ROSH - "Realm Object command SHell"
===================================

**rosh** is an extensible, all-in-one, application command shell.

It features a common command line interface to facilitate administration
of all sorts of API-powered applications within one consistent shell
environment. It helps to ease the work of application administrators who
often have to master a plethora of different CLI command languages, and
command sets - usually one for each administered application. Each
particular CLI having its own - often cryptic - commands, its own
command conventions, and its own style of design. Administering
applications by means of their graphical or web interfaces is usually
not much better - in fact administrators often prefer command line
interfaces -- for a reason.

While doing their job, admins often create collections of command
scripts for automating routine application management tasks (and thereby
establishing mastership over it). The **rosh** project aims at providing
a framework for organizing these scripts in a systematic, reusable, and
shareable fashion.

Key Concepts
============

The key idea of **rosh** is derived from the observation that
practically all application command languages have a few concepts in
common:

-   they deal with a *set of objects* (resources) that are
    characteristical for their application domain (or *realm* as rosh
    refers to them)
-   they often provide commands to
    -   *authenticate* users, and
    -   *list* (or query, discover),
    -   *create*,
    -   *describe*,
    -   *edit*, and
    -   *delete*

    resources (often referred to as *CRUD* operations),
-   as well as a number of commands that are specific for each
    application realm.

For **rosh** in its aim for a unified, common style of command language
for all applications, there are a few guiding principles:
-   the same kind of operation shall be initiated by the same command,
    regardless of the particular application,
-   the syntax, even for complex command sentences shall resemble - at
    least vaguely - commands spoken in natural language:
    -   sentences start with an *action verb*; action verbs can be
        complex, i.e. consist of multiple words,
    -   followed by a *noun* identifying the *kind* of the command's
        subject (also referred to as the *abstract subject*),
    -   any number of *prepositions* (usually representing command
        switches, and options), and
    -   the *subject* (or list of subjects) to which the
        command applies.

Examples:
---------

-   `list projects`
-   `list users --in iot/DOPS`
-   `add user will.smith@ua.com --as developer --to iot`
-   `list members of group iot`
-   `new merge --from branch-id-1 --to master`
-   `merge branch branch-task2 --to master`
-   `list merges --in my-project`
-   `list --my issues`
-   `describe issue DOPS-129`
-   `create branch for issue DOPS-129 --in gitlab`
-   `start node yforge1`

Command Processing
------------------

Commands are analyzed from left to right. When **rosh** processes a
command, it first tries to identify the *action verb*, which always
starts a command sentence. Action verbs consist of one or more plain
words. **rosh** tries to find the longest matching sequence of
verb-words in its table of known action verbs. Given the verb, **rosh**
proceeds to find a *noun* that has the verb defined in the remaining
command string. Having identified the noun, **rosh** loads the
applicable object class module from its realm library, and determines
the entry point that corresponds to the verb. All remaining words of the
procesed command (that are neither verb nor noun) are interpreted as
command arguments and are passed to standard **getopt** argument
processing.

Realms
------

**Realm** is a fancy word for *application domain* within a **rosh**
setup. In such a setup, it is possible to control for example
applications such as
-   gitlab,
-   jira,
-   artifactory, and
-   aws

within the same commandline environment. These applications are the
**realms**.

On a more technical level, a realm is a module (or plugin, if you want)
encapsulating an application's objects, and providing commands to
interact with these objects. Different realms can be activated and named
by a user specific *preferences* file - provided, a corresponding module
for the application is available. When a realm is loaded, it adds its
specific *nouns*, and applicable *verbs* to the current vocabulary of
the **rosh** session.

Currently, there are application modules for:
-   gitlab,
-   jira,
-   crowd,
-   ldap (active directory),
-   artifactory, and
-   aws.

The **rosh** core works independently from any application module, and
can be extended by any number of application specific adaptor modules.

Creating modules for new applications is rather straightforward: it
consists of a [high-level specification](sde/specs), written in YAML
format, and a [template-based generator](sde/mkapplication.pl) that
builds (usually fully functioning) skeleton modules for realms, and
realm objects from the specifications. The functional details of each
function require programming in *perl*.

The development process for new realms is outlined below.

### Namespaces

In order to avoid clashes when another realm is (dynamically) loaded
into a **rosh** session, and thereby eventually overloading an existing
vocabulary with nouns and/or verbs that are already associated with a
previously loaded realm, realms also establish **name spaces** for the
application objects. If multiple realms are configured in **rosh** it is
quite likely, that some names become ambiguous, for example *user* or
*project*. So, the exact meaning of a command such as `list
projects` depends on the realm in which the command is interpreted.
Usually, this is the *current realm*, a globally known state variable.
Commands can also be directed at *realm qualified objects*, for example:

