package GitLabCLI::Requests;

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

use  GitLabCLI::Requests_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsreq', 'cmd_lsreq' ],
     ['descreq', 'cmd_descreq' ],
     ['accessreq', 'cmd_accessreq' ],
     ['approvereq', 'cmd_approvereq' ],
     ['denyreq', 'cmd_denyreq' ], 
		 ]);
  
  return $this;
}


sub cmd_lsreq {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Requests_IF::gcli_lsreq_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsreq ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my @projects;
  my @groups;
  my $in_what;
  if ( $opt_in ) {
      # verify project id
      my $item;
      try {
	  my $id = $this->assert_project_id( $opt_in );
	  $item = $gitlab->get_project_from_id( $id );
	  push( @projects, $item );
	  $in_what = 'project';
      } catch {
	  try {
	      my $id = $this->assert_group_id( $opt_in );
	      $item = $gitlab->get_group_from_id( $id );
	      push( @groups, $item );
	      $in_what = 'group';
	  } catch {
	      chomp $_;
	      die "** Invalid project or group requested with --in $opt_in.\n";
	  };
      };
  } else {
      print "[looking for pending access requests in your groups and projects..]\n";
      my $entities = $this->load_all_requests();
      @projects = @{ $entities->[ 0 ] };
      @groups = @{ $entities->[ 1 ] };
  }
  my %access_requests;
  foreach my $this_group ( @groups ) {
      my @rqs = $this->load_group_requests( $this_group );
      if ( @rqs ) {
	  $access_requests{ 'group' }->{ $this_group->{ 'name' } } = \@rqs;
      }
  }
  if ( @groups ) {
      print "GROUP ACCESS REQUESTS:\n" . '=' x length( "GROUP ACCESS REQUESTS:" ) . "\n";
  } else {
      print "* No pending group access requests.\n";
  }
  if ( exists $access_requests{ 'group' } ) {
      foreach my $g ( sort keys %{ $access_requests{ 'group' } } ) {
	  print "  group $g:\n";
	  my $res = $access_requests{ 'group' }->{ $g };
	  if ( $opt_format ) {
	      print join( "\n    ", map { $gitlab->substitute_format( $opt_format, $_ ) } @{ $res } ) . "\n"; 
	  } elsif ( $opt_long ) {
	      print join( "\n    ", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @{ $res } ) . "\n";
	  } else {
	      my $norm_format = "%i: %n (%F:username), %F:requested_at";
	      print "    " . join( "\n    ", map { $gitlab->substitute_format( $norm_format, $_ ) } @{ $res } ) . "\n";
	  }
      }
      print "\n";
  } else {
      @groups && print "  *currently no access requests" . 
	  (( defined $in_what and $in_what eq 'group' ) ? " in group $opt_in" : '' ) . "*\n\n";

  }
  foreach my $this_project ( @projects ) {
      my @rqs = $this->load_project_requests( $this_project );
      if ( @rqs ) {
	  $access_requests{ 'project' }->{ $this_project->{ 'name' } } = \@rqs;
      }
  }
  
  if ( @projects) {
      print "PROJECT ACCESS REQUESTS:\n" . '=' x length( "PROJECT ACCESS REQUESTS:" ) . "\n";
  } else {
      print "* No pending project access requests.\n";
  }
  if ( exists $access_requests{ 'project' } ) {
      foreach my $p ( sort keys %{ $access_requests{ 'project' } } ) {
	  print "  project $p:\n";
	  my $res = $access_requests{ 'project' }->{ $p };
	  if ( $opt_format ) {
	      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @{ $res } ) . "\n"; 
	  } elsif ( $opt_long ) {
	      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @{ $res } ) . "\n";
	  } else {
	      my $norm_format = "%i: %n (%F:username), %F:requested_at";
	      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @{ $res } ) . "\n";
	  }
      }
  } else {
      @projects && print "  *currently no access requests" . 
	  (( defined $in_what and $in_what eq 'project' ) ? " in project $opt_in" : '' ) . "*\n";
  }
  
  # end this routine by returning a status indicator; not null means error!

  return $stat;
}

