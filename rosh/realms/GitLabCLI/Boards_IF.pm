package GitLabCLI::Boards_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Boards');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsbrd',                                # external command name (used by user)
                    'verb' => [ 'ls', 'list', 'show' ],
                    'usage' => \&gcli_lsbrd_usage,
		    'description' => 'ls board',
                    'category' => 'board',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        in=s
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'descbrd',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&gcli_descbrd_usage,
		    'description' => 'describe board',
                    'category' => 'board',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        in=s
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'addbrd',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&gcli_addbrd_usage,
		    'description' => 'add board',
                    'category' => 'board',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        name|n=s
		                        in=s
		                        desc|d=s
				      )
				  ],
		   },
		   {
		    'name' => 'deletebrd',                                # external command name (used by user)
                    'verb' => [ 'delete' ],
                    'usage' => \&gcli_deletebrd_usage,
		    'description' => 'delete board',
                    'category' => 'board',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        in=s
		                        help
				      )
				  ],
		   },
		   {
		    'name' => 'editbrd',                                # external command name (used by user)
                    'verb' => [ 'edit' ],
                    'usage' => \&gcli_editbrd_usage,
		    'description' => 'edit board',
                    'category' => 'board',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        name|n=s
		                        in=s
		                        desc|d=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsbrd_usage
{
#    return "** UNIMPLEMENTED **";

    return "ls board --help --long|l --short|s --in=s --format|fmt=s [ name.. ]

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

sub gcli_descbrd_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe board --help --long|l --short|s --in=s --format|fmt=s 

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

sub gcli_addbrd_usage
{
#    return "** UNIMPLEMENTED **";

    return "add board --help --name|n=s --in=s --desc|d=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --name|n=s    Description for option name
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
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

";
}

sub gcli_deletebrd_usage
{
#    return "** UNIMPLEMENTED **";

    return "delete board --force|f --in=s --help 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
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

    --help
        Print this help, and command usage information.

";
}

sub gcli_editbrd_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit board --help --name|n=s --in=s --desc|d=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --name|n=s    Description for option name
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
        Specify a short (quoted) description for a GitLab resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

";
}



1;