-   `list jira.projects` vs.
-   `list gitlab.projects`

where the name of the applicable realm is used as prefix to the
conceptual object. The current realm can be changed with the special
command

`chrealm <realm-name>`.

The *list of available realms* is obtained with the command

`realms`.

The *current realm* can be examined with the command

`realm`.

Instances
---------

**Rosh** makes it easy to manage multiple instances of an application,
say a test-, or staging instance, accompanying the productive instance.
All application realms, and all instances of an application are defined
as named entities in the user specific `.rosh_preferences` file.

For example, to create a new *project* object in the staging instance of
a gitlab installation, there are three ways to do this:

1.  start **rosh** with the applicable instance as initial realm:

``` {.example}
rosh --with gitlab.stage
rosh> add project GOOF
```

1.  in a running **rosh** session switch the current realm before
    running the command:

``` {.example}
rosh> chrealm gitlab.stage
rosh> add project GOOF
```

or,
1.  run the realm-qualified command from any current realm:
    `rosh> add gitlab.stage.project GOOF`

For this command to function, the following preconditions must hold:
-   the GitLab module must be configured in the **rosh** installation
    -   it could either be packaged in the **rosh** container, or be
        stored in a locally supplied *realms* library that is
        effectively "linked" the to rosh via the `$ROSH_LIBREALM`
        environment variable; see "Running Rosh",
-   the **gitlab** realm must be defined in the user's
    `.gitlab\_preferences` file, and
-   the realm instance **stage** must be defined in the user's
    `.gitlab\_preferences` file

Running Rosh
============

**Rosh** is a modular command line application, written in perl. It runs
on any platform where perl is available - just about anywhere.

However, if you are on Linux or MacOS the easiest way to get it running
is in a **docker** container.

Docker
------

To run **rosh** as a docker container, set up a simple command script
like this one:

``` {.example}
#!/bin/bash

if [ -d $HOME/.aws ]
then
    AWS_VOL="-v $HOME/.aws:/opt/rosh/data/aws"
fi
if [ -d "$ROSH_LIBREALM" ]
then
    REALMS="-v $ROSH_LIBREALM:/opt/rosh/realms"
fi
docker run --name=rosh-$$ --rm -it -v $HOME:/opt/rosh/data $AWS_VOL $REALMS ickooch/rosh:latest
```

All that needs to be done for running the **rosh** container is to
connect it to the `.rosh_preferences` file. This is usually located in
the user's home directory.

Make sure that the HOME directory of the calling user has a properly set
up `.rosh_preferences` file (see "Define Rosh Preferences").

The **rosh** container comes with a few built-in application realms. In
order to extend it with more/other applications, the path to the
location with the additional script modules needs to be supplied in the
environment variable `$ROSH_LIBREALM`.

Running from Source
-------------------

**Rosh** is written in *perl* and depends on a few modules that may not
be part of the standard perl installation (it is assumed that a regular
perl installation is present).

