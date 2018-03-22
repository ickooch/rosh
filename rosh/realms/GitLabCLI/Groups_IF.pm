package GitLabCLI::Groups_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Groups');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsgrp',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&gcli_lsgrp_usage,
		    'description' => 'list group',
                    'category' => 'group',
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
		    'name' => 'lsgrp_projects',                                # external command name (used by user)
                    'verb' => [ 'list projects in', 'ls projects in' ],
                    'usage' => \&gcli_lsgrp_projects_usage,
		    'description' => 'list projects in group',
                    'category' => 'group',
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
		    'name' => 'lsgrp_members',                                # external command name (used by user)
                    'verb' => [ 'list members of', 'list members in', 'list users in', 'ls members of' ],
                    'usage' => \&gcli_lsgrp_members_usage,
		    'description' => 'list members of group',
                    'category' => 'group',
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
		    'name' => 'addgrp_members',                                # external command name (used by user)
                    'verb' => [ 'add member to', 'add user to' ],
                    'usage' => \&gcli_addgrp_members_usage,
		    'description' => 'add member to group',
                    'category' => 'group',
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
		    'name' => 'rmgrp_members',                                # external command name (used by user)
                    'verb' => [ 'remove member from', 'remove user from', 'rm member from' ],
                    'usage' => \&gcli_rmgrp_members_usage,
		    'description' => 'remove member from group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'descgrp',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&gcli_descgrp_usage,
		    'description' => 'describe group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        json
				      )
				  ],
		   },
		   {
		    'name' => 'addgrp',                                # external command name (used by user)
                    'verb' => [ 'add', 'new', 'create' ],
                    'usage' => \&gcli_addgrp_usage,
		    'description' => 'add group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        path=s
		                        proto=s
		                        in=s
		                        desc|d=s
		                        visibility=s
				      )
				  ],
		   },
		   {
		    'name' => 'deletegrp',                                # external command name (used by user)
                    'verb' => [ 'delete', 'del', 'remove', 'rm' ],
                    'usage' => \&gcli_deletegrp_usage,
		    'description' => 'delete group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        recursive|r
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'editgrp',                                # external command name (used by user)
                    'verb' => [ 'edit', 'update', 'change' ],
                    'usage' => \&gcli_editgrp_usage,
		    'description' => 'edit group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        group=s
		                        name|n=s
		                        path=s
		                        in=s
		                        enable=s
		                        disable=s
		                        desc|d=s
		                        visibility=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "list group --help --long|l --short|s [ name.. ]

DESCRIPTION:
    List names, and ids of all groups owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.      

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

sub gcli_lsgrp_projects_usage
{
#    return "** UNIMPLEMENTED **";

    return "list projects in group --help --long|l --short|s 

DESCRIPTION:
List names, and ids of all projects contained in the group or
subgroup passed as argument.

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

sub gcli_lsgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "list members of group --help --long|l --short|s 

DESCRIPTION:
List names, and ids of all subgroups contained in the group
passed as argument.

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

sub gcli_addgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "add member to group --help --as=s 

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

sub gcli_rmgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove member from group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_descgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe group --help --long|l --short|s --format|fmt=s --json 

DESCRIPTION:
Output all relevant details of the group given as argument.

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

    --json
        Descriptive output is printed as JSON document. This is useful
        for further automated prcessing of the returned information.

";
}

sub gcli_addgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "add group --help --path=s --proto=s --in=s --desc|d=s --visibility=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --path=s    Description for option path
    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

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
";
}

sub gcli_deletegrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete group --force|f --recursive|r --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --recursive|r
        If the option /--recursive/ is set, the operation applies to
        all entities that are referenced by the transitive closure
        of a group context (possibly defined with --to).

    --help
        Print this help, and command usage information.

";
}

sub gcli_editgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit group --help --group=s --name|n=s --path=s --in=s --enable=s --disable=s --desc|d=s --visibility=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --group=s    Description for option group
    --name|n=s    Description for option name
    --path=s    Description for option path
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

    --desc|d=s
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --visibility=s    Description for option visibility
";
}



1;
