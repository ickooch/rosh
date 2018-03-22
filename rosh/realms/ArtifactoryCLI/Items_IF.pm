package ArtifactoryCLI::Items_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Items');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsitm',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&atfcli_lsitm_usage,
		    'description' => 'list item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        recursive|rec|R
		                        t
		                        r
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'descitm',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&atfcli_descitm_usage,
		    'description' => 'describe item',
                    'category' => 'item',
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
		    'name' => 'mkitm',                                # external command name (used by user)
                    'verb' => [ 'new', 'create', 'add', 'upload', 'deploy' ],
                    'usage' => \&atfcli_mkitm_usage,
		    'description' => 'new item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        file|f
		                        to=s
		                        force|f
				      )
				  ],
		   },
		   {
		    'name' => 'mkdiritm',                                # external command name (used by user)
                    'verb' => [ 'mkdir', 'mkfolder', 'addfolder' ],
                    'usage' => \&atfcli_mkdiritm_usage,
		    'description' => 'mkdir item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        force|f
				      )
				  ],
		   },
		   {
		    'name' => 'cpitm',                                # external command name (used by user)
                    'verb' => [ 'copy', 'cp' ],
                    'usage' => \&atfcli_cpitm_usage,
		    'description' => 'copy item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'mvitm',                                # external command name (used by user)
                    'verb' => [ 'move', 'mv', 'rename', 'ren' ],
                    'usage' => \&atfcli_mvitm_usage,
		    'description' => 'move item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'rmitm',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete', 'del', 'rm' ],
                    'usage' => \&atfcli_rmitm_usage,
		    'description' => 'remove item',
                    'category' => 'item',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        help
		                        with-content
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub atfcli_lsitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "list item --help --long|l --short|s --recursive|rec|R --t --r --format|fmt=s [ name.. ]

DESCRIPTION:
    List names, and basic information about items stored in a repository
    or a folder in that repository.

    Arguments to the command are treated as search names, and only
    items whose names match are included in the output.      

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
    --recursive|rec|R
        If the option /--recursive/ is set, the operation applies to
        all entities that are referenced by the transitive closure
        of a group context (possibly defined with --to).

    --t    Description for option time_ordered
    --r
        Reverse the meaning of the current ordering of file entries.

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

sub atfcli_descitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe item --help --long|l --short|s --format|fmt=s 

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

sub atfcli_mkitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "new item --help --file|f --to=s --force|f 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --file|f    Description for option file
    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --force|f    Description for option force
";
}

sub atfcli_mkdiritm_usage
{
#    return "** UNIMPLEMENTED **";

    return "mkdir item --help --force|f 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --force|f    Description for option force
";
}

sub atfcli_cpitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "copy item --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_mvitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "move item --help 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

";
}

sub atfcli_rmitm_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove item --force|f --help --with-content 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

    --with-content
        By default, items aren't deleted if they have content.
        Use this switch to remove a repository even if it is not empty. 

";
}



1;
