package GitLabCLI::Projects_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Projects');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsprj',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&gcli_lsprj_usage,
		    'description' => 'list project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        in=s
		                        all|a
		                        recursive|r
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'lsprj_members',                                # external command name (used by user)
                    'verb' => [ 'list members of' ],
                    'usage' => \&gcli_lsprj_members_usage,
		    'description' => 'list members of project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
				      )
				  ],
		   },
		   {
		    'name' => 'addprj_members',                                # external command name (used by user)
                    'verb' => [ 'add member to', 'add user to' ],
                    'usage' => \&gcli_addprj_members_usage,
		    'description' => 'add member to project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        as=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmprj_members',                                # external command name (used by user)
                    'verb' => [ 'remove member from', 'remove user from' ],
                    'usage' => \&gcli_rmprj_members_usage,
		    'description' => 'remove member from project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'descprj',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&gcli_descprj_usage,
		    'description' => 'describe project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'mkprj',                                # external command name (used by user)
                    'verb' => [ 'create', 'add', 'new' ],
                    'usage' => \&gcli_mkprj_usage,
		    'description' => 'create project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        desc|d=s
		                        visibility=s
		                        branch|b=s
		                        enable=s
		                        url=s
		                        proto=s
				      )
				  ],
		   },
		   {
		    'name' => 'moveprj',                                # external command name (used by user)
                    'verb' => [ 'move', 'rename', 'mv', 'ren', 'transfer', 'trans' ],
                    'usage' => \&gcli_moveprj_usage,
		    'description' => 'move project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        from=s
		                        to=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmprj',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete' ],
                    'usage' => \&gcli_rmprj_usage,
		    'description' => 'remove project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'editprj',                                # external command name (used by user)
                    'verb' => [ 'update', 'edit', 'change' ],
                    'usage' => \&gcli_editprj_usage,
		    'description' => 'update project',
                    'category' => 'project',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        desc|d=s
		                        visibility=s
		                        in=s
		                        name|n=s
		                        path=s
		                        proto=s
		                        branch|b=s
		                        enable=s
		                        disable=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "list project --help --long|l --short|s --in=s --all|a --recursive|r --format|fmt=s [ name.. ]

DESCRIPTION:
    List names, and ids of all projects listed in a group or
    subgroup (namespace) owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    projects whose names match are included in the output.      

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

    --all|a
        Do not restrict output by any kind of built-in filter
        logic, such as only listing projects that are listed
        in one of the caller's namespaces.

        Note, that requesting all possible entries may result
        in extended response times because of GitLab's
        paginating API returns (i.e. there may be many
        sequential GET requests involved). 

    --recursive|r
        If the option /--recursive/ is set, the operation applies to
        all entities that are referenced by the transitive closure
        of a group context (possibly defined with --to).

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

";
}

sub gcli_lsprj_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "list members of project --help --long|l --short|s [ name.. ]

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
";
}

sub gcli_addprj_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "add member to project --help --as=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --as=s
        Specify the role or permission level granted to the user for
        which the command is run.
        
        Permission levels are specified numerically.
        The following levels can be granted to a user:
           10 => Guest access
           20 => Reporter access
           30 => Developer access
           40 => Master access
           50 => Owner access # Only valid for groups

";
}

sub gcli_rmprj_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove member from project --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_descprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe project --help --long|l --short|s --format|fmt=s 

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

";
}

sub gcli_mkprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "create project --help --in=s --desc|d=s --visibility=s --branch|b=s --enable=s --url=s --proto=s 

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

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --visibility=s    Description for option visibility
    --branch|b=s    Description for option branch
    --enable=s
        Enable the command specific options or features
        identified in the comma-separated list of option
        keywords. Each of the options is taken to be a boolean
        that is set to 'true' if the keyword is listed.

        The following keywords are recognized:
            issues
            container_registry
            containers
            jobs
            lfs
            merge_requests / mr
            merge_requires_green_build
            merge_requires_resolved_discussion
            request_access / request
            runners
            shared_runners
            snippets
            wiki

    --url=s
        Specify the URL of the resource or endpoint referenced
        in the command.

    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

";
}

sub gcli_moveprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "move project --help --from=s --to=s 

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

";
}

sub gcli_rmprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove project --force|f --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

";
}

sub gcli_editprj_usage
{
#    return "** UNIMPLEMENTED **";

    return "update project --help --desc|d=s --visibility=s --in=s --name|n=s --path=s --proto=s --branch|b=s --enable=s --disable=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --visibility=s    Description for option visibility
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

    --name|n=s    Description for option name
    --path=s    Description for option path
    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

    --branch|b=s    Description for option branch
    --enable=s
        Enable the command specific options or features
        identified in the comma-separated list of option
        keywords. Each of the options is taken to be a boolean
        that is set to 'true' if the keyword is listed.

        The following keywords are recognized:
            issues
            container_registry
            containers
            jobs
            lfs
            merge_requests / mr
            merge_requires_green_build
            merge_requires_resolved_discussion
            request_access / request
            runners
            shared_runners
            snippets
            wiki

    --disable=s
        Disable the resource specific options or features
        identified in the comma-separated list of option
        keywords. Each of the options is taken to be a boolean
        that is set to 'false' if the keyword is listed.

        The following keywords are recognized:
            issues
            container_registry
            containers
            jobs
            lfs
            merge_requests / mr
            merge_requires_green_build
            merge_requires_resolved_discussion
            request_access / request
            runners
            shared_runners
            snippets
            wiki

";
}



1;
