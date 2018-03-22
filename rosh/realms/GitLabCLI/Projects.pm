package GitLabCLI::Projects;

require AppImplementation;
use base qw( AppImplementation );

use strict;

#
# Copyright
#

use Data::Dump qw( dump );
use Data::Dumper;
use Getopt::Long;
use Try::Tiny;
use JSON;

use  GitLabCLI::Projects_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsprj', 'cmd_lsprj' ],
     ['lsprj_members', 'cmd_lsprj_members' ],
     ['addprj_members', 'cmd_addprj_members' ],
     ['rmprj_members', 'cmd_rmprj_members' ],
     ['descprj', 'cmd_descprj' ],
     ['mkprj', 'cmd_mkprj' ],
     ['moveprj', 'cmd_moveprj' ],
     ['rmprj', 'cmd_rmprj' ],
     ['editprj', 'cmd_editprj' ], 
		 ]);
  
  return $this;
}

sub cmd_lsprj {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_lsprj_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_in, $opt_all, $opt_recursive, $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      'all|a' => \$opt_all,
      'recursive|r' => \$opt_recursive,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  if ( $opt_in and $opt_all ) {
      die "Incompatible command line switches --all and --in.\n\n$usage";
  }
  if ( $opt_recursive and not $opt_in ) {
      die "Setting the recursive switch requires a group context specified with --in.\n\n$usage";
  }
  my $json = JSON->new->allow_nonref;
  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  my $in_groups;
  if ( $opt_in ) {
      try {
	  $in_groups = $opt_recursive ? 
	      $gitlab->get_group_closure( $opt_in ) :
	       [ $gitlab->get_group_id( $opt_in, 'exact-match' => 1, 'verify' => 1 ) ];
      } catch {
	  die "Cannot establish restricting context: $_\n";
      };
  }

  my @results;
  if ( $opt_all ) {
      @results = @{ $gitlab->all_projects() };
  } elsif ( $in_groups ) {
      @results = @{ $gitlab->my_projects_in_groups( $in_groups ) };
  } else {
      @results = @{ $gitlab->my_projects() };
  }
  $this->preference( 'debug' ) && print "*** Got projects: " . dump( @results ) . "\n";
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  print scalar( @results ) . " projects" . 
      ( $opt_in ? " in (sub-)group $opt_in" : '' ) . ".\n";
  if ( $opt_format ) {
      my $require_webhooks = grep { $_ =~ m/webhooks/i } 
      $gitlab->format_required_fields( $opt_format );
      if ( $require_webhooks ) {
	  foreach my $this_project ( @results ) {
	      next
		  if ( exists $this_project->{ 'webhooks' } );
	      my $hooks = $gitlab->rest_get_list( '/projects/' . $this_project->{ 'id' } . '/hooks' );
	      if ( @{ $hooks } ) {
		  $this_project->{ 'webhooks' } = [ map { $_->{ 'id' } . ': ' . $_->{ 'url' } } @{ $hooks } ];
		  $gitlab->register_webhooks( $hooks );
	      } else {
		  $this_project->{ 'webhooks' } = '** no webhooks **';
	      }
	  }
      }
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n"; 
  } else {
      my $norm_format = "%n \t(%i,\t%F:path_with_namespace, %F:visibility)";
      print '[Format: "' . $norm_format . '"]' . "\n";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } sort { $a->{ 'name' } cmp $b->{ 'name' } } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}


