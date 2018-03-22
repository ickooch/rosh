ROSH - "Realm Object command SHell"
===================================

**rosh** is an extensible, all-in-one, application command shell.

It features a common command line interface to facilitate administration
of all sorts of API-powered applications within one common command
shell. It helps to ease the work of application administrators who often
have to master a plethora of different CLI command languages, and
command sets - usually one for each administered application. Each
particular CLI having its own - often cryptic - commands, its own
command conventions, and its own style of design. Administering
applications by means of their graphical or web interfaces is usually
not much better - in fact administrators often prefer command line
interfaces -- for a reason.

While doing their job, admins often create a more or less sizeable
collections of command scripts for automating routine application
management tasks (and thereby establishing mastership over it). The
**rosh** project aims at providing a framework for organizing these
scripts in a systematic, reusable, and shareable fashion.

Key Concepts
------------

The key idea of **rosh** is derived from the observation that
practically all application command languages have a few concepts in
common:

-   they deal with a *set of objects* (resources) that are typical for
    their respective application domain (or *realm* as rosh refers
    to them)
-   they often provide commands to
    -   *authenticate* users, and
    -   *list* (or query, discover),
    -   *create*,
    -   *describe*,
    -   *edit*, and
    -   *delete*

    these objects (often referred to as *CRUD* operations),
-   as well as a number of commands that are specific for each
    application realm.

For **rosh** in its aim for a unified, common style of command language
for all applications, there are a few guiding principles:
-   the same kind of operation shall be initiated by the same command,
    regardless of the particular application,
-   the syntax, even for complex command sentences shall resemble - at
    least vaguely - commands spoken in natural language:
    -   sentences start with a - possibly complex - *action verb*,
    -   followed by a *noun* identifying the *kind* of the command's
        subject (also referred to as the *abstract subject*),
    -   any number of *prepositions* (usually representing command
        switches, and options), and
    -   the *subject* (or list of subjects) to which the
        command applies.

### Examples:

-   `list projects`
-   `list users --in iot/DOPS`
-   `add user will.smith@ua.com --as developer --to iot/DOPS`
-   `new merge --from branch-id-1 --to master`
-   `merge branch branch-task2 --to master`
-   `list merges --in my-project`
-   `list --my issues`
-   `describe issue DOPS-129`
-   `create branch for issue DOPS-129 --in gitlab`
-   `start node yforge1`

Realms
------

**Realm** is a simple word for *application domain* within a **rosh**
setup. In such a setup, it is possible to control for example
applications such as
-   gitlab,
-   jira,
-   artifactory, and
-   aws

within the same commandline session. These applications are the
**realms**.

A Realm is a module (or plugin, if you want) that **enables access** to
an application's objects, and provides commands to interact with these
objects. Different realms can be activated and named by a user specific
*preferences* file - provided, a corresponding module for the
application is available. When a realm is loaded, it adds its specific
*nouns*, and applicable *verbs* to the current vocabulary of the
**rosh** session.

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
consists of a high-level specification, written in YAML format, and a
template-based generator that builds (functioning) skeleton modules for
realms, and realm objects from the specifications. The functional
details of each function require programming in *perl*.

The development process for new realms is outlined below.

### Namespaces

In order to avoid clashes when loading a realm overloads an existing
vocabulary with nouns and/or verbs that are already associated with a
previously loaded realm, realms also establish **name spaces** for the
application objects. If multiple realms are configured in **rosh** it is
quite likely, that some concept names become ambiguous, for example
*user* or *project*. So, the exact meaning of a command such as `list
projects` depends on the realm in which the command is interpreted.
Usually, this is the *current realm*, a globally known process variable.
Commands can also be directed at *realm qualified objects*, for example:

-   `list jira.projects` vs.
-   `list gitlab.projects`

where the name of the applicable realm is used as prefix to the
conceptual object. The current realm can be changed with the special
command `chrealm <realm-name>`.

### Instances

**Rosh** makes it easy to manage multiple instances of an application,
say a test-, or staging instance, and the productive instance. All
application realms, and all instances of an application are defined as
named entities in the user specific `.rosh_preferences` file.

For example, to create a new project in the staging instance of a gitlab
installation, there are three ways to do this:
1.  start **rosh** with the applicable instance as initial realm:
    `rosh --with gitlab.stage`,
2.  in a running **rosh** session switch the current realm before
    running the command: `chrealm gitlab.stage`, or
3.  run the realm-qualified command from any current realm:
    `add gitlab.stage.project GOOF`

