package GitLabCLI::Variables_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Variables');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsvar',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsvar_usage,
		    'description' => 'list var',
                    'category' => 'var',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'descvar',                                # external command name (used by user)
                    'verb' => [ 'describe' ],
                    'usage' => \&gcli_descvar_usage,
		    'description' => 'describe var',
                    'category' => 'var',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'addvar',                                # external command name (used by user)
                    'verb' => [ 'add', 'create' ],
                    'usage' => \&gcli_addvar_usage,
		    'description' => 'add var',
                    'category' => 'var',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        value|val=s
		                        environment|env|scope=s
		                        protected|prot
				      )
				  ],
		   },
		   {
		    'name' => 'rmvar',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete' ],
                    'usage' => \&gcli_rmvar_usage,
		    'description' => 'remove var',
                    'category' => 'var',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        help
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'editvar',                                # external command name (used by user)
                    'verb' => [ 'edit', 'setenv', 'update' ],
                    'usage' => \&gcli_editvar_usage,
		    'description' => 'edit var',
                    'category' => 'var',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        in=s
		                        value|val=s
		                        environment|env|scope=s
		                        protected|prot
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsvar_usage
{
#    return "** UNIMPLEMENTED **";

    return "list var --help --long|l --short|s --format|fmt=s --in=s [ name.. ]

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

sub gcli_descvar_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe var --help --long|l --short|s --in=s 

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

";
}

sub gcli_addvar_usage
{
#    return "** UNIMPLEMENTED **";

    return "add var --help --in=s --value|val=s --environment|env|scope=s --protected|prot 

DESCRIPTION:
    Create a new build variable.

    The options are as follows:
    --help
        Print this help, and command usage information.

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

    --value|val=s
        Specify the (quoted) value for the build variable.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        value from this file, if one is found.

    --environment|env|scope=s
        The environment_scope of the variable

    --protected|prot
        If switch is set, the variable is set to be protected.

";
}

sub gcli_rmvar_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove var --force|f --help --in=s 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

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

sub gcli_editvar_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit var --help --in=s --value|val=s --environment|env|scope=s --protected|prot 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

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

    --value|val=s
        Specify the (quoted) value for the build variable.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        value from this file, if one is found.

    --environment|env|scope=s
        The environment_scope of the variable

    --protected|prot
        If switch is set, the variable is set to be protected.

";
}



1;