sub cmd_lsprj_members {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_lsprj_members_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsprj_members ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  $subject ||= $this->preference( 'current_project' );
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  # verify project id
  my $project_id = $this->assert_project_id( $subject );

  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  my $endpoint = '/projects/' . $project_id . '/members';
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'username' } =~ m/${filter_re}/i } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)";
      foreach my $res ( @results ) {
          my $role = lc $gitlab->access_level( $res->{ 'access_level' } );
	  $role =~ s/\s*access//;
          print "$res->{ 'name' }, $role (ID: $res->{ 'id' })\n";
      }
  }
  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_addprj_members {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_addprj_members_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addprj_members ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_perm,  );
  GetOptions (
      'help' => \$opt_help,
      'as=s' => \$opt_perm,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  $subject ||= $this->preference( 'current_project' );
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my $project_id = $this->assert_project_id( $subject );
  
  my @users = split(',', join( ',', @ARGV ) );
  if (not @users ) {
      die "Please specify one or more users to add as members.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my @user_ids = map { $this->assert_user_id( $_ ) } @users;

  my $perm = $this->assert_access_level( $opt_perm );
  
  my $endpoint = '/projects/' . $project_id . '/members';

  my @results;								 

  my $params = {
      'id' => $project_id,
      'access_level' => $perm,
  };
  
  foreach my $user_id ( @user_ids ) {
      $params->{ 'user_id' } = $user_id;
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_post( $endpoint, $params );
      } catch {
	  print "Could not add user $user_id to project $project_id as $opt_perm: $_\n";
	  next;
      };
      push( @results, from_json( $result_obj->{ 'body' } ) );
  }
  
  print join( "\n", map { "$_->{ name } added to project $subject with " . 
			      $gitlab->access_level( $_->{ 'access_level' } ) . 
			      '.' } @results ) . "\n";
  
  return $stat;
}

sub cmd_rmprj_members {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_rmprj_members_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmprj_members ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help,  );
  Getopt::Long::Configure('default'); # cancel 'no_passthrough'
  GetOptions (
      'help' => \$opt_help,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  $subject ||= $this->preference( 'current_project' );
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my $project_id = $this->assert_project_id( $subject );
  
  my @users = split(',', join( ',', @ARGV ) );
  if (not @users ) {
      die "Please specify one or more users to add as members.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my @user_ids = map { $this->assert_user_id( $_ ) } @users;

  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint = '/projects/' . $project_id . '/members/';
  
  my @results;								 
  
  foreach my $user_id ( @user_ids ) {
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_delete( $endpoint . $user_id );
      } catch {
	  print "Could not remove user $user_id from project $project_id: $_\n";
	  next;
      };
      push( @results, $user_id );
  }
  print join( ".\n", map { $_->{ 'name' } . " removed from project $subject" } 
	      map { $gitlab->rest_get_single( '/users/' . $_ ) } @results ) . ".\n";
  
  return $stat;
}

sub cmd_descprj {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_descprj_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_json,  $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  $subject ||= $this->preference( 'current_project' );
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my $project_id = $this->assert_project_id( $subject );

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint = '/projects/:project-id';  
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_get_single( $endpoint );
  } catch {
      die "Cannot find project $subject: $_.\n";
  };

  my $project_hooks;
  try { 
      $project_hooks = $gitlab->rest_get_list( '/projects/' . $project_id . '/hooks' );
  } catch {
      ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) && 
	  warn "No webhooks found: $!\n";
  };

  my $project_runners;
  try { 
      $project_runners = $gitlab->rest_get_list( '/projects/' . $project_id . '/runners' );
  } catch {
      ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) && 
	  warn "No runners found: $!\n";
  };

  if ( $opt_format ) {
      print $gitlab->substitute_format( $opt_format, $result_obj ) . "\n"; 
  } elsif ( $opt_long ) {
      print $json->pretty->encode( $result_obj ) . "\n";
  } else {
      print "Project: $subject ($result_obj->{ 'name' }, $result_obj->{ 'id' })\n";
      if ( $result_obj->{ 'description' } ) {
	  print $result_obj->{ 'description' } . "\n";
      }
      print $gitlab->substitute_format( "  Visibility: %F:visibility\n  Default Branch: %F:default_branch\n",
					$result_obj );
      print $gitlab->substitute_format( "  Created at: %F:created_at\n  Last activity: %F:last_activity_at\n",
					$result_obj );
      print $gitlab->substitute_format( "  Owner: %F:owner.name\n",
					$result_obj ) . "\n";;
      my @enabled_features;
      while ( my ($k, $v ) = each  %{ $result_obj } ) {
	  if ( ( $k =~ m/_enabled/ ) && $v ) {
	      my $k1 = $k;
	      $k1 =~ s/_enabled//;
	      push( @enabled_features, $k1 );
	  }
      }
      my @other_options = qw( public_jobs
                              only_allow_merge_if_pipeline_succeeds 
                              only_allow_merge_if_all_discussions_are_resolved 
                          );
      foreach my $ftr ( @other_options ) {
	  if ( $result_obj->{ $ftr } ) {
	      push( @enabled_features, $ftr );
	  }
      }
      print "Features and other options enabled in this project:\n  " .
	  join( "\n  ", sort @enabled_features ) . "\n\n";
  }

  if ( ref $project_hooks ) {
      print "Webhooks:\n  " . join( "\n  ", map { $gitlab->compile_webhook_id( $_, $subject ) } @{ $project_hooks } ) . "\n\n";
  }
  if ( ref $project_runners ) {
      print "Runners:\n  " . join( "\n  ", map { $gitlab->substitute_format( '%i: %D', $_ ) } @{ $project_runners } ) . "\n";
  }
  return $stat;
}

