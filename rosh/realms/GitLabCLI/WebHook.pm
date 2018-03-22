package GitLabCLI::WebHook;

require AppImplementation;
use base qw( AppImplementation );

use strict;

#
# Copyright
#

use Data::Dump qw( dump );
use Getopt::Long;
use Try::Tiny;
use JSON;

use  GitLabCLI::WebHook_IF;

sub new {
  my $this = bless({}, shift);

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #
  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lshook', 'cmd_lshook' ],
     ['deschook', 'cmd_deschook' ],
     ['addhook', 'cmd_addhook' ],
     ['copyhook', 'cmd_copyhook' ],
     ['rmhook', 'cmd_rmhook' ],
     ['edithook', 'cmd_edithook' ], 
		 ]);
  
  return $this;
}

sub cmd_lshook {
    my $stat = "";

    my $this = shift;
    
    my $usage = GitLabCLI::WebHook_IF::gcli_lshook_usage();
    if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
	print 'Called: cmd_lshook ';
	print join(', ', @ARGV ); print "\n";
    }
    my ( $opt_help, $opt_long, $opt_short, $opt_in, 
	 $opt_project, $opt_project_id,  $opt_format,
	 $opt_url );
    GetOptions (
	'help' => \$opt_help,
	'long|l' => \$opt_long,
	'short|s' => \$opt_short,
	'in=s' => \$opt_in,
	'format|fmt=s' => \$opt_format,
	'url=s' => \$opt_url,
	'in=s' => \$opt_project_id,
	);

    if ( $opt_help ) {
	print $usage;
	return 0;
    }
    my $json = JSON->new->allow_nonref;

    my $gitlab = $this->preference( 'gitlab_connector' );

    # intial option checking here

    my @projects;
    my $subject_list = shift @ARGV;
    if ( $subject_list ) {
	foreach my $p ( split( ',', $subject_list ) ) {
	    my $pid;
	    try {
		$pid = $gitlab->get_project_id( $p );
	    } catch {
		$this->check( "ERR: Cannot find project $p: $_; skipping\n" );
		next;
	    };
	    push( @projects, $pid );
	}
    } else {
	@projects = map { $_->{ 'id' } } @{ $gitlab->my_projects() };
    }
    # end this routine by returning a status indicator; not null means error!
    
    if ( $opt_long ) {
	$opt_short = '';
    }
    
    
    my @results;
    foreach my $prj_id ( @projects ) {
	my ( $project_desc, $project_name );
	try {
	    $project_desc = $gitlab->get_project_from_id( $prj_id );
	    $project_name = $project_desc->{ 'path_with_namespace' };
	} catch {
	    $this->print( "[ *warn* - could not find data for project $prj_id: $_ ]\n" );
	    $project_name = '*unknown*';
	};
	my $endpoint = "/projects/$prj_id/hooks";
  								 
	push( @results, map { $_->{ 'project' } = $project_name; $_ }
	      @{ $gitlab->rest_get_list( $endpoint ) } );
    }

    $gitlab->register_webhooks( \@results );    
    if ( $opt_url ) {
	@results = grep { $_->{ 'url' } eq $opt_url } @results;
    }
    if ( $opt_long ) {
	print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n"; 
    } elsif ( $opt_format ) {
	print join( '', map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"
    } else {
	print join( "\n", map { $gitlab->compile_webhook_id( $_, $_->{ 'project' } ) } @results ) . "\n";
    }
    
    # end this routine by returning a status indicator; not null means error!
    return $stat;
}

sub cmd_deschook {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::WebHook_IF::gcli_deschook_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deschook ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_project, $opt_project_id,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing webhook argument.\n";
  }
  my $webhooks = $gitlab->get_webhooks();
  if ( not defined $webhooks ) {
      die "No Webhooks in cache - please use 'list webhooks' to initialize cache.\n";
  }
  if ( not exists $webhooks->{ $subject } ) { 
      die "Cannot find a webhook object with id \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  my $result_obj = $webhooks->{ $subject };
  
  print $json->pretty->encode( $result_obj ) . "\n";

  return $stat;
}

