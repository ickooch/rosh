package ArtifactoryCLI::Groups_IF;

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
                    'usage' => \&atfcli_lsgrp_usage,
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
		    'name' => 'lsgrp_members',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&atfcli_lsgrp_members_usage,
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
                    'usage' => \&atfcli_addgrp_members_usage,
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
                    'usage' => \&atfcli_rmgrp_members_usage,
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
                    'usage' => \&atfcli_addgrp_usage,
		    'description' => 'add group',
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
		    'name' => 'deletegrp',                                # external command name (used by user)
                    'verb' => [ 'delete' ],
                    'usage' => \&atfcli_deletegrp_usage,
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
                    'usage' => \&atfcli_editgrp_usage,
		    'description' => 'edit group',
                    'category' => 'group',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub atfcli_lsgrp_usage
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

sub atfcli_lsgrp_members_usage
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

sub atfcli_addgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "add member to group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_rmgrp_members_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove member from group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_addgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "add group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_deletegrp_usage
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

sub atfcli_editgrp_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit group --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}



1;