In order to keep your local perl installation clean, and to install all
required modules in a safe and convenient fashion, it is recommended to
install the
[**carton**](http://search.cpan.org/~miyagawa/Carton-v1.0.28/lib/Carton.pm)
utility.

To get *rosh* up and running from source,

-   make sure your machine has HTTP~PROXY~ set, so that components can
    be installed from repositories in the internet.
-   install **carton**: `ppm install carton`
-   git clone <https://github.com/ickooch/rosh.git>
    -   NOTE: at the time of this writing, the **rosh** project is not
        yet public (still needs a license, and a decent README). If you
        have trouble accessing the project, contact me
        at ickooch@gmail.com.
-   create a `~/.rosh\_preferences file` in your `$HOME` directory. This
    is a YAML file with the connection data for your application
    instances (see below for details).
-   `cd rosh/rosh`
-   run `carton install`
    -   this installs all required modules in an application specific
        environment without messing up the system's global
        perl installation.
    -   **this step is only required once**
-   start **rosh** with `carton exec rosh`

\*CAVEAT:\* Running **rosh** via *carton* has the limitation that no
arguments can be passed to to rosh directly. The programm can only be
run with the interactive command line.

Setting up Application Connections
==================================

In order to connect to an application instance, the instance must be
defined in a settings file named **.rosh\_preferences** in the user's
home directory. The preferences file is in YAML format, and should look
similar to:

``` {.example}
---
#
# Global configuration section for the rosh shell.
#
config:
  # plugin-path is the (supposedly central) location, where plugin
  # modules are maintained. Usually, plugins should come from a
  # trusted server, and be cached locally.
  #
  default-realm: gitlab
  plugin-base-url: d:/Work/rosh/rosh/plugins
  plugin-cache-path: ~/.rosh.d
---
#
# Personalized service definitions that will be available
# for the calling user.
#
gitlab:
  name: GitLab
  color: red
  connector: GitLabConnector
  instances:
    defaults:
      api: v4
      instance: code
    code:
      access_token: nNuPwQE9mWWu9V4yivXV
      api: v4
      group: iot
      url: https://code.ingeneers.com
    stage:
      access_token: nNuPwQE9mWWu9V4yivXV
      api: v4
      group: iot
      url: https://stage.code.ingeneers.com
    test:
      access_token: nNuPwQE9mWWu9V4yivXV
      api: v4
      group: iot
      url: https://localhost:8085
jira:
  name: Jira
  color: blue
  connector: JiraConnector
  instances:

...
```

The `.rosh_preferences` file has two sections:
1.  global configuration settings, and
2.  a sequence of realm definitions.

### Global Section

(Currently, only the `default-realm:` setting has an effect. The two
*plugin-* lines are legacy settings that will go away, but are still
required to be present. The values are meaningless.)

### Realm Definitions

The sample realm definition *gitlab* consists of:
1.  the realm name (`gitlab:`)
2.  the application name (`name: GitLab`) - this name is used as prefix
    for the application connector module in the realm's
    script directory. In this example, it would build the name
    `GitLabConnector`.
3.  prompt color (`color: red`) - the color used for application command
    output that is sent to the console. The idea is to provide a visual
    clue as to which application responds to a command (typically the
    *current realm*).
4.  name of the application connector class (`connector:
     GitLabConnector`). This name must match the name of a perl module
    in the realm's script directory, here for example:
    `GitLabConnector.pm`. **Note:** this is currently redundant with the
    *application name*, described in point 2.
5.  instance definitions (`instances:`) - a sequence of definitions for
    individual application connections. These consist of:
    1.  instance name (`code:`)
    2.  access token (`access_token: nNuPwQE9mWWu9V4yivXV`) - the
        structure of the token is application dependent, and is possibly
        decoded in the *connector* module. In the `gitlab` example, the
        token is obtained from the *user profile* section of the GitLab
        web interface, and is used verbatim by the connector module. In
        other cases, the "token" could be a *base64-encoded* combination
        of user credentials that are used in basic authentication.
    3.  application url (`url: https://code.ingeneers.com`) - the unique
        address of the service access point for the application
        instance, typically a URL of a REST API.
    4.  any number of application specific additional fields, or options
        (here: `api:`, and `group:`, which are used in the
        module implementations).

6.  Each *instances* definition sequence must have a pseudo-instance
    that identifies the default instance (for the *gitlab* realm, the
    `instance: code` is selected as default).

Setting up a Development Environment
====================================

**NOTE:** The master site for the **rosh** CLI core is
<https://github.com/ickooch/rosh> on GitHub. Some realm plugins are
developed as part of the **rosh** project (in subdirectory
`rosh/realms`) but are in fact independent from the core development.
Private or custom implementations for realm plugins can be supplied in a
library directory via the `$ROSH_LIBREALM` environment variable,
provided, the plugins implement the realm load interface.

Setup of a development environment for contributing to the **rosh**
project is similar to running **rosh** from source. Usually, any
contributions to **rosh** should at least be performed on a separate
branch, or in a fork of **rosh**'s master repository.

`perl rosh.pl list projects`

Directory layout
----------------

-   rosh

    Main program structure with main program `rosh.pl`, and build
    support files `Makefile`, and `Dockerfile`.
    -   lib Core modules that implement the basic function of the
        **rosh** shell.
    -   realms Application plugins. Each application, or **realm**,
        consists of a separate directory that lists class interface
        (*&lt;class&gt;* `_IF.pm`), and implementation (*&lt;class&gt;*
        `.pm`) module pairs for application objects.

        The classes of a realm are split into an interface- and an
        implementation part. To ensure a quick startup of the CLI, only
        the interface definitions are initially loaded by the
        **rosh** shell. This makes all commands, and their respective
        help, and usage information known to the program. When the user
        calls a particular command, the applicable implementation is
        loaded, and the command script is run.

        Skeletons for these module pairs are generated from YAML
        specifications (see `sde/spec`, below), where the resulting
        `_IF.pm` files are usually not modified (except for the
        man-page part). The class implementations are usually
        heavily modified.

-   sde

    The `mkapplication.pl` skript is a small program that reads a realm
    specification, and generates (or updates) realm specific object
    modules from templates, and writes the resulting modules to the
    `rosh/realms` directory, described above.

    -   lib - template files for class interface (*&lt;mod&gt;*
        `_IF.pm`), and implementation. **Rosh** module templates are
        based on simple [HTML::Template
        templates](http://search.cpan.org/~samtregar/HTML-Template-2.6/Template.pm).
    -   spec - yaml specifications for realms, the specific realm
        objects (*nouns*), and the methods (*action verbs*) of
        these objects.
-   util Two simple scripts to base64-encode or -decode strings. The
    encode script is used to transform cleartext credential information
    into base64 encoded *tokens* that are read by realm application
    connectors before passing them - supposedly for basic
    authentication - to application endpoints.

Realm Development Workflow
--------------------------

Most realm object interfaces, and implementations have a common basic
structure, which makes it easy to generate an initial basic version from
a template. The generated raw modules are then completed and possibly
adapted by hand.

The overall command structure provided by a realm plugin is defined in
the *application specification*, eg. `gitlab.yml` in the `specs`
subdirectory. This is a YAML file describing the characteristics of all
the commands, the *nouns*, and the *verbs* of the application along with
their options.

To generate a complete application scaffolding from scratch, call the
development utility, and pass the name of the application specification
YAML file as argument.

`perl mkapplication.pl specs/gitlab.yml`

By default, existing application payload modules will *not* be
overwritten. This behavior can be overridden by using one of the
following options:

-   `perl mkapplication.pl --clobber specs/gitlab.yml` will overwrite
    all existing plugin modules.
-   `perl mkapplication.pl --clobber --noclobber <mod1>,<mod2>   specs/gitlab.yml`
    will overwrite all existing plugin modules, except those whose name
    matches one of the names listed as argument to the
    --noclobber option.
-   `perl mkapplication.pl --if-only specs/gitlab.yml` will overwrite
    only plugin interface definitions. This is useful for regenerating
    the documentation of a plugin, or introducing yet
    another subcommand.
-   `perl mkapplication.pl --plugin <mod1>,<mod2> specs/gitlab.yml`
    build only those plugin modules whose name matches one of the names
    passed to the --plugin option.
-   `perl mkapplication.pl -u --plugin <mod1>,<mod2> specs/gitlab.yml`
    generates new versions of the plugin module files without
    interfering with existing work on modules: all generated files are
    created with names that end in `.gen`. This is particularly useful
    for incrementally updating modules by (re-)deriving from the specs,
    and manually transferring, and tailoring newly generated code from
    the .gen file to the .pm file.

Realms
======

As *outlined below*, **rosh** development originally started because I
had to administer quite a few projects in GitLab, and I was dissatisfied
with the available command line interfaces to GitLab. And since I had an
old project for an efficient, and simple structured generic command
shell in my personal archive, I decided to refurbish it and use it as
basis for a custom GitLab CLI project. It turned out that the same
approach was easily extended to other applications I had to manage as
well, namely Jira, and JFrog Artifactory, resulting in a single CLI
environment for all the applications I had to manage.

**CAVEAT:** all of the applications described in the next few sections
have a rich, and deep REST (or other) API. The current state of the
**rosh** realm plugins is far from complete, and covers only those
functions that were in immediate need. One idea of the **rosh** project
is that realm implementations focus on the individual practical needs of
the user/admin/programmer and be shared in a community of **rosh** CLI
users, so that more, and more complete realm implementations will
eventually result.

GitLab
------

### Artifacts

### Boards

### Branches

### CIYML

### Commits

### Environments

### Files

### Groups

### Issues

### Jobs

### Labels

### Mergerequests

### Namespaces

### Pipelines

### Projects

### Runners

### Requests

### Snippets

### Tags

### Users

### Variables

### WebHook

Jira
----

### Boards

### Filters

### Groups

### Issues

### Projects

### Status

### Users

JFrog Artifactory
-----------------

### Builds

### Groups

### Items

### Permissions

### Repositories

### Users

Aws
---

Crowd
-----

Ldap
----

### Users

Why?
====

In short: I was in need of a tool that helps administering a fairly
large collection of GitLab projects (actually, in GitLab a project is
basically the same as a single repository with some additional stuff,
like pipelines, and deployments). In particular, I have to manage
Webhooks for most of the projects which can become tedious when one is
constrained to the Web interface.

There are quite a few free CLIs for GitLab available (see
<https://about.gitlab.com/applications/#cli-clients>), and I have looked
at some of them only to find that they did not exactly what I had in
mind, or that they were quite slow, or both. I haven't looked at all of
them but decided to rather spend my time building my own client that
works as I need it.