sub cmd_mkprj {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_mkprj_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_desc, $opt_visibility, $opt_branch, 
       $opt_enable_features, $opt_url,  $opt_json,
       $opt_prototype, $opt_recursive
      );
  GetOptions (
      'help' => \$opt_help,
      'recursive|r' => \$opt_recursive,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'branch|b=s' => \$opt_branch,
      'enable=s' => \$opt_enable_features,
      'url=s' => \$opt_url,
      'proto=s' => \$opt_prototype,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initialize create parameters
  my $post_params = {};
  
  my $proto_project;
  my $proto_webhooks;
  if ( $opt_prototype ) {
      my $proto_id;
      try {
	  $proto_id = $gitlab->get_project_id( $opt_prototype );
	  $proto_project = $gitlab->get_project_from_id( $proto_id );
      } catch {
	  die "Cannot find prototype project \"$opt_prototype\".\n";
      };
      my @clonable_fields = qw(
          default_branch
          issues_enabled
	  merge_requests_enabled
	  jobs_enabled
	  wiki_enabled
	  snippets_enabled
	  container_registry_enabled
	  shared_runners_enabled
	  visibility
	  public_jobs
	  only_allow_merge_if_pipeline_succeeds
	  only_allow_merge_if_all_discussions_are_resolved
	  lfs_enabled
	  request_access_enabled
	  tag_list
	  approvals_before_merge
      );
      foreach my $fld ( @clonable_fields ) {
	  $post_params->{ $fld } = $proto_project->{ $fld };
	  $post_params->{ 'namespace_id' } = $proto_project->{ 'namespace' }->{ 'id' }
      }
      try { 
	  $proto_webhooks = $gitlab->rest_get_list( '/projects/' . $proto_id . '/hooks' );
      } catch {
	  ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) && 
	      warn "No webhooks found to clone: $!\n";
      };
  }

  if ( $opt_visibility ) {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid project visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }
  if ( $opt_branch ) {
      $opt_branch =~ m/^[A-z][A-z0-9_-]{3,}/
	  or die "Invalid name for defautl branch specified.
Please start with a letter and use at least 4 alphanum characters, '-' or '_'\n";
  }
  my $ftr_map =  {
      'issues' => 'issues_enabled',
      'merge_requests' => 'merge_requests_enabled',
      'mr' => 'merge_requests_enabled',
      'jobs' => 'jobs_enabled',
      'wiki' => 'wiki_enabled',
      'container_registry' => 'container_registry_enabled',
      'containers' => 'container_registry_enabled',
      'shared_runners' => 'shared_runners_enabled',
      'snippets' => 'snippets_enabled',
      'runners' => 'shared_runners_enabled',
      'lfs' => 'lfs_enabled',
      'request_access' => 'request_access_enabled',
      'request' => 'request_access_enabled',
      'merge_requires_green_build' => 'only_allow_merge_if_pipeline_succeeds',
      'merge_requires_resolved_discussion' => 'only_allow_merge_if_all_discussions_are_resolved'
  };
  my @project_features;
  if ( $opt_enable_features ) {
      my @features = split(',', $opt_enable_features );
      
      foreach my $ftr ( @features ) {
	  my $feature;
	  if ( not exists $ftr_map->{ lc $ftr } ) {
	      die "Invalid project feature $ftr specified.\n$usage\n";
	  } else {
	      push( @project_features, $ftr_map->{ lc $ftr } );
	  }
      }
  }

  my $subject_list = join( ',', @ARGV );
  my $group_id;
  if ( $opt_in ) {
      try {
	  $group_id = $gitlab->get_group_id( $opt_in, 'exact-match' => 1, 'verify' => 1 );
      } catch {
	  die "Invalid group $opt_in specified in which new project(s) $subject_list should be created.\n";
      };
      $post_params->{ 'namespace_id' } = $group_id;
  }
  if ( $opt_desc ) {
      $post_params->{ 'description' } = $opt_desc;
  }
  # set defaults for project features
  if ( not $opt_prototype ) {
      foreach my $ftr ( values %{ $ftr_map } ) {
	  $post_params->{ $ftr } = 0;
      }
  }
  if ( @project_features ) {
      foreach my $ftr ( @project_features ) {
	  $post_params->{ $ftr } = 1;
      }
  }

  if ( not $subject_list ) {
      return "Error: Missing project argument for create.\n$usage\n";
  }
  foreach my $subject ( split( ',', $subject_list ) ) {
      my $subject_id;
      try {
	  $subject_id = $gitlab->get_object_id( 'project', $subject );
	  $this->check( "ERR: Project with name $subject already exists.\n");
	  next;
      };

      # end this routine by returning a status indicator; not null means error!

      print "Creating new project '$subject'" . ( $opt_prototype ? " from prototype $opt_prototype" : '' ) . 
	  ($opt_in ? " in group $opt_in" : '' ) . ".\n";
      my $endpoint_template = '/projects';
      my $endpoint = $endpoint_template;
      
      if ( is_path( $subject )) {
	  $post_params->{ 'path' } = $subject;
      } else {
	  $post_params->{ 'name' } = $subject;
      }

      my $json_headers = to_json( $post_params );  
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_post( $endpoint, $post_params );
      } catch {
	  $this->check( "ERR: Create new project failed for $subject: $_\n");
	  next;
      };
      my $project_data = from_json( $result_obj->{ 'body' } );
      $gitlab->register_project( $project_data );
      my $new_project_id = $project_data->{ 'id' };
      if ( ref $proto_webhooks ) {
	  foreach my $whook ( @{ $proto_webhooks } ) {
	      my $wh_post_params = {};
	      my $result_obj;
	      foreach my $key ( qw( url enable_ssl_verification token ) , @{ $gitlab->webhook_events() } ) {
		  $wh_post_params->{ $key } = $whook->{ $key };
	      };
	      $wh_post_params->{ 'id' } = $new_project_id;
	      try {
		  $result_obj = $gitlab->rest_post( "/projects/$new_project_id/hooks", $wh_post_params );
	      } catch {
		  $this->check( "ERR: Could not create webhook " . $whook->{ 'url' } . 
				" for new project $project_data->{ 'name' }: $_\n" );
		  next;
	      };
	  }
      }
      
      $this->check( "MSG: Created project $project_data->{ 'id' }:\n" . $json->pretty->encode( $project_data ) . "\n");
  }  

  return $stat;
}

