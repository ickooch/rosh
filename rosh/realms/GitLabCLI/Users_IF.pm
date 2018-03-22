package GitLabCLI::Users_IF;

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
		                        long|l
		                        format|fmt=s
		                        short|s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'descusr',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
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
		    'name' => 'addusr',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&gcli_addusr_usage,
		    'description' => 'add user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        to=s
		                        as=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmusr',                                # external command name (used by user)
                    'verb' => [ 'remove', 'rm', 'del', 'delete' ],
                    'usage' => \&gcli_rmusr_usage,
		    'description' => 'remove user',
                    'category' => 'user',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        from=s
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

    return "list user --help --long|l --format|fmt=s --short|s --in=s [ name.. ]

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

sub gcli_addusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "add user --help --long|l --to=s --as=s 

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

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

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

sub gcli_rmusr_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove user --help --long|l --from=s 

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

    --from=s    Description for option from_original
";
}



1;
