package ArtifactoryCLI::Repositories_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('Repositories');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lsrep',                                # external command name (used by user)
                    'verb' => [ 'list', 'ls' ],
                    'usage' => \&atfcli_lsrep_usage,
		    'description' => 'list repository',
                    'category' => 'repository',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        all|a
		                        my
		                        recursive|rec|R
		                        class=s
		                        t
		                        r
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'descrep',                                # external command name (used by user)
                    'verb' => [ 'describe', 'desc' ],
                    'usage' => \&atfcli_descrep_usage,
		    'description' => 'describe repository',
                    'category' => 'repository',
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
		    'name' => 'mkrep',                                # external command name (used by user)
                    'verb' => [ 'create', 'add' ],
                    'usage' => \&atfcli_mkrep_usage,
		    'description' => 'create repository',
                    'category' => 'repository',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        title=s
		                        desc|d=s
		                        type=s
		                        class=s
		                        proto=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmrep',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete', 'del', 'rm' ],
                    'usage' => \&atfcli_rmrep_usage,
		    'description' => 'remove repository',
                    'category' => 'repository',
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
		   {
		    'name' => 'editrep',                                # external command name (used by user)
                    'verb' => [ 'update', 'edit' ],
                    'usage' => \&atfcli_editrep_usage,
		    'description' => 'update repository',
                    'category' => 'repository',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        desc|d=s
		                        visibility=s
		                        branch|b=s
		                        enable=s
		                        disable=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub atfcli_lsrep_usage
{
#    return "** UNIMPLEMENTED **";

    return "list repository --help --long|l --short|s --all|a --my --recursive|rec|R --class=s --t --r --format|fmt=s [ name.. ]

DESCRIPTION:
    List names, and ids of all repositories listed in a group or
    subgroup (namespace) owned by or visible to the caller.

    Arguments to the command are treated as search names, and only
    repositories whose names match are included in the output.      

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
    --all|a
        Do not restrict output by any kind of built-in filter
        logic, such as only listing projects that are listed
        in one of the caller's namespaces.

        Note, that requesting all possible entries may result
        in extended response times because of Artifactory's
        paginating API returns (i.e. there may be many
        sequential GET requests involved). 

    --my
        List only repositories that are supposedly mine, i.e. to which the
        calling user has at least slightly extended permissions.

    --recursive|rec|R
        If the option /--recursive/ is set, the operation applies to
        all entities that are referenced by the transitive closure
        of a group context (possibly defined with --to).

    --class=s
        Category of the repository.
        Supported classes are:
        - local (default)
        - remote
        - virtual

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

sub atfcli_descrep_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe repository --help --long|l --short|s --format|fmt=s 

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

sub atfcli_mkrep_usage
{
#    return "** UNIMPLEMENTED **";

    return "create repository --help --title=s --desc|d=s --type=s --class=s --proto=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --title=s
        Title of the object.

    --desc|d=s
        Specify a short (quoted) description for a Artifactory resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --type=s
        Repository layout type.
        Supported types are:
        - Generic (default)
        - Bower
        - CocoaPods
        - Debian
        - Docker
        - Gems
        - GitLFS
        - Gradle
        - Ivy
        - Maven
        - npm
        - NuGet
        - Opkg
        - PyPI
        - SBT
        - Vagrant
        - YUM

    --class=s
        Category of the repository.
        Supported classes are:
        - local (default)
        - remote
        - virtual

    --proto=s
        Specify an existing prototype in the creation of a new
        object. If a protoype object is specified, all
        relevant attributes of the object are used to set an
        initial value for the respective attribute in the
        newly created object.

";
}

sub atfcli_rmrep_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove repository --force|f --help --with-content 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

    --with-content
        By default, repositories aren't deleted if they have content.
        Use this switch to remove a repository even if it is not empty. 

";
}

sub atfcli_editrep_usage
{
#    return "** UNIMPLEMENTED **";

    return "update repository --help --desc|d=s --visibility=s --branch|b=s --enable=s --disable=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --desc|d=s
        Specify a short (quoted) description for a Artifactory resource object.

        If the argument has the form /@<filename>/, then the program
        attempts to find a file with the specified name, and reads the
        description from this file, if one is found.

    --visibility=s    Description for option visibility
    --branch|b=s    Description for option branch
    --enable=s
        Enable the command specific options or features
        identified in the comma-separated list of option
        keywords. Each of the options is taken to be a boolean
        that is set to 'true' if the keyword is listed.

        The following keywords are recognized:
            issues
            container_registry
            containers
            jobs
            lfs
            merge_requests / mr
            merge_requires_green_build
            merge_requires_resolved_discussion
            request_access / request
            runners
            shared_runners
            snippets
            wiki

    --disable=s
        Disable the resource specific options or features
        identified in the comma-separated list of option
        keywords. Each of the options is taken to be a boolean
        that is set to 'false' if the keyword is listed.

        The following keywords are recognized:
            issues
            container_registry
            containers
            jobs
            lfs
            merge_requests / mr
            merge_requires_green_build
            merge_requires_resolved_discussion
            request_access / request
            runners
            shared_runners
            snippets
            wiki

";
}



1;
