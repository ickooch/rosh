package CrowdCLI::Groups_IF;

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
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsgrp_usage,
		    'description' => 'list group',
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
		    'name' => 'lsgrp_members',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc', 'list members of', 'list members in', 'list users in' ],
                    'usage' => \&gcli_lsgrp_members_usage,
		    'description' => 'describe group',
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
				      )
				  ],
		   },
		   {
		    'name' => 'rmgrp_members',                                # external command name (used by user)
                    'verb' => [ 'remove member from', 'remove user from' ],
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
		    'name' => 'addgrp',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&gcli_addgrp_usage,
		    'description' => 'add group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        desc|d=s
				      )
				  ],
		   },
		   {
		    'name' => 'deletegrp',                                # external command name (used by user)
                    'verb' => [ 'delete' ],
                    'usage' => \&gcli_deletegrp_usage,
		    'description' => 'delete group',
                    'category' => 'group',
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
		    'name' => 'editgrp',                                # external command name (used by user)
                    'verb' => [ 'edit' ],
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

    return "list group --help [ name.. ]

DESCRIPTION:
    List names, and ids of all groups.

    Arguments to the command are treated as search names, and only
    groups whose names match are included in the output.      

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_lsgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe group --help --long|l --short|s 

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

    return "add member to group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

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

sub gcli_addgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "add group --help --desc|d=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --desc|d=s
        Specify a short (quoted) description for a Crowd resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

";
}

sub gcli_deletegrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete group --force|f --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

";
}

sub gcli_editgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit group --help --group=s --name|n=s --path=s --in=s --desc|d=s --visibility=s 

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

    --desc|d=s
        Specify a short (quoted) description for a Crowd resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --visibility=s    Description for option visibility
";
}



1;
