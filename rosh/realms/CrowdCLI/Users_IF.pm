package CrowdCLI::Users_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Users');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsusr',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&gcli_lsusr_usage,
		    'description' => 'list user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'descusr',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc', 'get' ],
                    'usage' => \&gcli_descusr_usage,
		    'description' => 'describe user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        format|fmt=s
		                        short|s
				      )
				  ],
		   },
		   {
		    'name' => 'mkusr',                                # external command name (used by user)
                    'verb' => [ 'create', 'add' ],
                    'usage' => \&gcli_mkusr_usage,
		    'description' => 'create user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        proto=s
		                        name|n=s
		                        email=s
		                        surname|sn=s
		                        givenname|gn=s
		                        groups=s
				      )
				  ],
		   },
		   {
		    'name' => 'editusr',                                # external command name (used by user)
                    'verb' => [ 'edit', 'update', 'change' ],
                    'usage' => \&gcli_editusr_usage,
		    'description' => 'edit user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        email=s
		                        surname|sn=s
		                        givenname|gn=s
		                        groups=s
		                        proto=s
		                        force|f
		                        reset-password|resetpw
				      )
				  ],
		   },
		   {
		    'name' => 'rmusr',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete', 'rm', 'del', 'offboard' ],
                    'usage' => \&gcli_rmusr_usage,
		    'description' => 'remove user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        force|f
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "list user --help [ name.. ]

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub gcli_descusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe user --help --long|l --format|fmt=s --short|s 

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

    --short|s    Description for option short
";
}

sub gcli_mkusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "create user --help --proto=s --name|n=s --email=s --surname|sn=s --givenname|gn=s --groups=s 

DESCRIPTION:
    The command modifies one or more users by prototype,
    i.e. all relevant, non-idividual attributes of the prototype
    user, specified as argument to the --prot option, are
    applied to the specified user entries. In particular, the
    users are added and removed to/from groups so they match the
    prototype user.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

    --name|n=s    Description for option name
    --email=s    Description for option user_email
    --surname|sn=s    Description for option surname
    --givenname|gn=s    Description for option givenname
    --groups=s
        Specify one or more groups in the format
           group1,group2,..

";
}

sub gcli_editusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit user --help --email=s --surname|sn=s --givenname|gn=s --groups=s --proto=s --force|f --reset-password|resetpw 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --email=s    Description for option user_email
    --surname|sn=s    Description for option surname
    --givenname|gn=s    Description for option givenname
    --groups=s
        Specify one or more groups in the format
           group1,group2,..

    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

    --force|f    Description for option force
    --reset-password|resetpw
        Reset the users password to a hash value of the username.

";
}

sub gcli_rmusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove user --help --force|f 

DESCRIPTION:
    The specified users are not really deleted from the
    applicable user directory, but rather removed from all
    groups. This will remove application access from the users,
    and free up the tool licenses. 

    The options are as follows:
    --help
        Print this help, and command usage information.

    --force|f    Description for option force
";
}



1;
