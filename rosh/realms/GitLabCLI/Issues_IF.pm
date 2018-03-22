package GitLabCLI::Issues_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Issues');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsiss',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&gcli_lsiss_usage,
		    'description' => 'list issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        limit|max=i
		                        in=s
		                        on|on-board|board=s
		                        filter=s
		                        all|a
				      )
				  ],
		   },
		   {
		    'name' => 'lsmyiss',                                # external command name (used by user)
                    'verb' => [ 'list my', 'ls my' ],
                    'usage' => \&gcli_lsmyiss_usage,
		    'description' => 'list my issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        userid=i
		                        format|fmt=s
		                        all|a
		                        filter=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'lstmpiss',                                # external command name (used by user)
                    'verb' => [ 'list templates for', 'ls templ' ],
                    'usage' => \&gcli_lstmpiss_usage,
		    'description' => 'list templates for issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'desciss',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc', 'cat' ],
                    'usage' => \&gcli_desciss_usage,
		    'description' => 'describe issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        in=s
		                        with=s
				      )
				  ],
		   },
		   {
		    'name' => 'addiss',                                # external command name (used by user)
                    'verb' => [ 'new', 'add', 'create' ],
                    'usage' => \&gcli_addiss_usage,
		    'description' => 'new issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        labels|type=s
		                        title=s
		                        desc|d=s
		                        assign-to=s
		                        milestone=s
				      )
				  ],
		   },
		   {
		    'name' => 'deliss',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete', 'rm', 'del' ],
                    'usage' => \&gcli_deliss_usage,
		    'description' => 'remove issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        help
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'asgiss',                                # external command name (used by user)
                    'verb' => [ 'assign' ],
                    'usage' => \&gcli_asgiss_usage,
		    'description' => 'assign issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        to=s
		                        comment|c=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'crbriss',                                # external command name (used by user)
                    'verb' => [ 'create branch for', 'add branch for' ],
                    'usage' => \&gcli_crbriss_usage,
		    'description' => 'create branch for issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        for=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'cmtiss',                                # external command name (used by user)
                    'verb' => [ 'comment' ],
                    'usage' => \&gcli_cmtiss_usage,
		    'description' => 'comment issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        comment|c=s
				      )
				  ],
		   },
		   {
		    'name' => 'watiss',                                # external command name (used by user)
                    'verb' => [ 'watch', 'subscribe', 'sub' ],
                    'usage' => \&gcli_watiss_usage,
		    'description' => 'watch issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'uwatiss',                                # external command name (used by user)
                    'verb' => [ 'unwatch', 'unsubscribe', 'unsub' ],
                    'usage' => \&gcli_uwatiss_usage,
		    'description' => 'unwatch issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'transiss',                                # external command name (used by user)
                    'verb' => [ 'transition', 'trans', 'move', 'advance', 'adv', 'push', 'close', 'reopen' ],
                    'usage' => \&gcli_transiss_usage,
		    'description' => 'transition issue',
                    'category' => 'issue',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        from=s
		                        to=s
		                        no-comment|nc
		                        in=s
		                        comment|c=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "list issue --help --long|l --short|s --format|fmt=s --limit|max=i --in=s --on|on-board|board=s --filter=s --all|a [ name.. ]

DESCRIPTION:
    List active issues in the specified project, or according to one of the
    selection options.
    By default, only active issues are returned. Option --all can be set to
    include closed, and resolved issues in the output, too.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

    --short|s    Description for option short
    --format|fmt=s
        Specify a template string to define a custom format
        for the produced output.
        
        The string argument can be a filename containing the
        format template, or a verbatim template string.
        
        Template strings consist of regular text that is kept
        verbatim in the output, and /format codes/ that are
        substituted by fields in the found data items. Format
        codes start with a '%' and are followed by a letter
        indicating the data field that is to be substituted.
        
        The following format codes are recognized:
          %F:<fieldname> - generic field access: the expression
               %F:<fieldname> is substituted by the value of
               specified field as found in the object descriptor.
               In many cases, available field names can be
               obtained by list or describe of an object with
               the --long option.
          %H - the HTTPS URL of the object (if available)
          %i - the numeric id of the object
          %I - the URL encoded id of the object
          %n - the name of the object (if available - if not,
               an empty string is substituted)
          %N - the name_with_path of an object
          %p - the path of the object
          %P - the full_path of the object
          %S - the ssh URL of the object (if available)
          %U - the web URL of the object (if available)

    --limit|max=i
        For list output, limit the number of rows that are reported.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --on|on-board|board=s
        List issues on the board indicated by the argument to the --on-board
        switch. Issues are selected with the filter associated with the board.
        Output is grouped by the columns defined in the board.

    --filter=s
        Restrict diff output to kind of changes specified as filter argument:
            - A - select files added
            - D - select files deleted
            - M - select files modified
            - R - select file renames
        Any combination of filter keys is possible.
        If no filter is specified, all differences will be listed.

    --all|a
        Do not restrict output by any kind of built-in filter
        logic, such as only listing projects that are listed
        in one of the caller's namespaces.

        Note, that requesting all possible entries may result
        in extended response times because of GitLab's
        paginating API returns (i.e. there may be many
        sequential GET requests involved). 

";
}

