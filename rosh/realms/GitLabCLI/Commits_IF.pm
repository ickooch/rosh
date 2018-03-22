package GitLabCLI::Commits_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Commits');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lscmit',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lscmit_usage,
		    'description' => 'list commit',
                    'category' => 'commit',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        format|fmt=s
		                        limit|max=i
		                        in=s
		                        branch|b=s
		                        ref=s
		                        since=s
		                        until=s
				      )
				  ],
		   },
		   {
		    'name' => 'desccmit',                                # external command name (used by user)
                    'verb' => [ 'describe' ],
                    'usage' => \&gcli_desccmit_usage,
		    'description' => 'describe commit',
                    'category' => 'commit',
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
		    'name' => 'diffcmit',                                # external command name (used by user)
                    'verb' => [ 'diff|compare|comp' ],
                    'usage' => \&gcli_diffcmit_usage,
		    'description' => 'diff|compare|comp commit',
                    'category' => 'commit',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        from=s
		                        to=s
		                        in=s
		                        filter=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lscmit_usage
{
#    return "** UNIMPLEMENTED **";

    return "list commit --help --long|l --short|s --format|fmt=s --limit|max=i --in=s --branch|b=s --ref=s --since=s --until=s [ name.. ]

DESCRIPTION:
    List commits in specified repositories.

    An argument to the list command is treated as a filter expression
    that will be matched against the title of all commits.

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

    --limit|max=i
        For list output, limit the number of rows that are reported.

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

    --branch|b=s    Description for option branch
    --ref=s    Description for option ref
    --since=s
        Only commits after or on this date will be listed in ISO 8601 format
        YYYY-MM-DDTHH:MM:SSZ

    --until=s
        Only commits before or on this date will be listed in ISO 8601 format
        YYYY-MM-DDTHH:MM:SSZ

";
}

sub gcli_desccmit_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe commit --help --long|l --short|s --format|fmt=s --in=s 

DESCRIPTION:
Output details of the current project's commit which is given as argument.

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

sub gcli_diffcmit_usage
{
    return "diff|compare|comp commit --help --long|l --short|s --from=s --to=s --in=s --filter=s 

DESCRIPTION:
Print an overview of the differences between the two commits --from and --to.

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
    --from <from-ref-sha> Commit-id (or ref) of the base version for the compare.
        This parameter is mandatory.

    --to <to-ref-sha>     Commit-id of the target version against which the from
        version is going to be compared. This parameter is mandatory.

    --in <project>
        Specify the project / repository to which the operation applies.

        In any case, the argument to the --in switch can be a proper
        object id (numeric, or url encoded pathname), or a unique
        object name.

        If the argument to --in references a project, this project
        is cached in the internal variable 'current_project'. If
        'current_project' is defined it is implicitly assumed as
        argument to --in, i.e. it is not necessary to specify the
        project context more than once in multiple subsequent commands
        that apply to the same project.

    --filter=s
        Restrict diff output to kind of changes specified as filter argument:
            - A - select files added
            - D - select files deleted
            - M - select files modified
            - R - select file renames
        Any combination of filter keys is possible.
        If no filter is specified, all differences will be listed.

";
}



1;