For this command to function, the following preconditions must hold:
-   the GitLab module must be configured in the **rosh** installation
    (it should be packaged in the **rosh** container; see "Running
    Rosh"),
-   the **gitlab** realm must be defined in the user's
    `.gitlab\_preferences` file, and
-   the realm instance **stage** must be defined in the user's
    `.gitlab\_preferences` file

Running Rosh
------------

**Rosh** is a modular command line application, written in perl. It runs
on any platform where perl is available - just about anywhere.

The easiest way to get it running is in a **docker** container, which
requires a unix-like environment, though.

### Docker

To run **rosh** as a docker container, set up a simple command script
like this one:

``` {.example}
#!/bin/bash

docker run --name=rosh-$$ --rm -it -v ~:/opt/rosh/data ickooch/rosh:latest
```

All that needs to be done for running the **rosh** container is to
connect it to the `.rosh_preferences` file. This is usually located in
the user's home directory (`~`).

Make sure that the HOME directory of the calling user has a properly set
up `.rosh_preferences` file (see "Define Rosh Preferences").

Using the docker execution mode does not permit for local extension or
debugging of the scripts that implement the application object
functions.

### Running from Source

**Rosh** is written in *perl* and depends on a few modules that may not
be part of the perl standard installation (it is assumed that a regular
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
-   git clone
-   create a `~/.rosh\_preferences file` in your \$HOME directory. The
    with the connection data for your application instances (see below
    for details)
-   `cd rosh/rosh`
-   run `carton install`
    -   this installs all required modules in an application specific
        environment without messing up the system's global
        perl installation.
    -   **this step is only required once**
-   start **rosh** with `carton exec rosh`

\*CAVEAT:\* Running **rosh** via *carbon* has the limitation that no
arguments can be passed to to rosh directly. The programm can only be
run with the interactive command line.

### Setting up a Development Environment

Setup of a development environment for contributing to the **rosh**
project is similar to running **rosh** from source. Usually, any
contributions to **rosh** should at least be performed on a separate
branch, or in a fork of **rosh**'s master repository.

`perl rosh.pl list projects`

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
    defaults:
      api: 2
      instance: jira
    jira:
      access_token: c3ZtrsdhfgdDJFGdjfdDc2lXZ3N1czAx
      api: 2
      url: https://smartstuff.com/jira/rest
      myissues: project in (WOSSDE, IDEV, CONN, EDGE, SINT) AND status in (open, "in progress", Reopened, "To Do", Done, realisation, review, qa, validation, proposed, incomplete, analysis, implementation) AND assignee in (currentUser()) ORDER BY Rang ASC
    stage:
      access_token: c3ZtrsdhfgdDJFGdjfdDc2lXZ3N1czAx
      api: 2
      url: https://stage.smartstuff.com/jira/rest
crowd:
  name: Crowd
  color: cyan
  connector: CrowdConnector
  scramble_key: WoS-2016-Security
  instances:
    defaults:
      api: 1
      instance: crowd
    crowd:
      access_token: cm9zaTZDFgfGHKFffglMm
      api: 1
      url: https://smartstuff.com/crowd/rest/usermanagement
    stage:
      access_token: cm9zaTZDFgfGHKFffglMm
      api: 1
      url: https://stage.smartstuff.com/crowd/rest/usermanagement
atf:
  name: Artifactory
  color: green
  connector: ArtifactoryConnector
  instances:
    defaults:
      instance: wosatf
      api: undef
    wosatf:
      access_token: YHGhgHJGHJbFKhknZGwyaw==
      url: http://iot.smartstuff.com/artifactory
ldap:
  name: Ldap
  color: magenta
  connector: LdapConnector
  instances:
    defaults:
      instance: top
      api: 3
    ad001:
      access_token: YJGVHkJVsNBJKBo1NGogMTRnVEknZGwyaw==
      url: ldaps://top.ingeneers.net
aws:
  name: Aws
  color: yellow on_blue
  connector: AWSConnector
  instances:
    defaults:
      instance: aws1
      api: n/a
    aws1:
      access_token: QUtJQUlORzJHGjlbbdrkjJHioözhuhJKBjkaXJkaDdmajZFS3o2NTlpb2JHREpHWVQvRjZCS0hFVQ==
      url: aws
      region: eu-central-1

```

The access token links the requests made by the *rosh* client to a user
account in the application instance. Tokens can usually be obtained by
logging into the webinterface of an application, and creating one in the
user profile section.

Payload Commands and Scaffolding Generation
-------------------------------------------

As pointed out at the beginning, this gitlab CLI program was built using
a scaffolding generator toolkit. It consists of a generic command line
processing kernel, and a number of application payload modules, or
*plugins*. The *command line processing kernel* is the same for any kind
of command line interface for any kind of system that has an API
accessible to perl. It provides the frame for *plug-in* modules that
implement the actual application logic, in this particular case the
various GitLab management commands.

The **generic** parts of the CLI application reside in the `lib`
subdirectory. The **application payload modules** reside in the
`GitLabCLI` subdirectory. This is where most of the gitlab specific
scripting occurs. Some generally useful functions for interacting with
GitLab are collected in the `lib/GitLabConnector.pm` module, which
implements a `$gitlab` object that is linked into each of the plugin
modules.

Each of the plugins is a separate command script that implements one or
more commands that can be called when the application is running. A
plugin consists of two parts, 1. an **interface specification**, and 2.
the **implementation** part of the plugin.

To ensure a quick startup of the CLI, only the interface definitions are
initially loaded. This makes all commands, and their respective help,
and usage information known to the program. When the user calls a
particular command, the applicable plugin implementation is loaded, and
the command script is run.

All plugin interfaces, and implementations have a common basic
structure, which makes it easy to generate an initial basic version from
templates. The generated raw modules are then completed and possibly
adapted by hand.

The overall command structure provided by a plugin is defined in the
*application specification*, eg. `gitlab.yml` in the `specs`
subdirectory. This is a YAML file describing the characteristics of all
the commands, the *nouns*, and the *verbs* of the application along with
their options.

To generate a complete application scaffolding from scratch, call the
development utility, and pass the name of the application specification
YAML file as argument.

`perl mkapplication.pl specs/gitlab.yml`

By default, any existing application payload modules will not be
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

Why?
----

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