sub cmd_addhook {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::WebHook_IF::gcli_addhook_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addhook ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_url, $opt_events, $opt_token, $opt_to_target, $opt_recursive );
  GetOptions (
      'help' => \$opt_help,
      'recursive|r' => \$opt_recursive,
      'to=s' => \$opt_to_target,
      'url=s' => \$opt_url,
      'events=s' => \$opt_events,
      'token=s' => \$opt_token,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  if ( not $opt_to_target ) {
      die "You must specify one or more target projects to add the webhook to.
$usage\n";
  }

  if ( not $opt_events ) {
      die "Please specify the events ('--events <event1,..>') that should trigger the webhook.
$usage\n";
  }
  my @events = split( ',', $opt_events );

  if ( not $opt_url ) {
      die "Please specify the URL that should be called by the webhook.
$usage\n";
  }
  my $post_params = {};
  $post_params->{ 'url' } = $opt_url;
  if ( $opt_token ) {
      $post_params->{ 'token' } = $opt_url;
  }
  my @known_events = @{ $gitlab->webhook_events() };
  foreach my $event ( @events ) {
      if ( scalar ( grep { m/^$event/ } @known_events ) == 1 ) {
	  $post_params->{ (grep { m/^$event/ } @known_events )[0] } = 1;
      } else {
	  die "Keyword $event does not refer to any known event.\n$usage\n";
      }
  }
  # intial option checking here
  my @targets = split( ',', $opt_to_target );
  if ( $opt_recursive ) {
      # if option -r is set, we expect one or more of the specified
      # targets to be group identifiers, rather than plain
      # projects. We work as follows:
      # - examine each target in the original list
      # - if the target is a group, replace the group id by the list
      #   of all projects that are contained in the transitive closure
      #   of the group.
      # - condense the list to eliminate possible duplicates
      my @targ2;
      foreach my $this_target ( @targets ) {
	  my $gid;
	  try {
	      $gid = $gitlab->get_group_id( $this_target, 'verify' => 1,
					    'exact-match' => 1 );
	  } catch {
	      push( @targ2, $gid );
	      next;
	  };
	  my $groups = $gitlab->get_group_closure( $gid );
	  push( @targ2, map { $_->{ 'id' } } @{ $gitlab->my_projects_in_groups( $groups ) } );
      }
      my %condenser;
      foreach my $t ( @targ2 ) {
	  $condenser{ $t } = 1;
      }
      @targets = keys %condenser;
  }
  my @results;
  foreach my $this_target ( @targets ) {
      my $target_project_id;
      try {
	  $target_project_id = $gitlab->get_project_id( $this_target );
      } catch {
	  $this->check( "ERR: Cannot determine id for target project \"$this_target\", skipping.\n" );
	  next;
      };
      # end this routine by returning a status indicator; not null means error!

      $post_params->{ 'id' } = $target_project_id;
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_post( "/projects/$target_project_id/hooks", $post_params );
      } catch {
	  $this->check( "ERR: Could not create webhook " . $opt_url .
			    " for project $this_target: $_\n" );
	      next;
      };
      # we've got to fiddle with the returned data to make compile_webhook_id happy
      my $res_object = from_json( $result_obj->{ 'body' } );
      $res_object->{ 'project' } = $this_target;
      push( @results, $res_object );
  }

  print "Added Webhook $opt_url to project(s) \n" . 
      join( "\n", map { $gitlab->compile_webhook_id( $_, $_->{ 'project' } ) } @results ) . "\n";

  # end this routine by returning a status indicator; not null means error!

  return $stat;
}

sub cmd_copyhook {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::WebHook_IF::gcli_copyhook_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_copyhook ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_to_target,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      'to=s' => \$opt_to_target,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject_list = shift @ARGV;
  if ( not $subject_list ) {
      return "Error: Missing source webhook argument(s) for copy operation.\n";
  }
  my $webhooks = $gitlab->get_webhooks();
  if ( not defined $webhooks ) {
      die "No Webhooks in cache - please use 'list webhooks' to initialize cache.\n";
  }
  my @webhooks;
  foreach my $subject ( split( ',', $subject_list ) ) {
      my $webhook_obj;
      $webhook_obj = exists $webhooks->{ $subject };
      if ( not $webhook_obj ) {
	  die "ERR: No webhook with id $subject exists.\n";
      };
      push( @webhooks, $subject );
  }

  if ( not $opt_to_target ) {
      die "You must specify a target project to copy the webhook(s) to.
$usage\n";
  }
  my @targets = split( ',', $opt_to_target );
  foreach my $this_target ( @targets ) {
      my $target_project_id;
      try {
	  $target_project_id = $gitlab->get_project_id( $this_target );
      } catch {
	  $this->check( "ERR: Cannot determine id for target project \"$this_target\", skipping.\n" );
      };
      next
	  unless ( $target_project_id );
      # end this routine by returning a status indicator; not null means error!

      my @results;
      foreach my $whook ( @webhooks ) {
	  my $post_params = {};
	  my ( $result_obj, $result );
	  foreach my $key ( qw( url enable_ssl_verification token ) , @{ $gitlab->webhook_events() } ) {
	      $post_params->{ $key } = $webhooks->{ $whook }->{ $key };
	  };
	  $post_params->{ 'id' } = $target_project_id;
	  try {
	      $result_obj = $gitlab->rest_post( "/projects/$target_project_id/hooks", $post_params )->{ 'body' };
	      $result = from_json( $result_obj );
	  } catch {
	      $this->check( "ERR: Could not create webhook " . $webhooks->{ $whook }->{ 'url' } . 
			    " for project $opt_to_target: $_\n" );
	      next;
	  };
	  push( @results, $result );
      }
      if ( my $this_project = $gitlab->get_project( $target_project_id ) ) {
	  $this_project->{ 'webhooks' } = [ map { $_->{ 'id' } . ': ' . $_->{ 'url' } } @results ];
	  $gitlab->update_project( $this_project );
      }
      $gitlab->register_webhooks( \@results );
      if ( @results ) {
	  print "Copied Webhooks to project $opt_to_target: \n" . 
	      join( "\n", map{ $gitlab->substitute_format( "%i: %F:url", $_ ) } @results ) . "\n";
      } else {
	  print "No Webhooks installed.\n";
      }
  }
  
  return $stat;
}

