package JiraCLI::Filters_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Filters');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsflt',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsflt_usage,
		    'description' => 'list filter',
                    'category' => 'filter',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        favorite|fave
				      )
				  ],
		   },
		   {
		    'name' => 'descflt',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&gcli_descflt_usage,
		    'description' => 'describe filter',
                    'category' => 'filter',
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
		    'name' => 'addflt',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&gcli_addflt_usage,
		    'description' => 'add filter',
                    'category' => 'filter',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        name|n=s
		                        proto=s
		                        jql=s
		                        desc|d=s
		                        favorite|fave
				      )
				  ],
		   },
		   {
		    'name' => 'deleteflt',                                # external command name (used by user)
                    'verb' => [ 'delete' ],
                    'usage' => \&gcli_deleteflt_usage,
		    'description' => 'delete filter',
                    'category' => 'filter',
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
		    'name' => 'editflt',                                # external command name (used by user)
                    'verb' => [ 'edit', 'update' ],
                    'usage' => \&gcli_editflt_usage,
		    'description' => 'edit filter',
                    'category' => 'filter',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        name|n=s
		                        desc|d=s
		                        jql=s
		                        favorite|fave
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsflt_usage
{
#    return "** UNIMPLEMENTED **";

    return "list filter --help --long|l --short|s --favorite|fave [ name.. ]

DESCRIPTION:
    List names, and ids of all filters owned by or visible to the caller.

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
    --favorite|fave    Description for option fave
";
}

sub gcli_descflt_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe filter --help --long|l --short|s --format|fmt=s 

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

sub gcli_addflt_usage
{
#    return "** UNIMPLEMENTED **";

    return "add filter --help --name|n=s --proto=s --jql=s --desc|d=s --favorite|fave 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --name|n=s    Description for option name
    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

    --jql=s
        Specify a (quoted) JQL query for a Jira issue search expression.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --desc|d=s
        Specify a short (quoted) description for a Jira resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --favorite|fave    Description for option fave
";
}

sub gcli_deleteflt_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete filter --force|f --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

";
}

sub gcli_editflt_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit filter --help --name|n=s --desc|d=s --jql=s --favorite|fave 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --name|n=s    Description for option name
    --desc|d=s
        Specify a short (quoted) description for a Jira resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --jql=s
        Specify a (quoted) JQL query for a Jira issue search expression.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --favorite|fave    Description for option fave
";
}



1;
