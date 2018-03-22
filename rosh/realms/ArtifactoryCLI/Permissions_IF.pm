package ArtifactoryCLI::Permissions_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Permissions');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsperm',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&atfcli_lsperm_usage,
		    'description' => 'list permission',
                    'category' => 'permission',
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
		    'name' => 'descperm',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&atfcli_descperm_usage,
		    'description' => 'describe permission',
                    'category' => 'permission',
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
		    'name' => 'mkperm',                                # external command name (used by user)
                    'verb' => [ 'create', 'add' ],
                    'usage' => \&atfcli_mkperm_usage,
		    'description' => 'create permission',
                    'category' => 'permission',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        title=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmperm',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete', 'del', 'rm' ],
                    'usage' => \&atfcli_rmperm_usage,
		    'description' => 'remove permission',
                    'category' => 'permission',
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
		    'name' => 'editperm',                                # external command name (used by user)
                    'verb' => [ 'update', 'edit', 'replace' ],
                    'usage' => \&atfcli_editperm_usage,
		    'description' => 'update permission',
                    'category' => 'permission',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'applyperm',                                # external command name (used by user)
                    'verb' => [ 'apply', 'administer', 'admin', 'unapply', 'revoke' ],
                    'usage' => \&atfcli_applyperm_usage,
		    'description' => 'apply permission',
                    'category' => 'permission',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        to=s
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
sub atfcli_lsperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "list permission --help --long|l --short|s --format|fmt=s [ name.. ]

DESCRIPTION:
    Get the permission targets list

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

sub atfcli_descperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe permission --help --long|l --short|s --format|fmt=s 

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

sub atfcli_mkperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "create permission --help --title=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --title=s
        Title of the object.

";
}

sub atfcli_rmperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove permission --force|f --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

";
}

sub atfcli_editperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "update permission --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_applyperm_usage
{
#    return "** UNIMPLEMENTED **";

    return "apply permission --help --to=s --from=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --from=s    Description for option from_original
";
}



1;
