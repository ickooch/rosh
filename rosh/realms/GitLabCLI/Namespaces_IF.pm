package GitLabCLI::Namespaces_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Namespaces');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsns',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsns_usage,
		    'description' => 'list namespace',
                    'category' => 'namespace',
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
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsns_usage
{
#    return "** UNIMPLEMENTED **";

    return "list namespace --help --long|l --short|s [ name.. ]

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



1;