sub is_path {
    my $string = shift;

    return scalar( split('/', $string ) ) > 1;
}

sub cmd_moveprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Projects_IF::gcli_moveprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_moveprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_from_original, $opt_to_target,  );
  GetOptions (
      'help' => \$opt_help,
      'from=s' => \$opt_from_original,
      'to=s' => \$opt_to_target,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  if ( @ARGV ) {
      if ( not $opt_from_original ) {
	  $opt_from_original = shift @ARGV;
      }
  }
  if ( @ARGV ) {
      if ( not $opt_to_target ) {
	  $opt_to_target = shift @ARGV;
      }
  }
  if ( not $opt_from_original ) {
      die "Error: No project was specified that were to be moved. Use option --from <project>.\n";
  }
  if ( not $opt_to_target ) {
      die "Error: No target was specified to where the project were to be moved.
Use option --to <name or group>.\n";
  }
  
  my $project_id = $this->assert_project_id( $opt_from_original );
  # find out whether target exists, and is a group
  my $target_id;
  try { 
      $target_id = $gitlab->assert_project_id( $opt_to_target );
      if ( defined $target_id ) {
	  die "Error: Project $opt_to_target already exists.\n"
      }
  };
  try {
      $target_id = $this->assert_group_id( $opt_to_target );
  };

  # if $target_id is defined, we have case 2: project is transferred
  # to some other group/subgroup.
  #
  my ( @results, $result_obj );				 
  my ( $endpoint, $params );
  if ( defined $target_id ) {
      #
      # Case 2
      #
      # transfer to other group endpoint: POST
      # /groups/:id/projects/:project_id
      $endpoint = '/groups/:id/projects/:project_id';
      $endpoint =~ s/\/projects\/:project_id/\/projects\/$project_id/;
      $endpoint =~ s/\/groups\/:id/\/groups\/$target_id/;
      $params = { 
		     'project_id' => $project_id,
		     'id' => $target_id 
      };      
      try {
	  $result_obj = $gitlab->rest_post( $endpoint, $params );
	  $result_obj = from_json( $result_obj->{ 'body' } );
      } catch {
	  chomp $_;
	  die ucfirst "Transfer project failed: $_.\n";      
      };
      $gitlab->register_project( $result_obj );
      print ucfirst "Transferre" . "d project $opt_from_original to " . $result_obj->{ 'name_with_namespace' } . "\n";
  } else {
      $endpoint = '/projects/:id';
      $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
      $params = { 
	  'id' => $project_id,
	  'name' => $opt_to_target,
	  'path' => $opt_to_target,
      };
      try {
	  $result_obj = $gitlab->rest_put( $endpoint, $params );
	  $result_obj = from_json( $result_obj->{ 'body' } );
      } catch {
	  chomp $_;
	  die ucfirst "Rename project failed: $_.\n";      
      };
      $gitlab->register_project( $result_obj );
      $this->assert_project_id( $result_obj->{ 'name' } );
      print ucfirst "Renamed project $opt_from_original to " . $result_obj->{ 'name' } . "\n";
  }
  push( @results, $result_obj );

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


sub cmd_rmprj {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Projects_IF::gcli_rmprj_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help,  $opt_json );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my ( $subject_id, $project );
  try {
      $subject_id = $gitlab->get_project_id( $subject );
      $project = $gitlab->get_project_from_id( $subject_id );
  } catch {
      die "Cannot find project object \"$subject\".\n";
  };


  if ( not ( $opt_force or $this->confirm( "Really delete project $project->{ 'name_with_namespace' }? 
(This action is final and cannot be undone!)", 'no' ))) {
      $this->print( "Project $project->{ 'name_with_namespace' } not removed.\n" );
      return $stat;
  }

  # end this routine by returning a status indicator; not null means error!  
  my $endpoint_template = '/projects/:project-id';
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'force' => $opt_force,
                                                                  'help' => $opt_help,
                                                                 'subject_id' => $subject_id,});
  								 
  try {
    $gitlab->rest_delete( $endpoint );
    $gitlab->unregister_project( $project );
    $this->check("MSG: Project $project->{ 'name_with_namespace' } deleted: $_\n");
  } catch {
    $this->check("ERR: Delete project $project->{ 'name_with_namespace' } failed: $_\n");
  };
  
  return $stat;
}

