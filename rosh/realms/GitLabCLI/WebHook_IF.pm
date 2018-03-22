package GitLabCLI::WebHook_IF;

require AppInterface;
use base qw( AppInterface );

use strict;

sub new {
  my $this = bless({}, shift);

  $this->frame(shift);
  $this->name('WebHook');
  $this->version('1.0.0');
  $this->commands([{
		    'name' => 'lshook',                                # external command name (used by user)
                    'verb' => [ 'list' ],
                    'usage' => \&gcli_lshook_usage,
		    'description' => 'list webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
		                        url=s
		                        format|fmt=s
				      )
				  ],
		   },
		   {
		    'name' => 'deschook',                                # external command name (used by user)
                    'verb' => [ 'describe' ],
                    'usage' => \&gcli_deschook_usage,
		    'description' => 'describe webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        long|l
		                        short|s
				      )
				  ],
		   },
		   {
		    'name' => 'addhook',                                # external command name (used by user)
                    'verb' => [ 'add' ],
                    'usage' => \&gcli_addhook_usage,
		    'description' => 'add webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        url=s
		                        to=s
		                        recursive|r
		                        events=s
		                        token=s
				      )
				  ],
		   },
		   {
		    'name' => 'copyhook',                                # external command name (used by user)
                    'verb' => [ 'copy' ],
                    'usage' => \&gcli_copyhook_usage,
		    'description' => 'copy webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        to=s
				      )
				  ],
		   },
		   {
		    'name' => 'rmhook',                                # external command name (used by user)
                    'verb' => [ 'remove', 'delete' ],
                    'usage' => \&gcli_rmhook_usage,
		    'description' => 'remove webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        force|f
		                        help
		                        events=s
				      )
				  ],
		   },
		   {
		    'name' => 'edithook',                                # external command name (used by user)
                    'verb' => [ 'edit' ],
                    'usage' => \&gcli_edithook_usage,
		    'description' => 'edit webhook',
                    'category' => 'webhook',
                    'version' => '',                                 # set when implementation is loaded
		    'kind' => 'cli',
		    'entry' => undef,                                # set when implementation is loaded
		    'options' =>  [ qw(
		                        help
		                        project|p=s
		                        in=i
		                        url=s
		                        events=s
		                        token=s
				      )
				  ],
		   },
		   		   
		  ]);

  return $this;
}

#-------------------------------------------------------------------------------
# print short usage notes
#-------------------------------------------------------------------------------
sub gcli_lshook_usage
{
#    return "** UNIMPLEMENTED **";

    return "list webhook --help --long|l --short|s --url=s --format|fmt=s 

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
    --url=s
        Specify the URL of the resource or endpoint referenced
        in the command.

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

sub gcli_deschook_usage
{
#    return "** UNIMPLEMENTED **";

    return "describe webhook --help --long|l --short|s 

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
";
}

sub gcli_addhook_usage
{
#    return "** UNIMPLEMENTED **";

    return "add webhook --help --url=s --to=s --recursive|r --events=s --token=s 

DESCRIPTION:
    Create a project hook (also referred to as webhook) for the
    project or projects referenced by the context specified by
    the --to option. The referenced context is usually a
    projecst or a list of projects. It is also possible to specify a
    group or subgroup, in which case the webhook is created for
    all projects in the respective group (see also option
    --recursive). 
    
    The option /--url '<url string>'/ defines URL endpoint of a
    webseservice that is called whenever one of the events
    specified with the  option --events occurs.
    
    The switch '--token <string>' is used to define a secret
    token to validate received payloads.
    
    If the option /--recursive/ is set the argument to the --to
    option is taken as a group (possibly containing subgroups)
    in which projects are organized. In this case the webhook is
    added to all projects that are contained in the transitive
    closure of the group given in the --to option.

    The options are as follows:
    --help
        Print this help, and command usage information.

    --url=s
        Specify the URL of the resource or endpoint referenced
        in the command.

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

    --recursive|r
        If the option /--recursive/ is set, the operation applies to
        all entities that are referenced by the transitive closure
        of a group context (possibly defined with --to).

    --events=s
        The --events option determines, which GitLab events trigger
        the webhook. The argument to the --event option is a
        comma-separated sequence of one or more GitLab events.
        The following event keywords are known:
            push
            tag_push
            note
            issues
            merge_requests
            job
            pipeline
            wiki_page

    --token=s
        The switch '--token <string>' is used to define a secret
        token to validate received payloads.

";
}

sub gcli_copyhook_usage
{
#    return "** UNIMPLEMENTED **";

    return "copy webhook --help --to=s 

DESCRIPTION:
  Copy the webhooks specified as command arguments to the
  project (or projects) specified as argument to the --to
  option.

  This command requires an initialized cache of webhook
  entries (see command 'list webhooks'). 

    The options are as follows:
    --help
        Print this help, and command usage information.

    --to=s
        Specify the target context or object to which an
        operation applies. The string argument can be a simple
        id, or name, or a comma-separated sequence of ids.

        For example, copy an existing webhook to an existing project
        with 'copy webhook 842 --to my_project.

";
}

sub gcli_rmhook_usage
{
#    return "** UNIMPLEMENTED **";

    return "remove webhook --force|f --help --events=s 

DESCRIPTION:

    The options are as follows:
    --force|f    Description for option force
    --help
        Print this help, and command usage information.

    --events=s
        The --events option determines, which GitLab events trigger
        the webhook. The argument to the --event option is a
        comma-separated sequence of one or more GitLab events.
        The following event keywords are known:
            push
            tag_push
            note
            issues
            merge_requests
            job
            pipeline
            wiki_page

";
}

sub gcli_edithook_usage
{
#    return "** UNIMPLEMENTED **";

    return "edit webhook --help --project|p=s --in=i --url=s --events=s --token=s 

DESCRIPTION:

    The options are as follows:
    --help
        Print this help, and command usage information.

    --project|p=s    Description for option project
    --in=i    Description for option project_id
    --url=s
        Specify the URL of the resource or endpoint referenced
        in the command.

    --events=s
        The --events option determines, which GitLab events trigger
        the webhook. The argument to the --event option is a
        comma-separated sequence of one or more GitLab events.
        The following event keywords are known:
            push
            tag_push
            note
            issues
            merge_requests
            job
            pipeline
            wiki_page

    --token=s
        The switch '--token <string>' is used to define a secret
        token to validate received payloads.

";
}



1;
