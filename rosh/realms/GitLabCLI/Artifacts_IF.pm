package GitLabCLI::Artifacts_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Artifacts');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsatf',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lsatf_usage,
		    'description' => 'list artifact',
                    'category' => 'artifact',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        job=s
		                        ref=s
		                        long|l
		                        in=s
				      )
				  ],
		   },
		   {
		    'name' => 'getatf',                                # external command name (used by user)
                    'verb' => [ 'get' ],
                    'usage' => \&gcli_getatf_usage,
		    'description' => 'get artifact',
                    'category' => 'artifact',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        job=s
		                        long|l
		                        in=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lsatf_usage
{
#    return "** UNIMPLEMENTED **";

    return "list artifact --help --job=s --ref=s --long|l --in=s [ name.. ]

DESCRIPTION:
    List artifacts generated for the indicated job.

    An argument to the list command is treated as a filter expression
    that will be matched against the set of all job artifacts.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --job=s    Description for option job
    --ref=s    Description for option ref
    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

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

sub gcli_getatf_usage
{
#    return "** UNIMPLEMENTED **";

    return "get artifact --help --job=s --long|l --in=s [ name.. ]

DESCRIPTION:
    Get the artifacts (zip-)file for the given job. If a name is
    provided that matches one or more artifact, only the
    matching artifacts are retrieved and placed in the current
    directory. 

    The options are as follows:
    --help
        Print this help, and command usage information.

    --job=s    Description for option job
    --long|l
        Print detailed information, such as description. and other
        attributes for the respective resource.
        If this switch is used together with the --json switch, then
        all raw data as returned by the API call is printed as JSON
        document. 

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



1;