sub load_all_requests {
    my $this = shift;

    print "[patience...]\n";
    my $gitlab = $this->preference( 'gitlab_connector' );

    my @projects = @{ $gitlab->my_projects() };
    my @groups = @{ $gitlab->rest_get_list( '/groups?owned=true' ) };

    my ( @p_rqs, @g_rqs );
    foreach my $g ( @groups ) {
	$this->load_group_requests( $g ) && push( @g_rqs, $g );
    }
    foreach my $p ( @projects ) {
	$this->load_project_requests( $p ) && push( @p_rqs, $p );
    }

    return [ \@p_rqs, \@g_rqs ];
}

sub load_group_requests {
    my ( $this, $grp ) = @_;
    
    my $gitlab = $this->preference( 'gitlab_connector' );
    my $grp_id = $grp->{ 'id' };

    my ( $rqs, $cached );
    try {
	$rqs = $this->cache_lookup( $grp_id );
	$rqs = [ grep { not exists $_->{ 'cancelled' } } @{ $rqs } ];
	$cached = 1;
    } catch {
	my $endpoint = '/groups/' . $grp_id . '/access_requests';
	$rqs = $gitlab->rest_get_list( $endpoint );
	$cached = 0;
    };

    if ( not $cached and $rqs and @{ $rqs } ) {
	foreach my $greq ( @{ $rqs } ) {
	    $greq->{ 'context_id' } = $grp_id;
	    $greq->{ 'context_name' } = $grp->{ 'name' };
	    $greq->{ 'context' } = 'g';
	    $this->cache( $greq->{ 'id' }, $greq );
	}
	$this->cache( $grp_id, $rqs );
    }
    return wantarray ? @{ $rqs } : scalar @{ $rqs };
}

sub load_project_requests {
    my ( $this, $prj ) = @_;
    
    my $gitlab = $this->preference( 'gitlab_connector' );
    my $prj_id = $prj->{ 'id' };

    my ( $rqs, $cached );
    try {
	$rqs = $this->cache_lookup( $prj_id );
	$rqs = [ grep { not exists $_->{ 'cancelled' } } @{ $rqs } ];
	$cached = 1;
    } catch {
	my $endpoint = '/projects/' . $prj_id . '/access_requests';
	$rqs = $gitlab->rest_get_list( $endpoint );
	$cached = 0;
    };
    
    if ( not $cached and $rqs and @{ $rqs } ) {
	foreach my $preq ( @{ $rqs } ) {
	    $preq->{ 'context_id' } = $prj_id;
	    $preq->{ 'context_name' } = $prj->{ 'name' };
	    $preq->{ 'context' } = 'p';
	    $this->cache( $preq->{ 'id' }, $preq );
	}
	$this->cache( $prj_id, $rqs );
    }
    return wantarray ? @{ $rqs } : scalar @{ $rqs };
}

