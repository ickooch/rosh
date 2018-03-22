package JiraCLI::Projects;

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

use  JiraCLI::Projects_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsprj', 'cmd_lsprj' ],
     ['descprj', 'cmd_descprj' ],
     ['mkprj', 'cmd_mkprj' ],
     ['rmprj', 'cmd_rmprj' ],
     ['editprj', 'cmd_editprj' ], 
		 ]);
  
  return $this;
}


sub cmd_lsprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Projects_IF::gcli_lsprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/project';


  my @results;								 
  @results = @{ $jira->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ ( $_->{ 'name' } =~ m/${filter_re}/ ) or 
      ( $_->{ 'key' } =~ m/${filter_re}/ ) } @results;
  }
  print scalar( @results ) . " projects.\n";
  if ( $opt_format ) {
      my $required_fields;
      $required_fields = $jira->format_required_fields( $opt_format );

      # direct fields are returned by the list projects requests 
      my $direct_fields = {
	  'projectTypeKey' => 1,
	  'key' => 1,
	  'self' => 1,
	  'avatarUrls' => 1,
	  'id' => 1,
	  'name' => 1,
	  'expand' => 1,
      };
      my $need_extended_info = 0;
      foreach my $fld ( split(/,/, $required_fields ) ) {
	  if ( not exists $direct_fields->{ $fld } ) {
	      $need_extended_info = 1;
	      last;
	  }
      }
      if ( $need_extended_info ) {
	  foreach my $proj ( @results ) {
	      my $result_obj = $jira->rest_get_single( '/project/' . $proj->{ 'id' } );
	      $this->expand_project( $result_obj, 'only_roles' );
	      foreach my $fld ( keys %{ $result_obj } ) {
		  $proj->{ $fld } = $result_obj->{ $fld };
	      }
	  }
      }
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print '[Format: "' . '%n (%F:key / %i)' . '"]' . "\n";
      print join( "\n", map { "$_->{ 'name' }\t ($_->{ 'key' } / $_->{ 'id' })" } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Projects_IF::gcli_descprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/project/' . $subject;
  my @results;								 

  my $result_obj = $jira->rest_get_single( $endpoint );
  $this->expand_project( $result_obj );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print $jira->substitute_format( "Project %n\n  Id: %F:id\n  Key: %F:key\n  ", $result_obj );
      print $jira->substitute_format( "Description: %d\n  Lead: %F:lead.name\n  ", $result_obj );
      print $jira->substitute_format( "Project type: %F:projectTypeKey\n  ", $result_obj );
      print "Roles:\n  ";
      foreach my $r ( sort keys( %{ $result_obj->{ 'roles' } } ) ) {
	  print "  $r: " . join( ', ', keys %{ $result_obj->{ 'roles' }->{ $r }->{ 'actors' } } ) . "\n  ";
      }
      print "Issue types enabled:\n  ";
      foreach my $itype ( sort { $a->{ 'name' } cmp $b->{ 'name' } } @{ $result_obj->{ 'issueTypes' } } ) {
	  print "  $itype->{ 'name' }";
	  if (  $itype->{ 'description' } ) {
	      print " ($itype->{ 'description' })\n  ";
	  } else {
	      print "\n  ";
	  }
      }
      print "Permission scheme:\n  ";
      print "  $result_obj->{ 'permission_scheme' }->[ 0 ] ($result_obj->{ 'permission_scheme' }->[ 1 ])\n  ";
      print "Notification scheme:\n  ";
      print "  $result_obj->{ 'notification_scheme' }->[ 0 ] ($result_obj->{ 'notification_scheme' }->[ 1 ])\n  ";
      print "Security levels:\n  ";
      foreach my $lvl ( @{ $result_obj->{ 'security_levels' } } ) {
	  print "  $lvl->{ 'name' } ($lvl->{ 'id' })\n  ";
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub expand_project {
    my ( $this, $project, $only_roles ) = @_;

    my $jira = $this->preference( 'jira_connector' );
    
    # get roles
    my @role_descs;
    my %roles;
    foreach my $role_name ( keys %{ $project->{ 'roles' } } ) {
	my $rd = $project->{ 'roles' }->{ $role_name };
	# $rd looks like "https://jira.server.com/jira/rest/api/2/project/10800/role/10000"
	$rd =~ s/^.*(\/project.*)/$1/;
	my $role_desc = $jira->rest_get_single( $rd );
	$roles{ $role_name } = {
	    'id' => $role_desc->{ 'id'},
	    'actors' => {},
	};
	foreach my $act ( @{ $role_desc->{ 'actors' } } )  {
	    $roles{ $role_name }->{ 'actors' }->{ $act->{ 'name' } } = $act;
	}
    }
    $project->{ 'roles' } = \%roles;

    return $project 
	if ( $only_roles );
    
    # get permission scheme
    try {
	my $permission_scheme = $jira->rest_get_single( '/project/' . $project->{ 'id' } . '/permissionscheme' );
	$project->{ 'permission_scheme' } = [ $permission_scheme->{ 'name' }, $permission_scheme->{ 'id' } ];
    };
    
    # get security level
    try {
	my $security_level = $jira->rest_get_single( '/project/' . $project->{ 'id' } . '/securitylevel' );
	$project->{ 'security_levels' } = $security_level->{ 'levels' };
    };

    # get notification scheme
    try {
	my $notify = $jira->rest_get_single( '/project/' . $project->{ 'id' } . '/notificationscheme?expand=all' );
	$project->{ 'notification_scheme' } = [ $notify->{ 'name' }, $notify->{ 'id'} ];
	#    $project->{ 'notification_scheme_events' } = $notify->{ 'notificationSchemeEvents' };
    };
    
    return $project;
}

sub cmd_mkprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Projects_IF::gcli_mkprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_key, $opt_desc, $opt_notification_scheme, $opt_permission_scheme, 
       $opt_title, $opt_type, $opt_lead, $opt_roles, $opt_prototype,  );

  GetOptions (
      'help' => \$opt_help,
      'key=s' => \$opt_key,
      'title|name=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'notification-scheme|notify=s' => \$opt_notification_scheme,
      'permission-scheme|perm=s' => \$opt_permission_scheme,
      'type=s' => \$opt_type,
      'lead=s' => \$opt_lead,
      'roles=s' => \$opt_roles,
      'proto=s' => \$opt_prototype,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }

  print "*** Creating projects via REST API is not properly supported by Atlassian.\n";

  return 1;
}

sub unsupported_cmd_mkprj {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Projects_IF::gcli_mkprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_key, $opt_desc, $opt_notification_scheme, $opt_permission_scheme, 
       $opt_title, $opt_type, $opt_lead, $opt_roles, $opt_prototype,  );

  GetOptions (
      'help' => \$opt_help,
      'key=s' => \$opt_key,
      'title|name=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'notification-scheme|notify=s' => \$opt_notification_scheme,
      'permission-scheme|perm=s' => \$opt_permission_scheme,
      'type=s' => \$opt_type,
      'lead=s' => \$opt_lead,
      'roles=s' => \$opt_roles,
      'proto=s' => \$opt_prototype,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;
  
  my $jira = $this->preference( 'jira_connector' );
  
  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }

  # for convenience, use name of project as key if no key given and name is suitable
  if ( not $opt_key ) {
      if ( $subject =~ m/[A-Z0-0]{3,6}/i ) {
	  $opt_key = uc $subject;
      }
  }
  if ( not $opt_key ) {
      return "Error: You must specify a new project key.\n";
  }
  $opt_key = uc $opt_key;
  if ( not $opt_key =~ m/[A-Z0-0]{3,6}/ ) {
      return "Error: Bad project key - please use 3 - 6 all caps letters or numbers.\n";
  }
  try {
      my $res = $jira->rest_get_single( '/projectvalidate/key?key=' . $opt_key );
      if ( %{ $res->{ 'errors' } } ) {
	  die "Error: Validate of proposed project key failed: " . join( '', values( %{ $res->{ 'errors' } } )) . "\n";
      }
  } catch {
      die "$_";
     # continue
  };
  
  # initialize create parameters
  my $post_params = {
      'key' => $opt_key,
      'name' => $subject,
  };
  if ( $opt_title ) {
      $post_params->{ 'name' } = $opt_title;
  }
  if ( $opt_desc ) {
      $post_params->{ 'description' } = $opt_desc;
  }

  if ( $opt_prototype ) {
      my $proto_id;
      try {
	  $proto_id = $this->assert_project_id( $opt_prototype );
      } catch {
	  die "Cannot find prototype project \"$opt_prototype\".\n";
      };
      
      my $endpoint = '/project/' . $proto_id;
      my @results;								 

      my $proto_project = $jira->rest_get_single( $endpoint );
      $this->expand_project( $proto_project );
      my @clonable_fields = qw(
    	      projectTypeKey
    	      lead
    	      assigneeType
    	      avatarId
    	      issueSecurityScheme
    	      permissionScheme
    	      notificationScheme
      );
      my $cf_map = {
	  'permissionScheme' => 'permission_scheme',
	  'notificationScheme' => 'notification_scheme',
      };
      foreach my $fld ( @clonable_fields ) {
	  my $proto_field = exists( $cf_map->{ $fld } ) ? $cf_map->{ $fld } : $fld;
	  if ( ref $proto_project->{ $fld } eq 'HASH' ) {
	      $post_params->{ $fld } = $proto_project->{ $fld }->{ 'key' };
	  } elsif ( $proto_project->{ $fld } ) {
	      $post_params->{ $fld } = $proto_project->{ $fld };
	  }
      }
  }
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }

  my $endpoint = '/projects';
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $post_params );
  } catch {
      die "create project failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "create" . "d project " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_rmprj {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = JiraCLI::Projects_IF::gcli_rmprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $jira->assert_object_id( 'project', $subject );
  } catch {
      die "Cannot determine id for project object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really remove project $subject ?", 'no' ))) {
      $this->print( ucfirst "project $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:project-id';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such project: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d project " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command rmprj in JiraCLI::Projects' . "\n";

  return $stat;
}

sub cmd_editprj {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = JiraCLI::Projects_IF::gcli_editprj_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editprj ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_desc, $opt_visibility, $opt_branch, $opt_enable_features, $opt_dis_features,  );
  GetOptions (
      'help' => \$opt_help,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'branch|b=s' => \$opt_branch,
      'enable=s' => \$opt_enable_features,
      'disable=s' => \$opt_dis_features,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing project argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $jira->assert_object_id( 'project', $subject );
  } catch {
      die "Cannot determine id for project object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:project-id';

  my $params = { 'help' => $opt_help,
                'desc' => $opt_desc,
                'visibility' => $opt_visibility,
                'branch' => $opt_branch,
                'enable_features' => $opt_enable_features,
                'dis_features' => $opt_dis_features,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "update project failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "update" . "d project " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editprj in JiraCLI::Projects' . "\n";

  return $stat;
}

1;