sub gcli_lsmyiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "list my issue --help --long|l --short|s --userid=i --format|fmt=s --all|a --filter=s --in=s [ name.. ]

DESCRIPTION:
    List issues assigned to, or reported by the current user. By default
    the current user is the user used to connect to Jira. The concept of
    current user can be modified with the option --user <userid>.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

    --short|s    Description for option short
    --userid=i    Description for option userid
    --format|fmt=s
        Specify a template string to define a custom format
        for the produced output.
        
        The string argument can be a filename containing the
        format template, or a verbatim template string.
        
        Template strings consist of regular text that is kept
        verbatim in the output, and /format codes/ that are
        substituted by fields in the found data items. Format
        codes start with a '%' and are followed by a letter
        indicating the data field that is to be substituted.
        
        The following format codes are recognized:
          %F:<fieldname> - generic field access: the expression
               %F:<fieldname> is substituted by the value of
               specified field as found in the object descriptor.
               In many cases, available field names can be
               obtained by list or describe of an object with
               the --long option.
          %H - the HTTPS URL of the object (if available)
          %i - the numeric id of the object
          %I - the URL encoded id of the object
          %n - the name of the object (if available - if not,
               an empty string is substituted)
          %N - the name_with_path of an object
          %p - the path of the object
          %P - the full_path of the object
          %S - the ssh URL of the object (if available)
          %U - the web URL of the object (if available)

    --all|a
        Do not restrict output by any kind of built-in filter
        logic, such as only listing projects that are listed
        in one of the caller's namespaces.

        Note, that requesting all possible entries may result
        in extended response times because of GitLab's
        paginating API returns (i.e. there may be many
        sequential GET requests involved). 

    --filter=s
        Restrict diff output to kind of changes specified as filter argument:
            - A - select files added
            - D - select files deleted
            - M - select files modified
            - R - select file renames
        Any combination of filter keys is possible.
        If no filter is specified, all differences will be listed.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_lstmpiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "list templates for issue --help --long|l --short|s --in=s [ name.. ]

DESCRIPTION:
    List issue templates for the current project. The templates are markdown
    files stored in the .gitlab/issue_templates/ directory.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

    --short|s    Description for option short
    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_desciss_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe issue --help --long|l --short|s --format|fmt=s --in=s --with=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

    --short|s    Description for option short
    --format|fmt=s
        Specify a template string to define a custom format
        for the produced output.
        
        The string argument can be a filename containing the
        format template, or a verbatim template string.
        
        Template strings consist of regular text that is kept
        verbatim in the output, and /format codes/ that are
        substituted by fields in the found data items. Format
        codes start with a '%' and are followed by a letter
        indicating the data field that is to be substituted.
        
        The following format codes are recognized:
          %F:<fieldname> - generic field access: the expression
               %F:<fieldname> is substituted by the value of
               specified field as found in the object descriptor.
               In many cases, available field names can be
               obtained by list or describe of an object with
               the --long option.
          %H - the HTTPS URL of the object (if available)
          %i - the numeric id of the object
          %I - the URL encoded id of the object
          %n - the name of the object (if available - if not,
               an empty string is substituted)
          %N - the name_with_path of an object
          %p - the path of the object
          %P - the full_path of the object
          %S - the ssh URL of the object (if available)
          %U - the web URL of the object (if available)

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --with=s    Description for option with
";
}

sub gcli_addiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "new issue --help --in=s --labels|type=s --title=s --desc|d=s --assign-to=s --milestone=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --labels|type=s
        Comma-separated list of labels for the item.

    --title=s
        Title of the issue.

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --assign-to=s
        User Id of the person the merge request is assigned to.

    --milestone=s
        The ID of a milestone.

";
}

sub gcli_deliss_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove issue --force|f --help --in=s 

DESCRIPTION:
Delete an issue in the specified (or current) project.

The instance id of the issue must be specified as argument to the
command.

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_asgiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "assign issue --help --to=s --comment|c=s --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --comment|c=s
        Provide a quoted comment for a GitLab issue.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        comment from this file, if one is found.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_crbriss_usage
{
#    return "** UNIMPLEMENTED **";

    return "create branch for issue --help --for=s --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --for=s    Description for option for_id
    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_cmtiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "comment issue --help --in=s --comment|c=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --comment|c=s
        Provide a quoted comment for a GitLab issue.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        comment from this file, if one is found.

";
}

sub gcli_watiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "watch issue --help --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_uwatiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "unwatch issue --help --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

";
}

sub gcli_transiss_usage
{
#    return "** UNIMPLEMENTED **";

    return "transition issue --help --from=s --to=s --no-comment|nc --in=s --comment|c=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --from=s    Description for option from_original
    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --no-comment|nc
        Deny a comment (acquired by default).

    --in=s
        This is a generic option to specify a context object - usually
        some kind of namespace - for an operation. The particular
        context depends on the /noun/ in the command expression.

        Example:
        * in a 'list projects --in <group>', the referenced context is a
          /group/ namespace.
        * in a 'add webhook --in <project>', the referenced context is
          a /project/ object.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --comment|c=s
        Provide a quoted comment for a GitLab issue.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        comment from this file, if one is found.

";
}



1;