sub cmd_rmhook {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::WebHook_IF::gcli_rmhook_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_events,  $opt_json );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      'events=s' => \$opt_events,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject_list = join( ',',  @ARGV );
  if ( not $subject_list ) {
      return "Error: Missing webhook argument(s).\n";
  }
  my $webhooks = $gitlab->get_webhooks();
  if ( not defined $webhooks ) {
      die "No Webhooks in cache - please use 'list webhooks' to initialize cache.\n";
  }
  my @webhooks;
  foreach my $subject ( split( ',', $subject_list ) ) {
      my $webhook_obj;
      $webhook_obj = exists $webhooks->{ $subject };
      if ( not $webhook_obj ) {
	  $this->check( "ERR: No webhook with id $subject exists.\n");
	  next;
      };
      push( @webhooks, $subject );
  }

  foreach my $webhook_id ( @webhooks ) {
      my $this_hook = $webhooks->{ $webhook_id };
      if ( not $opt_events ) {
	  # complete removal of hook
	  my $this_hook = $webhooks->{ $webhook_id };
	  if ( not ( $opt_force or $this->confirm( "Delete webhook $webhook_id ($this_hook->{ 'url' }) completely ?", 'no'))) {
	      $this->print( "Webhook not removed.\n" );
	      next;
	  } else {
	      my $endpoint = "/projects/$this_hook->{ 'project_id' }/hooks/$webhook_id";
	      try {
		  $gitlab->rest_delete( $endpoint );
		  $this->check("MSG: Webhook $this_hook->{ 'id' } $this_hook->{ 'url' } deleted.\n");
	      } catch {
		  $this->check("ERR: Delete webhook $webhook_id failed: $_\n");
	      };
	  }
      } else {
	  # only strip events from webhook definition
      }
  }

  # end this routine by returning a status indicator; not null means error!  
  
  return $stat;
}

sub cmd_edithook {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::WebHook_IF::gcli_edithook_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_edithook ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_project, $opt_project_id, $opt_url, $opt_events, $opt_token,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      'project|p=s' => \$opt_project,
      'in=i' => \$opt_project_id,
      'url=s' => \$opt_url,
      'events=s' => \$opt_events,
      'token=s' => \$opt_token,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing webhook argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'webhook', $subject );
  } catch {
      die "Cannot determine id for webhook object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  if ( not ( $opt_project_id or $opt_project ) ) {
      $opt_project_id ||= $this->set( 'current_gitlab_project_id' );
      return "Error: Please specify the project's name or id for which webhooks should be listed.\n"
          if ( not $opt_project_id );
  }

  my $prj_id = $opt_project_id;
  if ( not $prj_id ) {
      try {
	  $prj_id = $gitlab->get_project_id( 'project', $opt_project );
      } catch {
	  print "No such project \"$opt_project\"\n";
      };
  }
  my $endpoint_template = '/projects/:project-id/hooks/:id';

  
  
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'project' => $opt_project,
                                                                  'project_id' => $opt_project_id,
                                                                  'url' => $opt_url,
                                                                  'events' => $opt_events,
                                                                  'token' => $opt_token,
                                                                 'subject_id' => $subject_id,});
  my $params = $gitlab->build_params({ 'help' => $opt_help,
                                                                  'project' => $opt_project,
                                                                  'project_id' => $opt_project_id,
                                                                  'url' => $opt_url,
                                                                  'events' => $opt_events,
                                                                  'token' => $opt_token,
                                                                 'subject_id' => $subject_id,});								 
  
  
  
  
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  

    print $opt_json ? to_json( $result_obj ) : dump( $result_obj ) . "\n"; 
  
  print "**** UNIMPLEMENTED: " . 'command edithook in GitLabCLI::WebHook' . "\n";

  return $stat;
}


1;
