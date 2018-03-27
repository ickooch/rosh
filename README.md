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

As pointed out above, when a realm plugin is loaded into the **rosh**
command shell, it extends the *vocabulary* of the command language by
*nouns* (the resource objects), and *verbs* that eventually take the
nouns as subjects. The set of nouns and verbs that are currently known
to **rosh** can be examined by giving the commands

`rosh> nouns`

or

`rosh> verbs`

respectively.

In order to view a summary of the command verbs applicable to a known
noun, specify the command

`rosh> noun _some_noun_`

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

The **GitLab** realm commands work against the [GitLab REST
API](https://docs.gitlab.com/ee/api/README.html). The *nouns* correspond
to the *Resource* classes defined by GitLab's API.

The exact API call sent by **rosh** to the web endpoint can be obtained
by setting the **show~curl~** variable to *1* in **rosh**
("`set show_curl ` 1=").

### Authentication

The GitLab *access~token~* specified in the `$HOME/.rosh_preferences`
file can be obtained through the GitLab web interface under the
**Settings** / **Access Tokens** section (left panel) in the User
profile.

### Nouns

#### Artifacts

**Action verbs:**
-   **get** --help --job *&lt;string&gt;* --long|l --in *&lt;string&gt;*

    Get the artifacts (zip-)file for the given job. If a name is
    provided that matches one or more artifact, only the matching
    artifacts are retrieved and placed in the current directory.

-   **list** --help --job *&lt;string&gt;* --ref *&lt;string&gt;*
    --long|l --in *&lt;string&gt;*

    List artifacts generated for the indicated job.

    An argument to the list command is treated as a filter expression
    that will be matched against the set of all job artifacts.

#### Boards

**Action verbs:**
-   **add** --help --name|n *&lt;string&gt;* --in *&lt;string&gt;*
    --desc|d *&lt;string&gt;*
-   **delete** --force|f --in *&lt;string&gt;* --help
-   **describe** --help --long|l --short|s --in *&lt;string&gt;*
    --format|fmt *&lt;string&gt;* (aliases: *desc*)
-   **edit** --help --name|n *&lt;string&gt;* --in *&lt;string&gt;*
    --desc|d *&lt;string&gt;*
-   **ls** --help --long|l --short|s --in *&lt;string&gt;* --format|fmt
    *&lt;string&gt;* (aliases: *list, show*)

    List names, and ids of all filters owned by or visible to
    the caller.

#### Branches

**Action verbs:**
-   **add** --help --in *&lt;string&gt;* --for *&lt;string&gt;* --ref
    *&lt;string&gt;* (aliases: *create, new*)

    Create a branch in the specified (or current) project. The branch is
    forked off from the specified branch, label or commit specified as
    argument to --ref. If no branching point is specified, the branch
    forks of master.

    The name of the branch must be specified as argument to the command.

-   **delete merged** --force|f --help --in *&lt;string&gt;*

    Delete all branches that are merged into the specified (or current)
    project's default branch.

    Protected branches will not be deleted as part of this operation.

-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* (aliases: *desc*)

    Output details of the current project's branch which is given
    as argument.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --limit|max=i --all|a --in *&lt;string&gt;* (aliases: *ls*)

    List names, and ids of branches in specified (current) repository.

    An argument to the list command is treated as a filter expression
    that will be matched against the set of all branches.

-   **protect** --help --in *&lt;string&gt;* --allow-push --allow-merge
-   **remove** --force|f --help --in *&lt;string&gt;* (aliases: *delete,
    rm, del*)

    Delete a branch in the specified (or current) project.

    The name of the branch must be specified as argument to the command.

-   **unprotect** --help --in *&lt;string&gt;*

#### CIYML

**Action verbs:**
-   **describe** --help
-   **get** --help
-   **list** --help

#### Commits

**Action verbs:**
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;*

    Output details of the current project's commit which is given
    as argument.

-   **diff|compare|comp** --help --long|l --short|s --from
    *&lt;string&gt;* --to *&lt;string&gt;* --in *&lt;string&gt;*
    --filter *&lt;string&gt;*

    Print an overview of the differences between the two commits --from
    and --to.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --limit|max=i --in *&lt;string&gt;* --branch|b *&lt;string&gt;*
    --ref *&lt;string&gt;* --since *&lt;string&gt;* --until
    *&lt;string&gt;*

    List commits in specified repositories.

    An argument to the list command is treated as a filter expression
    that will be matched against the title of all commits.

#### Environments

**Action verbs:**
-   **add** --help --in *&lt;string&gt;* --url *&lt;string&gt;*
    (aliases: *create*)

    Create a new deployment environment.

-   **describe** --help --long|l --short|s --in *&lt;string&gt;*
-   **edit** --help --in *&lt;string&gt;* --url *&lt;string&gt;*
    (aliases: *update*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;*
-   **remove** --force|f --help --in *&lt;string&gt;* (aliases:
    *delete*)

    Delete the environment.

-   **stop** --help --in *&lt;string&gt;*

    Stop the specified environment.

#### Files

**Action verbs:**
-   **cat** --help --file|f --in *&lt;string&gt;* --ref *&lt;string&gt;*
    --branch|b *&lt;string&gt;*

    Output the contents of the file.

-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* --ref *&lt;string&gt;* --branch|b
    *&lt;string&gt;*

    Output all relevant details of the file given as argument.

-   **diff|compare|comp** --help --long|l --from *&lt;string&gt;* --to
    *&lt;string&gt;* --in *&lt;string&gt;*

    Print the differences between the two commits --from and --to in
    specified file.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* --recursive|r --ref *&lt;string&gt;*
    --branch|b *&lt;string&gt;*

    List the files in a project's repository.

    Arguments to the command are treated as search names, and only files
    whose names match are included in the output.

#### Groups

**Action verbs:**
-   **add member to** --help --as *&lt;string&gt;* (aliases: *add user
    to*)
-   **add** --help --path *&lt;string&gt;* --proto *&lt;string&gt;* --in
    *&lt;string&gt;* --desc|d *&lt;string&gt;* --visibility
    *&lt;string&gt;* (aliases: *new, create*)
-   **delete** --force|f --recursive|r --help (aliases: *del, remove,
    rm*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --json (aliases: *desc*)

    Output all relevant details of the group given as argument.

-   **edit** --help --group *&lt;string&gt;* --name|n *&lt;string&gt;*
    --path *&lt;string&gt;* --in *&lt;string&gt;* --enable
    *&lt;string&gt;* --disable *&lt;string&gt;* --desc|d
    *&lt;string&gt;* --visibility *&lt;string&gt;* (aliases: *update,
    change*)
-   **list members of** --help --long|l --short|s (aliases: *list
    members in, list users in, ls members of*)

    List names, and ids of all subgroups contained in the group passed
    as argument.

-   **list projects in** --help --long|l --short|s (aliases: *ls
    projects in*)

    List names, and ids of all projects contained in the group or
    subgroup passed as argument.

-   **list** --help --long|l --short|s (aliases: *ls*)

    List names, and ids of all groups owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

-   **remove member from** --help (aliases: *remove user from, rm member
    from*)

#### Issues

**Action verbs:**
-   **assign** --help --to *&lt;string&gt;* --comment|c *&lt;string&gt;*
    --in *&lt;string&gt;*
-   **comment** --help --in *&lt;string&gt;* --comment|c
    *&lt;string&gt;*
-   **create branch for** --help --for *&lt;string&gt;* --in
    *&lt;string&gt;* (aliases: *add branch for*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* --with *&lt;string&gt;* (aliases: *desc, cat*)
-   **list my** --help --long|l --short|s --userid=i --format|fmt
    *&lt;string&gt;* --all|a --filter *&lt;string&gt;* --in
    *&lt;string&gt;* (aliases: *ls my*)

    List issues assigned to, or reported by the current user. By default
    the current user is the user used to connect to Jira. The concept of
    current user can be modified with the option --user &lt;userid&gt;.

-   **list templates for** --help --long|l --short|s --in
    *&lt;string&gt;* (aliases: *ls templ*)

    List issue templates for the current project. The templates are
    markdown files stored in the .gitlab/issue~templates~/ directory.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --limit|max=i --in *&lt;string&gt;* --on|on-board|board
    *&lt;string&gt;* --filter *&lt;string&gt;* --all|a (aliases: *ls*)

    List active issues in the specified project, or according to one of
    the selection options. By default, only active issues are returned.
    Option --all can be set to include closed, and resolved issues in
    the output, too.

-   **new** --help --in *&lt;string&gt;* --labels|type *&lt;string&gt;*
    --title *&lt;string&gt;* --desc|d *&lt;string&gt;* --assign-to
    *&lt;string&gt;* --milestone *&lt;string&gt;* (aliases: *add,
    create*)
-   **remove** --force|f --help --in *&lt;string&gt;* (aliases: *delete,
    rm, del*)

    Delete an issue in the specified (or current) project.

    The instance id of the issue must be specified as argument to
    the command.

-   **transition** --help --from *&lt;string&gt;* --to *&lt;string&gt;*
    --no-comment|nc --in *&lt;string&gt;* --comment|c *&lt;string&gt;*
    (aliases: *trans, move, advance, adv, push, close, reopen*)
-   **unwatch** --help --in *&lt;string&gt;* (aliases: *unsubscribe,
    unsub*)
-   **watch** --help --in *&lt;string&gt;* (aliases: *subscribe, sub*)

#### Jobs

**Action verbs:**
-   **cancel** --help --in *&lt;string&gt;*
-   **delete** --help --force|f --in *&lt;string&gt;* (aliases: *erase,
    remove*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;*
-   **download artifacts of** --help --in *&lt;string&gt;* --ref
    *&lt;string&gt;* --file|f
-   **get** --help --in *&lt;string&gt;* --file|f
-   **get artifacts from** --help --in *&lt;string&gt;*
-   **list** --help --in *&lt;string&gt;* --all|a --long|l --limit|max=i
    --short|s --format|fmt *&lt;string&gt;* --branch|b *&lt;string&gt;*
-   **list all** --help --long|l --limit|max=i --short|s --format|fmt
    *&lt;string&gt;* --in *&lt;string&gt;* --branch|b *&lt;string&gt;*
-   **play** --help --in *&lt;string&gt;* (aliases: *trigger, start*)
-   **retry** --help --in *&lt;string&gt;*

#### Labels

**Action verbs:**
-   **add** --help --in *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --color|col *&lt;string&gt;* (aliases: *create, new, mk*)

    Create a label in the specified (or current) project.

    The name of the label must be specified as argument to the command.

-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* (aliases: *desc, get*)

    Output details of the current project's branch which is given
    as argument.

-   **list** --help --long|l --limit|max=i --short|s --format|fmt
    *&lt;string&gt;* --in *&lt;string&gt;* (aliases: *ls*)
-   **remove** --force|f --help --in *&lt;string&gt;* (aliases: *delete,
    del, rm*)

    Delete a branch in the specified (or current) project.

    The name of the branch must be specified as argument to the command.

#### Mergerequests

**Action verbs:**
-   **add** --help --in *&lt;string&gt;* --from *&lt;string&gt;* --to
    *&lt;string&gt;* --title *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --rm-source-branch|delete-branch --assign-to *&lt;string&gt;*
    --labels|type *&lt;string&gt;* --squash --milestone *&lt;string&gt;*
    (aliases: *create*)
-   **approve** --help --sha *&lt;string&gt;* --in *&lt;string&gt;*
-   **cancel** --help --in *&lt;string&gt;* (aliases: *abort*)
-   **comment** --help --in *&lt;string&gt;* --comment|c
    *&lt;string&gt;*
-   **delete** --help --force|f --in *&lt;string&gt;* (aliases: *erase,
    remove*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --with *&lt;string&gt;* --in *&lt;string&gt;* (aliases: *desc*)
-   **do** --help --in *&lt;string&gt;* --sha *&lt;string&gt;*
    --message|msg *&lt;string&gt;* --rm-source-branch|delete-branch
    (aliases: *accept, merge, exec, execute*)
-   **edit** --help --in *&lt;string&gt;* --title *&lt;string&gt;*
    --desc|d *&lt;string&gt;* --assign-to *&lt;string&gt;* --to
    *&lt;string&gt;* --rm-source-branch|delete-branch --labels|type
    *&lt;string&gt;* --squash --milestone *&lt;string&gt;* (aliases:
    *update*)
-   **get** --help --in *&lt;string&gt;* --commits --changes --file|f
-   **list** --help --long|l --labels|type *&lt;string&gt;* --milestone
    *&lt;string&gt;* --limit|max=i --short|s --format|fmt
    *&lt;string&gt;* --all|a --in *&lt;string&gt;*
-   **list comments to** --help --long|l --limit|max=i --short|s
    --format|fmt *&lt;string&gt;* --in *&lt;string&gt;* (aliases: *list
    notes for, list comments, list notes*)
-   **unapprove** --help --in *&lt;string&gt;*

#### Namespaces

**Action verbs:**
-   **list** --help --long|l --short|s

#### Pipelines

**Action verbs:**
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* (aliases: *desc*)
-   **list** --help --long|l --limit|max=i --short|s --format|fmt
    *&lt;string&gt;* --in *&lt;string&gt;* (aliases: *ls*)

#### Projects

**Action verbs:**
-   **add member to** --help --as *&lt;string&gt;* (aliases: *add user
    to*)
-   **create** --help --in *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --visibility *&lt;string&gt;* --branch|b *&lt;string&gt;* --enable
    *&lt;string&gt;* --url *&lt;string&gt;* --proto *&lt;string&gt;*
    (aliases: *add, new*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list members of** --help --long|l --short|s
-   **list** --help --long|l --short|s --in *&lt;string&gt;* --all|a
    --recursive|r --format|fmt *&lt;string&gt;* (aliases: *ls*)

    List names, and ids of all projects listed in a group or
    subgroup (namespace) owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    projects whose names match are included in the output.

-   **move** --help --from *&lt;string&gt;* --to *&lt;string&gt;*
    (aliases: *rename, mv, ren, transfer, trans*)
-   **remove member from** --help (aliases: *remove user from*)
-   **remove** --force|f --help (aliases: *delete*)
-   **update** --help --desc|d *&lt;string&gt;* --visibility
    *&lt;string&gt;* --in *&lt;string&gt;* --name|n *&lt;string&gt;*
    --path *&lt;string&gt;* --proto *&lt;string&gt;* --branch|b
    *&lt;string&gt;* --enable *&lt;string&gt;* --disable
    *&lt;string&gt;* (aliases: *edit, change*)

#### Requests

**Action verbs:**
-   **approve** --help --in *&lt;string&gt;* --as *&lt;string&gt;*
    (aliases: *ok*)
-   **deny** --help --in *&lt;string&gt;* (aliases: *reject*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --projects|P (aliases: *desc*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;* (aliases: *ls*)
-   **new** --help --userid=i --for *&lt;string&gt;* --in
    *&lt;string&gt;* --to *&lt;string&gt;* (aliases: *access*)

#### Runners

**Action verbs:**
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --projects|P (aliases: *desc*)
-   **disable** --help --in *&lt;string&gt;*
-   **enable** --help --in *&lt;string&gt;*
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;*
-   **remove** --help --in *&lt;string&gt;* (aliases: *delete*)

#### Snippets

**Action verbs:**
-   **create** --help --in *&lt;string&gt;* --title *&lt;string&gt;*
    --file|f --desc|d *&lt;string&gt;* --visibility *&lt;string&gt;*
    --code *&lt;string&gt;* (aliases: *add*)
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    --in *&lt;string&gt;*
-   **get** --help --in *&lt;string&gt;* --to *&lt;string&gt;* (aliases:
    *cat*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    --in *&lt;string&gt;*
-   **remove** --help --force|f --in *&lt;string&gt;* (aliases:
    *delete*)
-   **update** --help --in *&lt;string&gt;* --title *&lt;string&gt;*
    --file|f --desc|d *&lt;string&gt;* --visibility *&lt;string&gt;*
    --code *&lt;string&gt;* (aliases: *edit*)

#### Tags

**Action verbs:**
-   **list** --help --long|l --limit|max=i --short|s --format|fmt
    *&lt;string&gt;* --in *&lt;string&gt;*

#### Users

**Action verbs:**
-   **add** --help --long|l --to *&lt;string&gt;* --as *&lt;string&gt;*
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    --in *&lt;string&gt;* (aliases: *ls*)
-   **remove** --help --long|l --from *&lt;string&gt;* (aliases: *rm,
    del, delete*)

#### Variables

**Action verbs:**
-   **add** --help --in *&lt;string&gt;* --value|val *&lt;string&gt;*
    --environment|env|scope *&lt;string&gt;* --protected|prot (aliases:
    *create*)

    Create a new build variable.

-   **describe** --help --long|l --short|s --in *&lt;string&gt;*
-   **edit** --help --in *&lt;string&gt;* --value|val *&lt;string&gt;*
    --environment|env|scope *&lt;string&gt;* --protected|prot (aliases:
    *setenv, update*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --in *&lt;string&gt;*
-   **remove** --force|f --help --in *&lt;string&gt;* (aliases:
    *delete*)

#### WebHook

**Action verbs:**
-   **add** --help --url *&lt;string&gt;* --to *&lt;string&gt;*
    --recursive|r --events *&lt;string&gt;* --token *&lt;string&gt;*

    Create a project hook (also referred to as webhook) for the project
    or projects referenced by the context specified by the --to option.
    The referenced context is usually a projecst or a list of projects.
    It is also possible to specify a group or subgroup, in which case
    the webhook is created for all projects in the respective group (see
    also option --recursive).

    The option /--url '&lt;url string&gt;'/ defines URL endpoint of a
    webseservice that is called whenever one of the events specified
    with the option --events occurs.

    The switch '--token &lt;string&gt;' is used to define a secret token
    to validate received payloads.

    If the option *--recursive* is set the argument to the --to option
    is taken as a group (possibly containing subgroups) in which
    projects are organized. In this case the webhook is added to all
    projects that are contained in the transitive closure of the group
    given in the --to option.

-   **copy** --help --to *&lt;string&gt;*

    Copy the webhooks specified as command arguments to the project
    (or projects) specified as argument to the --to option.

    This command requires an initialized cache of webhook entries (see
    command 'list webhooks').

-   **describe** --help --long|l --short|s
-   **edit** --help --project|p *&lt;string&gt;* --in=i --url
    *&lt;string&gt;* --events *&lt;string&gt;* --token *&lt;string&gt;*
-   **list** --help --long|l --short|s --url *&lt;string&gt;*
    --format|fmt *&lt;string&gt;*
-   **remove** --force|f --help --events *&lt;string&gt;* (aliases:
    *delete*)

Jira
----

The **Jira** realm commands work against the [JIRA REST
API](https://developer.atlassian.com/server/jira/platform/). The *nouns*
correspond to the *Resource* classes defined by JIRA's API.

The exact API call sent by **rosh** to the web endpoint can be obtained
by setting the **show~curl~** variable to *1* in **rosh**
("`set show_curl ` 1=").

### Authentication

The Jira *access~token~* specified in the `$HOME/.rosh_preferences` file
is composed of the base64-encoded *username*, and the user's *password*,
separated by a colon (":") (use the supplied `encode64.pl` utility, to
encode the credentials).

NOTE: the base64 encoded credentials are read by the JIRAConnector
module supplied to **rosh** as part of the realm plugin installation.
They are passed to the web service endpoint in the **Auth**-Header for
Basic-Authentication of web requests to the API. Make sure that the
connection to JIRA runs via HTTPS, in order to keep the credentials
secret.

### Nouns

#### Boards

**Action verbs:**
-   **add** --help --name|n *&lt;string&gt;* --jql *&lt;string&gt;*
    --desc|d *&lt;string&gt;* --favorite|fave
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **edit** --help --name|n *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --jql *&lt;string&gt;* --favorite|fave
-   **ls** --help --long|l --short|s --favorite|fave (aliases: *list,
    show*)

    List names, and ids of all filters owned by or visible to
    the caller.

#### Filters

**Action verbs:**
-   **add** --help --name|n *&lt;string&gt;* --proto *&lt;string&gt;*
    --jql *&lt;string&gt;* --desc|d *&lt;string&gt;* --favorite|fave
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **edit** --help --name|n *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --jql *&lt;string&gt;* --favorite|fave (aliases: *update*)
-   **list** --help --long|l --short|s --favorite|fave

    List names, and ids of all filters owned by or visible to
    the caller.

#### Groups

**Action verbs:**
-   **add** --help
-   **add member to** --help (aliases: *add user to*)
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s (aliases: *list members of,
    list members in, list users in*)

    List names, and ids of all subgroups contained in the group passed
    as argument.

-   **edit** --help --group *&lt;string&gt;* --name|n *&lt;string&gt;*
    --path *&lt;string&gt;* --in *&lt;string&gt;* --desc|d
    *&lt;string&gt;* --visibility *&lt;string&gt;*
-   **list** --help --long|l --short|s

    List names, and ids of all groups owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

-   **remove member from** --help (aliases: *remove user from*)

#### Issues

**Action verbs:**
-   

-   **assign** --help --to *&lt;string&gt;*
-   **attach file to** --help --file|f *&lt;string&gt;* (aliases: *att,
    add attachment to, attach*)
-   **comment** --help --comment|c *&lt;string&gt;*
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --with *&lt;string&gt;* (aliases: *desc, cat*)
-   **list my** --help --long|l --short|s --userid *&lt;string&gt;*
    --format|fmt *&lt;string&gt;* --all|a --in *&lt;string&gt;*
    (aliases: *ls my*)

    List issues assigned to, or reported by the current user. By default
    the current user is the user used to connect to Jira. The concept of
    current user can be modified with the option --user &lt;userid&gt;.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    --limit|max=i --in *&lt;string&gt;* --jql *&lt;string&gt;*
    --show-jql --on|on-board|board *&lt;string&gt;* --filter|flt
    *&lt;string&gt;* --all|a (aliases: *ls*)

    List active issues in the specified project, or according to one of
    the selection options. By default, only active issues are returned.
    Option --all can be set to include closed, and resolved issues in
    the output, too.

-   **new** --help --labels *&lt;string&gt;* --title *&lt;string&gt;*
    --type|kind *&lt;string&gt;* --desc|d *&lt;string&gt;* --in
    *&lt;string&gt;* --assign-to *&lt;string&gt;* (aliases: *add,
    create*)
-   **transition** --help --to *&lt;string&gt;* --no-comment|nc
    --comment|c *&lt;string&gt;* (aliases: *trans, move, mv, advance,
    adv, push*)
-   **unwatch** --help --userid *&lt;string&gt;* (aliases: *unsubscribe,
    unsub*)
-   **watch** --help --userid *&lt;string&gt;* (aliases: *subscribe,
    sub*)

#### Projects

**Action verbs:**
-   **create** --help --key *&lt;string&gt;* --title *&lt;string&gt;*
    --desc|d *&lt;string&gt;* --notification-scheme|notify
    *&lt;string&gt;* --permission-scheme|perm *&lt;string&gt;* --type
    *&lt;string&gt;* --lead *&lt;string&gt;* --roles *&lt;string&gt;*
    --proto *&lt;string&gt;* (aliases: *add*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    List names, and ids of all projects listed in a group or
    subgroup (namespace) owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    projects whose names match are included in the output.

-   **remove** --force|f --help (aliases: *delete*)
-   **update** --help --desc|d *&lt;string&gt;* --visibility
    *&lt;string&gt;* --branch|b *&lt;string&gt;* --enable
    *&lt;string&gt;* --disable *&lt;string&gt;* (aliases: *edit,
    change*)

#### Status

**Action verbs:**
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    List names, categories and ids of all issue statuses.

#### Users

**Action verbs:**
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    --in *&lt;string&gt;* (aliases: *ls*)
-   **remove** --help --force|f (aliases: *delete, rm, del, offboard*)

    The specified users are not really deleted from the applicable user
    directory, but rather removed from all groups. This will remove
    application access from the users, and free up the tool licenses.

-   **update** --help --proto *&lt;string&gt;* --groups *&lt;string&gt;*
    (aliases: *edit, change*)

    The command modifies one or more users by prototype, i.e. all
    relevant, non-idividual attributes of the prototype user, specified
    as argument to the --prot option, are applied to the specified
    user entries. In particular, the users are added and removed to/from
    groups so they match the prototype user.

JFrog Artifactory
-----------------

The **Artifactory** realm commands work directly against the
[JFrogArtifactory REST
API](https://www.jfrog.com/confluence/display/RTF/Artifactory+REST+API).
The *nouns* correspond to the *Resource* classes defined by the
Artifactory API.

The exact API call sent by **rosh** to the web endpoint can be obtained
by setting the **show~curl~** variable to *1* in **rosh**
("`set show_curl ` 1=").

### Authentication

The Artifactory *access~token~* specified in the
`$HOME/.rosh_preferences` file is composed of the base64-encoded
*username*, and the user's *password*, separated by a colon (':') (use
the supplied `encode64.pl` utility, to encode the credentials).

NOTE: the base64 encoded credentials are read by the
ArtifactoryConnector module supplied to **rosh** as part of the realm
plugin installation. They are passed to the web service endpoint in the
**Auth**-Header for Basic-Authentication of web requests to the API.
Make sure that the connection to Artifactory runs via HTTPS, in order to
keep the credentials secret.

### Nouns

#### Builds

**Action verbs:**
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --favorite|fave

    List names, and ids of all builds owned by or visible to the caller.

#### Groups

**Action verbs:**
-   **add** --help
-   **add member to** --help (aliases: *add user to*)
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s (aliases: *desc*)

    List names, and ids of all subgroups contained in the group passed
    as argument.

-   **edit** --help
-   **list** --help --long|l --short|s (aliases: *ls*)

    List names, and ids of all groups owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

-   **remove member from** --help (aliases: *remove user from*)

#### Items

**Action verbs:**
-   **copy** --help (aliases: *cp*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --recursive|rec|R --t --r
    --format|fmt *&lt;string&gt;* (aliases: *ls*)

    List names, and basic information about items stored in a repository
    or a folder in that repository.

    Arguments to the command are treated as search names, and only items
    whose names match are included in the output.

-   **mkdir** --help --force|f (aliases: *mkfolder, addfolder*)
-   **move** --help (aliases: *mv, rename, ren*)
-   **new** --help --file|f --to *&lt;string&gt;* --force|f (aliases:
    *create, add, upload, deploy*)
-   **remove** --force|f --help --with-content (aliases: *delete, del,
    rm*)

#### Permissions

**Action verbs:**
-   **apply** --help --to *&lt;string&gt;* --from *&lt;string&gt;*
    (aliases: *administer, admin, unapply, revoke*)
-   **create** --help --title *&lt;string&gt;* (aliases: *add*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    Get the permission targets list

-   **remove** --force|f --help (aliases: *delete, del, rm*)
-   **update** --help (aliases: *edit, replace*)

#### Repositories

**Action verbs:**
-   **create** --help --title *&lt;string&gt;* --desc|d *&lt;string&gt;*
    --type *&lt;string&gt;* --class *&lt;string&gt;* --proto
    *&lt;string&gt;* (aliases: *add*)
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --short|s --all|a --my --recursive|rec|R
    --class *&lt;string&gt;* --t --r --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    List names, and ids of all repositories listed in a group or
    subgroup (namespace) owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    repositories whose names match are included in the output.

-   **remove** --force|f --help --with-content (aliases: *delete, del,
    rm*)
-   **update** --help --desc|d *&lt;string&gt;* --visibility
    *&lt;string&gt;* --branch|b *&lt;string&gt;* --enable
    *&lt;string&gt;* --disable *&lt;string&gt;* (aliases: *edit*)

#### Users

**Action verbs:**
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)
-   **remove** --help --force|f (aliases: *delete, rm, del, offboard*)

    The specified users are not really deleted from the applicable user
    directory, but rather removed from all groups. This will remove
    application access from the users, and free up the tool licenses.

-   **update** --help --proto *&lt;string&gt;* --groups *&lt;string&gt;*
    (aliases: *edit*)

    The command modifies one or more users by prototype, i.e. all
    relevant, non-idividual attributes of the prototype user, specified
    as argument to the --prot option, are applied to the specified
    user entries. In particular, the users are added and removed to/from
    groups so they match the prototype user.

Aws
---

The **AWS** realm commands work against a locally installed **aws**
commandline installation. The installation is [described in the AWS
documentation](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).

The following commands implemement a small subset of the AWS EC2 related
commands. Integration of other subsystem commands is straightforward.

Set the **show~curl~** variable to *1* in **rosh** ("`set show_curl `
1=") to see the *aws* calls composed by **rosh**.

### Authentication

The aws *access~token~* specified in the `$HOME/.rosh_preferences` file
is composed of the base64-encoded *aws~accesskeyid~*, and the
*aws~secretaccesskey~*, separated by a comma (use the supplied
`encode64.pl` utility, to encode the credentials.

AWS credentials are [obtained via the AWS web
console](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).

NOTE: the base64 encoded credentials are read by the AWSConnector module
supplied to **rosh** as part of the realm plugin installation. They are
passed to the local `aws` cli installation. Nothing is sent over the
network.

### AWS EC2 related Nouns

#### Groups

**Action verbs:**
-   **describe** --help --short|s --long|l --format|fmt *&lt;string&gt;*
    (aliases: *desc*)

    List names, and ids of all groups.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

    List names, and ids of all groups.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

#### Images

**Action verbs:**
-   **add** --help --desc|d *&lt;string&gt;*
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)

    List names, and ids of all images.

    Arguments to the command are treated as search names, and only
    images whose names match are included in the output.

-   **list** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    List names, and ids of all ec2 images.

    Arguments to the command are treated as search names, and only
    images whose names match are included in the output.

#### Nodes

*Nodes* are indentical with AWS EC2 *instances*.

**Action verbs:**
-   **add** --help --desc|d *&lt;string&gt;*
-   **delete** --force|f --help
-   **describe** --help --short|s --long|l --format|fmt *&lt;string&gt;*
    (aliases: *desc*)

    List names, and ids of all nodes.

    Arguments to the command are treated as search names, and only nodes
    whose names match are included in the output.

-   **list** --help --short|s --long|l --format|fmt *&lt;string&gt;*
    (aliases: *ls*)

    List names, and ids of all ec2 nodes.

    Arguments to the command are treated as search names, and only nodes
    whose names match are included in the output.

-   **start** --help
-   **stop** --force|f --help

#### Policies

**Action verbs:**
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

    List names, and ids of all policies.

    Arguments to the command are treated as search names, and only
    policies whose names match are included in the output.

#### Roles

**Action verbs:**
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

    List names, and ids of all roles.

    Arguments to the command are treated as search names, and only roles
    whose names match are included in the output.

#### Subnets

**Action verbs:**
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

#### Users

**Action verbs:**
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

#### Vpcs

**Action verbs:**
-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *ls*)

Crowd
-----

The **Crowd** realm commands work directly against the [Crowd REST
API](https://www.jfrog.com/confluence/display/RTF/Artifactory+REST+API).
The *nouns* correspond to the *Resource* classes defined by the Crowd
API.

The exact API call sent by **rosh** to the web endpoint can be obtained
by setting the **show~curl~** variable to *1* in **rosh**
("`set show_curl ` 1=").

### Authentication

The [Crowd REST
API](https://docs.atlassian.com/atlassian-crowd/3.1.2/REST/) is not
intended for direct user access but rather to be accessed from
*applications* that depend on services provided by crowd. In order to
authenticate to the Crowd server, the IP address of the computer sending
the request must be cleared for access. Application credentials (name
and password) and IP-based access to Crowd must be configured through
the Crowd web interface.

The Crowd *access~token~* specified in the `$HOME/.rosh_preferences`
file is composed of the base64-encoded *application name*, and the
application's *password*, separated by a colon (':') (use the supplied
`encode64.pl` utility, to encode the credentials).

### Nouns

#### Groups

**Action verbs:**
-   **add** --help --desc|d *&lt;string&gt;*
-   **add member to** --help (aliases: *add user to*)
-   **delete** --force|f --help
-   **describe** --help --long|l --short|s (aliases: *desc, list members
    of, list members in, list users in*)

    List names, and ids of all subgroups contained in the group passed
    as argument.

-   **edit** --help --group *&lt;string&gt;* --name|n *&lt;string&gt;*
    --path *&lt;string&gt;* --in *&lt;string&gt;* --desc|d
    *&lt;string&gt;* --visibility *&lt;string&gt;*
-   **list** --help

    List names, and ids of all groups.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.

-   **remove member from** --help (aliases: *remove user from*)

#### Users

**Action verbs:**
-   **create** --help --proto *&lt;string&gt;* --name|n *&lt;string&gt;*
    --email *&lt;string&gt;* --surname|sn *&lt;string&gt;*
    --givenname|gn *&lt;string&gt;* --groups *&lt;string&gt;* (aliases:
    *add*)

    The command modifies one or more users by prototype, i.e. all
    relevant, non-idividual attributes of the prototype user, specified
    as argument to the --prot option, are applied to the specified
    user entries. In particular, the users are added and removed to/from
    groups so they match the prototype user.

-   **describe** --help --long|l --format|fmt *&lt;string&gt;* --short|s
    (aliases: *desc, get*)
-   **edit** --help --email *&lt;string&gt;* --surname|sn
    *&lt;string&gt;* --givenname|gn *&lt;string&gt;* --groups
    *&lt;string&gt;* --proto *&lt;string&gt;* --force|f
    --reset-password|resetpw (aliases: *update, change*)
-   **list** --help (aliases: *ls*)
-   **remove** --help --force|f (aliases: *delete, rm, del, offboard*)

    The specified users are not really deleted from the applicable user
    directory, but rather removed from all groups. This will remove
    application access from the users, and free up the tool licenses.

Ldap
----

The **Ldap** realm provides nothing more than a quick lookup facility
for user account data in the corporate directory (typically AD). It
works directly against the Ldap sercice endpoint, by means of perl's
**Net::LDAP** module.

Because of the variability of the user data schema, the LdapConnector
class that is part of the realm plugin implementation makes assumptions
about the particular directory it is querying. Thus, the module is not
generally portable, and should be treated as confidential.

### Authentication

The Ldap *access~token~* specified in the `$HOME/.rosh_preferences` file
is composed of the base64-encoded *domain-qualified username*, and the
user's *password*, separated by a single space (use the supplied
`encode64.pl` utility, to encode the credentials).

#### Users

**Action verbs:**
-   **describe** --help --long|l --short|s --format|fmt *&lt;string&gt;*
    (aliases: *desc*)
-   **list** --help --long|l --format|fmt *&lt;string&gt;* --short|s

    List names, and ids of matching user entries.

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
