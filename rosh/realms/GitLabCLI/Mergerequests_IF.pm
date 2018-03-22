package GitLabCLI::Mergerequests_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Mergerequests');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsmr',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsmr_usage,
		    'description' => 'list merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        labels|type=s
		                        milestone=s
		                        limit|max=i
		                        short|s
		                        format|fmt=s
		                        all|a
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'lsnotemr',                                # external command name (used by user)
                    'verb' => [ 'list comments to', 'list notes for', 'list comments', 'list notes' ],
                    'usage' => \&gcli_lsnotemr_usage,
		    'description' => 'list comments to merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        limit|max=i
		                        short|s
		                        format|fmt=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'descmr',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&gcli_descmr_usage,
		    'description' => 'describe merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        with=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'cmtmr',                                # external command name (used by user)
                    'verb' => [ 'comment' ],
                    'usage' => \&gcli_cmtmr_usage,
		    'description' => 'comment merge',
                    'category' => 'merge',
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
		    'name' => 'getmr',                                # external command name (used by user)
                    'verb' => [ 'get' ],
                    'usage' => \&gcli_getmr_usage,
		    'description' => 'get merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        commits
		                        changes
		                        file|f
				      )
				  ],
		   },
		   {
		    'name' => 'cancelmr',                                # external command name (used by user)
                    'verb' => [ 'cancel', 'abort' ],
                    'usage' => \&gcli_cancelmr_usage,
		    'description' => 'cancel merge',
                    'category' => 'merge',
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
		    'name' => 'acceptmr',                                # external command name (used by user)
                    'verb' => [ 'do', 'accept', 'merge', 'exec', 'execute' ],
                    'usage' => \&gcli_acceptmr_usage,
		    'description' => 'do merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        sha=s
		                        message|msg=s
		                        rm-source-branch|delete-branch
				      )
				  ],
		   },
		   {
		    'name' => 'approvemr',                                # external command name (used by user)
                    'verb' => [ 'approve' ],
                    'usage' => \&gcli_approvemr_usage,
		    'description' => 'approve merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        sha=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'unapprovemr',                                # external command name (used by user)
                    'verb' => [ 'unapprove' ],
                    'usage' => \&gcli_unapprovemr_usage,
		    'description' => 'unapprove merge',
                    'category' => 'merge',
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
		    'name' => 'erasemr',                                # external command name (used by user)
                    'verb' => [ 'delete', 'erase', 'remove' ],
                    'usage' => \&gcli_erasemr_usage,
		    'description' => 'delete merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        force|f
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'addmr',                                # external command name (used by user)
                    'verb' => [ 'add', 'create' ],
                    'usage' => \&gcli_addmr_usage,
		    'description' => 'add merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        from=s
		                        to=s
		                        title=s
		                        desc|d=s
		                        rm-source-branch|delete-branch
		                        assign-to=s
		                        labels|type=s
		                        squash
		                        milestone=s
				      )
				  ],
		   },
		   {
		    'name' => 'editmr',                                # external command name (used by user)
                    'verb' => [ 'edit', 'update' ],
                    'usage' => \&gcli_editmr_usage,
		    'description' => 'edit merge',
                    'category' => 'merge',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        title=s
		                        desc|d=s
		                        assign-to=s
		                        to=s
		                        rm-source-branch|delete-branch
		                        labels|type=s
		                        squash
		                        milestone=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "list merge --help --long|l --labels|type=s --milestone=s --limit|max=i --short|s --format|fmt=s --all|a --in=s [ name.. ]

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

    --labels|type=s
        Comma-separated list of labels for the item.

    --milestone=s
        The ID of a milestone.

    --limit|max=i
        For list output, limit the number of rows that are reported.

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

    --all|a
        Do not restrict output by any kind of built-in filter
        logic, such as only listing projects that are listed
        in one of the caller's namespaces.

        Note, that requesting all possible entries may result
        in extended response times because of GitLab's
        paginating API returns (i.e. there may be many
        sequential GET requests involved). 

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

sub gcli_lsnotemr_usage
{
#    return "** UNIMPLEMENTED **";

    return "list comments to merge --help --long|l --limit|max=i --short|s --format|fmt=s --in=s [ name.. ]

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

    --limit|max=i
        For list output, limit the number of rows that are reported.

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

";
}

sub gcli_descmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe merge --help --long|l --short|s --format|fmt=s --with=s --in=s 

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

    --with=s    Description for option with
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

sub gcli_cmtmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "comment merge --help --in=s --comment|c=s 

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

sub gcli_getmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "get merge --help --in=s --commits --changes --file|f 

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

    --commits
        Get a list of merge request commits.

    --changes
        Show information about the merge request including its files and changes.

    --file|f    Description for option file
";
}

sub gcli_cancelmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "cancel merge --help --in=s 

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

sub gcli_acceptmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "do merge --help --in=s --sha=s --message|msg=s --rm-source-branch|delete-branch 

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

    --sha=s    Description for option sha
    --message|msg=s
        Commit message to be used for the merge.

    --rm-source-branch|delete-branch
        Remove the source branch if merge succeeds.

";
}

sub gcli_approvemr_usage
{
#    return "** UNIMPLEMENTED **";

    return "approve merge --help --sha=s --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --sha=s    Description for option sha
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

sub gcli_unapprovemr_usage
{
#    return "** UNIMPLEMENTED **";

    return "unapprove merge --help --in=s 

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

sub gcli_erasemr_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete merge --help --force|f --in=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --force|f    Description for option force
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

sub gcli_addmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "add merge --help --in=s --from=s --to=s --title=s --desc|d=s --rm-source-branch|delete-branch --assign-to=s --labels|type=s --squash --milestone=s 

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

    --from=s    Description for option from_original
    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --title=s
        Title of the merge request.

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --rm-source-branch|delete-branch
        Remove the source branch if merge succeeds.

    --assign-to=s
        User Id of the person the merge request is assigned to.

    --labels|type=s
        Comma-separated list of labels for the item.

    --squash
        Squash commits into a single commit when merging.

    --milestone=s
        The ID of a milestone.

";
}

sub gcli_editmr_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit merge --help --in=s --title=s --desc|d=s --assign-to=s --to=s --rm-source-branch|delete-branch --labels|type=s --squash --milestone=s 

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

    --title=s
        Title of the merge request.

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --assign-to=s
        User Id of the person the merge request is assigned to.

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --rm-source-branch|delete-branch
        Remove the source branch if merge succeeds.

    --labels|type=s
        Comma-separated list of labels for the item.

    --squash
        Squash commits into a single commit when merging.

    --milestone=s
        The ID of a milestone.

";
}



1;