sub cmd_descreq {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Requests_IF::gcli_descreq_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descreq ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_show_projects,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'projects|P' => \$opt_show_projects,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing request argument.\n";
  }
  my $user_id = $gitlab->verify_user_id( $gitlab->get_user_id( $subject ) );
  die "** Error: No user $subject known.\n"
      if ( not defined $user_id );
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $req;
  try {
      $req = $this->cache_lookup( $user_id );
  } catch {
      print "[Could not find request $subject in cache - performing full lookup...]\n";
      $this->load_all_requests();
  };
  if ( not defined $req ) {
      try {
	  $req = $this->cache_lookup( $user_id );
      } catch {
	  die "** Request from $subject not found.\n";
      };
  }
      
  my @results;								 
  push( @results, $req );
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_accessreq {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Requests_IF::gcli_accessreq_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_accessreq ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_userid, $opt_for_id, $opt_in, $opt_to_target,  );
  GetOptions (
      'help' => \$opt_help,
      'userid=i' => \$opt_userid,
      'for=s' => \$opt_for_id,
      'in=s' => \$opt_in,
      'to=s' => \$opt_to_target,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $opt_to_target;   # these two switches are synonymous; opt_in prevails
  $opt_for_id ||= $opt_userid;  # these two switches are synonymous; opt_for_id prevails
  
  # initial option checking here
  if ( not $opt_in ) {
      die "** Error: No group or project specified in access request (use --in or --to)\n";
  }
  if ( not $opt_for_id ) {
      die "** Error: No user specified for whom access to $opt_in is requested (use --for or --userid)\n";
  }
  my ( $id, $is_group );
  # verify project id
  my $id;
  try {
      $id = $this->assert_project_id( $opt_in );
      $is_group = 0;
  } catch {
      try {
	  $id = $this->assert_group_id( $opt_in );
	  $is_group = 1;
      } catch {
	  chomp $_;
	  die "** Invalid project or group given with --in $opt_in.\n";
      };
  };

  my $endpoint = ( $is_group ? '/groups/' : '/projects/' ) . $id . '/access_requests';
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint );
  } catch {
      chomp $_;
      die "** Error: access request to $opt_in failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "access to " . ( $is_group ? 'group' : 'project' ) . " requested.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_approvereq {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Requests_IF::gcli_approvereq_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_approvereq ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_perm,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'as=s' => \$opt_perm,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user argument.\n";
  }
  my $user_id = $gitlab->verify_user_id( $gitlab->get_user_id( $subject ) );

  die "** Error: No user $subject known.\n"
      if ( not defined $user_id );
  
  my $req;
  try {
      $req = $this->cache_lookup( $user_id );
      $user_id = $gitlab->get_user_id( $req->{ 'username' } );
      $opt_in = $req->{ 'context_id' };
  };
  if ( not $opt_in ) {
      die "** Error: approve request requires an applicable project or group. Use option --in <project/group>.\n

$usage\n";
  } 

  if ( not $opt_perm ) {
      die "** Error: approve request requires an access-level argument (--as <developer etc.>)\n";
  }
  
  my ( $id, $is_group );
  # verify project id
  my $id;
  try {
      $id = $this->assert_project_id( $opt_in );
      $is_group = 0;
  } catch {
      try {
	  $id = $this->assert_group_id( $opt_in );
	  $is_group = 1;
      } catch {
	  chomp $_;
	  die "** Invalid project or group given with --in $opt_in.\n";
      };
  };

  my $endpoint = ( $is_group ? '/groups/' : '/projects/' ) . $id . '/access_requests/' .
      $user_id . '/approve';
  
  my $perm = $this->assert_access_level( $opt_perm );
  my $params = {
		 'access_level' => $gitlab->access_level( $opt_perm ) 
  };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_put( $endpoint, $params );
      $this->uncache( $user_id );
  } catch {
      die ucfirst "approve request failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "approve" . "d request " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_denyreq {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Requests_IF::gcli_denyreq_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_denyreq ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user argument.\n";
  }
  my $user_id;
  try {
      $user_id = $gitlab->get_user_id( $subject );
  } catch {
      die "Cannot determine id for user \"$subject\".\n";
  };
  
  if ( not $opt_in ) {
      die "deny request requires an applicable project or group. Use option --in <project/group>.\n

$usage\n";
  } 

  my ( $id, $is_group );
  # verify project id
  my $id;
  try {
      $id = $this->assert_project_id( $opt_in );
      $is_group = 0;
  } catch {
      try {
	  $id = $this->assert_group_id( $opt_in );
	  $is_group = 1;
      } catch {
	  chomp $_;
	  die "** Invalid project or group given with --in $opt_in.\n";
      };
  };

  my $endpoint = ( $is_group ? '/groups/' : '/projects/' ) . $id . '/access_requests/' .
      $user_id;
  
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      chomp $_;
      die "Deny access request failed: $_.\n";
  };
      
  push( @results, $subject );
  print ucfirst "denied $subject's request to join " . ( $is_group ? 'group' : 'project' ) .
      $opt_in . ".\n";

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
	$project_id = $gitlab->get_project_id( $pid );
    } catch {
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
	$group_id = $gitlab->get_group_id( $gid );
    } catch {
	die "Cannot determine id for group object \"$gid\" ($_).\n";
    };

    return $group_id;
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