sub cmd_editprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Projects_IF::gcli_editprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_desc, $opt_visibility, $opt_in, $opt_name, $opt_path, 
       $opt_branch, $opt_enable_features, $opt_disable_features, $opt_prototype );
  GetOptions (
      'help' => \$opt_help,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'in=s' => \$opt_in,
      'name|n=s' => \$opt_name,
      'path=s' => \$opt_path,
      'branch|b=s' => \$opt_branch,
      'enable=s' => \$opt_enable_features,
      'disable=s' => \$opt_disable_features,
      'proto=s' => \$opt_prototype,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $group_action;
  if ( $opt_in ) {
      my $group_id;
      try {
	  $group_id = $gitlab->get_group_id( $opt_in, 'exact-match' => 1, 'verify' => 1 );
      } catch {
	  die "Invalid group $opt_in specified for bulk project operation.\n";
      };
      @ARGV = map { $_->{ 'id' } } @{ $gitlab->my_projects_in_groups( [ $group_id ] ) };
  }

  if ( not @ARGV ) {
      return "Error: Missing project argument.\n";
  }
  if ( @ARGV > 1 and ( $opt_name or $opt_path ) ) {
      die "** Error: Cannot change name, or path in bulk operations.\n";
  }
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }

  if ( $opt_visibility ) {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid project visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }
  if ( $opt_branch ) {
      $opt_branch =~ m/^[A-z][A-z0-9_-]{3,}/
	  or die "Invalid name for default branch specified.
Please start with a letter and use at least 4 alphanum characters, '-' or '_'\n";
  }

  my $params = {
      'desc' => $opt_desc,
      'visibility' => $opt_visibility,
      'branch' => $opt_branch,
  };

  my $proto_project;
  my $proto_webhooks;
  if ( $opt_prototype ) {
      my $proto_id;
      try {
	  $proto_id = $gitlab->get_project_id( $opt_prototype );
	  $proto_project = $gitlab->get_project_from_id( $proto_id );
      } catch {
	  die "Cannot find prototype project \"$opt_prototype\".\n";
      };
      my @clonable_fields = qw(
          default_branch
          issues_enabled
	  merge_requests_enabled
	  jobs_enabled
	  wiki_enabled
	  snippets_enabled
	  container_registry_enabled
	  shared_runners_enabled
	  visibility
	  public_jobs
	  only_allow_merge_if_pipeline_succeeds
	  only_allow_merge_if_all_discussions_are_resolved
	  lfs_enabled
	  request_access_enabled
	  tag_list
	  approvals_before_merge
      );
      foreach my $fld ( @clonable_fields ) {
	  $params->{ $fld } = $proto_project->{ $fld };
      }
      try { 
	  $proto_webhooks = $gitlab->rest_get_list( '/projects/' . $proto_id . '/hooks' );
      } catch {
	  ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) && 
	      warn "No webhooks found to clone: $!\n";
      };
  }

  my $ftr_map =  {
      'issues' => 'issues_enabled',
      'merge_requests' => 'merge_requests_enabled',
      'mr' => 'merge_requests_enabled',
      'jobs' => 'jobs_enabled',
      'wiki' => 'wiki_enabled',
      'container_registry' => 'container_registry_enabled',
      'containers' => 'container_registry_enabled',
      'shared_runners' => 'shared_runners_enabled',
      'snippets' => 'snippets_enabled',
      'runners' => 'shared_runners_enabled',
      'lfs' => 'lfs_enabled',
      'request_access' => 'request_access_enabled',
      'request' => 'request_access_enabled',
      'merge_requires_green_build' => 'only_allow_merge_if_pipeline_succeeds',
      'merge_requires_resolved_discussion' => 'only_allow_merge_if_all_discussions_are_resolved'
  };
  my @project_features;
  if ( $opt_enable_features ) {
      my @features = split(',', $opt_enable_features );
      
      foreach my $ftr ( @features ) {
	  my $feature;
	  if ( not exists $ftr_map->{ lc $ftr } ) {
	      die "** Error: Enable requests invalid project feature $ftr.
** Enable one or more of:\n    " . join( "\n    ", sort keys %{ $ftr_map } ) . "\n";
	  } else {
	      push( @project_features, $ftr_map->{ lc $ftr } );
	  }
      }
  }

  my @project_no_features;
  if ( $opt_disable_features ) {
      my @features = split(',', $opt_disable_features );
      
      foreach my $ftr ( @features ) {
	  my $feature;
	  if ( not exists $ftr_map->{ lc $ftr } ) {
	      die "** Error: Disable requests invalid project feature $ftr.
** Enable one or more of:\n    " . join( "\n    ", sort keys %{ $ftr_map } ) . "\n";
	  } else {
	      push( @project_no_features, $ftr_map->{ lc $ftr } );
	  }
      }
  }

  foreach my $ftr ( @project_features ) {
      $params->{ $ftr } = 1;
  }
  foreach my $ftr ( @project_no_features ) {
      $params->{ $ftr } = 0;
  }

  my $endpoint = '/projects/';

  my @results;								 
  foreach my $subject ( @ARGV ) {
      my $project_id = $this->assert_project_id( $subject );
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_put( $endpoint . $project_id, $params );
      } catch {
	  chomp $_;
	  if ( ref $_ eq 'HASH' ) {
	      my $msg = "** Error: Edit project $subject failed:\n";
	      foreach my $k ( sort keys %{ $_ } ) {
		  my $msgs = $_->{ $k };
		  $msg .= "  $k: " . join( "\n    ", @{ $msgs } ) . "\n";
	      }
	      print STDERR $msg;
	  } else {
	      die "** Error: Edit project $subject failed: $_\n";
	  }
      };
      $result_obj or next; # assume error caught by catch; catch cannot do next.

      if ( ref $proto_webhooks ) {
	  foreach my $whook ( @{ $proto_webhooks } ) {
	      my $wh_post_params = {};
	      foreach my $key ( qw( url enable_ssl_verification token ) , @{ $gitlab->webhook_events() } ) {
		  $wh_post_params->{ $key } = $whook->{ $key };
	      };
	      $wh_post_params->{ 'id' } = $project_id;
	      try {
		  $gitlab->rest_post( "/projects/$project_id/hooks", $wh_post_params );
	      } catch {
		  chomp $_;
		  $this->check( "ERR: Could not create webhook " . $whook->{ 'url' } . 
				" for project $subject: $_\n" );
		  next;
	      };
	  }
      }

      push( @results, $result_obj );
      print ucfirst "update" . "d project $subject\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub assert_project_id {
    my ($this, $pid ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $project_id;
    try {
	$project_id = $gitlab->get_project_id( $pid, 'exact-match' => 1 );
    } catch {
	chomp $_;
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

sub assert_group_id {
    my ($this, $gid ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $group_id;
    try {
	$group_id = $gitlab->get_group_id( $gid, 'exact-match' => 1 );
    } catch {
	die "Cannot find group \"$gid\" ($_).\n";
    };

    return $group_id;
}

sub assert_user_id {
    my ($this, $uid ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $user_id;
    try {
	$user_id = $gitlab->get_user_id( $uid );
    } catch {
	die "Cannot determine id for user \"$uid\" ($_).\n";
    };

    return $user_id;
}

sub assert_access_level {
    my ($this, $level_arg ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my @level = grep { m/${level_arg}/i } @ { $gitlab->access_level() };
    if ( @level != 1 ) {
	die "Invalid access level requested: $level_arg.
Select either of: " . join( ', ', @{ $gitlab->access_level() } ) . "\n";
    }

    return $gitlab->access_level( shift @level );
}

1;
