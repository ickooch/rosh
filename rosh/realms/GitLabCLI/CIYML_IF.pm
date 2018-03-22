package GitLabCLI::CIYML_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('CIYML');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsyml',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsyml_usage,
		    'description' => 'list yml-template',
                    'category' => 'yml-template',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'descyml',                                # external command name (used by user)
                    'verb' => [ 'describe' ],
                    'usage' => \&gcli_descyml_usage,
		    'description' => 'describe yml-template',
                    'category' => 'yml-template',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'catyml',                                # external command name (used by user)
                    'verb' => [ 'get' ],
                    'usage' => \&gcli_catyml_usage,
		    'description' => 'get yml-template',
                    'category' => 'yml-template',
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
sub gcli_lsyml_usage
{
#    return "** UNIMPLEMENTED **";

    return "list yml-template --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_descyml_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe yml-template --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_catyml_usage
{
#    return "** UNIMPLEMENTED **";

    return "get yml-template --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}



1;
