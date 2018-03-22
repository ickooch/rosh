package AwsCLI::Images_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Images');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsimg',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&awscli_lsimg_usage,
		    'description' => 'list image',
                    'category' => 'image',
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
		    'name' => 'descimg',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&awscli_descimg_usage,
		    'description' => 'describe image',
                    'category' => 'image',
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
		    'name' => 'addimg',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&awscli_addimg_usage,
		    'description' => 'add image',
                    'category' => 'image',
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
		    'name' => 'deleteimg',                                # external command name (used by user)
                    'verb' => [ 'delete' ],
                    'usage' => \&awscli_deleteimg_usage,
		    'description' => 'delete image',
                    'category' => 'image',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
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
sub awscli_lsimg_usage
{
#    return "** UNIMPLEMENTED **";

    return "list image --help --long|l --short|s --format|fmt=s [ name.. ]

DESCRIPTION:
    List names, and ids of all ec2 images.

    Arguments to the command are treated as search names, and only
    images whose names match are included in the output.      

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

sub awscli_descimg_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe image --help --long|l --short|s --format|fmt=s 

DESCRIPTION:
    List names, and ids of all images.

    Arguments to the command are treated as search names, and only
    images whose names match are included in the output.      

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

sub awscli_addimg_usage
{
#    return "** UNIMPLEMENTED **";

    return "add image --help --desc|d=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --desc|d=s
        Specify a short (quoted) description for a Aws resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

";
}

sub awscli_deleteimg_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete image --force|f --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

";
}



1;
