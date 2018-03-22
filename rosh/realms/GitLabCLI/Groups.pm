package GitLabCLI::Groups;

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

use  GitLabCLI::Groups_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsgrp', 'cmd_lsgrp' ],
     ['lsgrp_projects', 'cmd_lsgrp_projects' ],
     ['lsgrp_members', 'cmd_lsgrp_members' ],
     ['addgrp_members', 'cmd_addgrp_members' ],
     ['rmgrp_members', 'cmd_rmgrp_members' ],
     ['descgrp', 'cmd_descgrp' ],
     ['addgrp', 'cmd_addgrp' ],
     ['deletegrp', 'cmd_deletegrp' ],
     ['editgrp', 'cmd_editgrp' ],
     ['transfer_project', 'cmd_transfer_project' ], 
		 ]);
  
  return $this;
}


sub cmd_lsgrp {
  my $stat = "";

  my $this = shift;


  my ( $opt_help, $opt_long, $opt_short,  $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  my $json = JSON->new->allow_nonref;
  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }

  my $usage = GitLabCLI::Groups_IF::gcli_lsgrp_usage();

  if ( $opt_help ) {
      print $usage;
      return 0;
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  my $endpoint = '/groups';  								 
  my @results = sort { $a->{ 'full_path' } cmp $b->{ 'full_path' } } @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }

  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ' (' . $_->{ 'full_path' } . '): ' . $json->pretty->encode( $_ ) } @results ) . "\n"; 
  } else {
      my $norm_format = "%n \t(%i,\t%F:full_path, %F:visibility)";
      foreach my $gd ( @results ) {
	  my $lvl = subgroup_lvl( $gd );
	  my $pref = "  " x $lvl;
	  print $pref . $gitlab->substitute_format( $norm_format, $gd ) . "\n";
      }
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub subgroup_lvl {
    my $grp_desc = shift;

    my @p = split( '/', $grp_desc->{ 'full_path' } );

    return (scalar(@p) - 1);
}
    
sub cmd_lsgrp_projects {
  my $stat = "";

  my $this = shift;

  my ( $opt_help, $opt_long, $opt_short,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      );

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/groups/:group-id/projects';

  
  
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'long' => $opt_long,
                                                                  'short' => $opt_short,
                                                                 'subject_id' => $subject_id,});
  								 
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 

  if ( $opt_long ) {
      {
	  local $Data::Dumper::Terse = 1;
	  print join( "\n", map { $_->{ 'id' } . ': ' . ($opt_json ?
      to_json( $_ ) : Dumper( $_ ) ) } @results ) . "\n"; 
      }
  } else {
      print join( "\n", map { exists $_->{ 'name' } ? $_->{ 'name' } : $_->{ 'id' } . ' (' . $_->{ 'id'} . ')' } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_lsgrp_members {
  my $stat = "";

  my $this = shift;

  my ( $opt_help, $opt_long, $opt_short,  $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  my $gitlab = $this->preference( 'gitlab_connector' );
  my $json = JSON->new->allow_nonref;

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/groups/:group-id/members';

  
  
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'long' => $opt_long,
                                                                  'short' => $opt_short,
                                                                 'subject_id' => $subject_id,});
  								 
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 

  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)";
      foreach my $res ( sort { $a->{ 'name' } cmp $b->{ 'name' } } @results ) {
          my $role = lc $gitlab->access_level( $res->{ 'access_level' } );
	  $role =~ s/\s*access//;
          print "$res->{ 'name' }, $role (ID: $res->{ 'id' })\n";
      }
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_addgrp_members {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Groups_IF::gcli_addgrp_members_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addgrp_members ';
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
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $group_id;
  try {
      $group_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
  } catch {
      die "Cannot determine id for group object \"$subject\": $_.\n";
  };
  
  my @users = split(',', join( ',', @ARGV ) );
  if (not @users ) {
      die "Please specify one or more users to add as members.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my @user_ids = map { $this->assert_user_id( $_ ) } @users;

  my $perm = $this->assert_access_level( $opt_perm );
  
  my $endpoint = '/groups/' . $group_id . '/members';

  my @results;								 

  my $params = {
      'id' => $group_id,
      'access_level' => $perm,
  };
  
  foreach my $user_id ( @user_ids ) {
      $params->{ 'user_id' } = $user_id;
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_post( $endpoint, $params );
      } catch {
	  chomp $_;
	  print "Could not add user $user_id to group $group_id as $opt_perm: $_\n";
	  next;
      };
      push( @results, from_json( $result_obj->{ 'body' } ) );
  }
  
  print join( "\n", map { "$_->{ name } added to group $subject with " . 
			      $gitlab->access_level( $_->{ 'access_level' } ) . 
			      '.' } @results ) . "\n";
  
  return $stat;
}

sub cmd_rmgrp_members {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Groups_IF::gcli_rmgrp_members_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmgrp_members ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help,  );
  GetOptions (
      'help' => \$opt_help,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $group_id;
  try {
      $group_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
  } catch {
      die "Cannot determine id for group object \"$subject\": $_.\n";
  };

  my @users = split(',', join( ',', @ARGV ) );
  if (not @users ) {
      die "Please specify one or more users to add as members.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my @user_ids = map { $this->assert_user_id( $_ ) } @users;

  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint = '/groups/' . $group_id . '/members/';
  
  my @results;								 
  
  foreach my $user_id ( @user_ids ) {
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_delete( $endpoint . $user_id );
      } catch {
	  print "Could not remove user $user_id from group $group_id: $_\n";
	  next;
      };
      push( @results, $user_id );
  }
  print join( ".\n", map { $_->{ 'name' } . " removed from group $subject" } 
	      map { $gitlab->rest_get_single( '/users/' . $_ ) } @results ) . ".\n";
  
  return $stat;
}

sub cmd_descgrp {
  my $stat = "";

  my $this = shift;

  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_json,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'json' => \$opt_json,
      );

  my $gitlab = $this->preference( 'gitlab_connector' );
  my $json = JSON->new->allow_nonref;

  # intial option checking here
  if ( not @ARGV ) {
      return "Error: Missing group argument.\n";
  }
  my @results;
  foreach my $subject ( @ARGV ) {
      my $subject_id;
      try {
	  $subject_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
      } catch {
	  die "Cannot determine id for group object \"$subject\": $_.\n";
      };
      
      # end this routine by returning a status indicator; not null means error!
      
      if ( $opt_long ) {
	  $opt_short = '';
      }
      my $endpoint = '/groups/';
      my $result_obj = $gitlab->rest_get_single( $endpoint . $subject_id );
      push( @results, $result_obj );
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      foreach my $result_obj ( @results ) {
	  print "Group: $result_obj->{ 'name' } ($result_obj->{ 'id' })\n";
	  if ( $result_obj->{ 'description' } ) {
	      print $result_obj->{ 'description' } . "\n";
	  }
	  print $gitlab->substitute_format( "  Visibility: %F:visibility\n",
					    $result_obj );
	  my @enabled_features;
	  while ( my ($k, $v ) = each  %{ $result_obj } ) {
	      if ( ( $k =~ m/_enabled/ ) && $v ) {
		  my $k1 = $k;
		  $k1 =~ s/_enabled//;
		  push( @enabled_features, $k1 );
	      }
	  }
	  print "Features and other options enabled in this group:\n  " .
	      join( "\n  ", sort @enabled_features ) . "\n\n";
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Groups_IF::gcli_addgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addgrp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_group, $opt_name, $opt_path, 
       $opt_prototype, $opt_in, $opt_desc, $opt_visibility,  );
  GetOptions (
      'help' => \$opt_help,
      'group=s' => \$opt_group,
      'name|n=s' => \$opt_name,
      'path=s' => \$opt_path,
      'proto=s' => \$opt_prototype,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
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
      die "** Error: Missing group argument.\n";
  }
  $subject =~ s/"//g;
  
  if ( not $opt_path ) {
      if ( $subject =~ m/^[A-z][\w\-\.]+$/ ) {
	  $opt_path = $subject;
      } else {
	  die "** Error: A path is required for creating group \"$subject\".\n" .
	      "A group path is a single word consisting of alphanumeric and '-', '_', or '.'.\n";
      }
  }
  my $params = {
      'name' => $subject,
      'path' => $opt_path,
  };
  my $proto_group;
  if ( $opt_prototype ) {
      my $proto_id;
      try {
	  $proto_id = $gitlab->get_group_id( $opt_prototype );
	  $proto_group = $gitlab->rest_get_single( '/groups/' . $proto_id );
      } catch {
	  chomp $_;
	  die "Cannot find prototype group \"$opt_prototype\": $_.\n";
      };
      my @clonable_fields = qw(
         membership_lock
         share_with_group_lock
         visibility
         lfs_enabled
         request_access_enabled
         parent_id
      );
      foreach my $fld ( @clonable_fields ) {
	  $params->{ $fld } = $proto_group->{ $fld };
	  $params->{ 'namespace_id' } = $proto_group->{ 'namespace' }->{ 'id' }
      }
  }
  my $group_id;
  if ( $opt_in ) {
      try {
	  $group_id = $gitlab->get_group_id( $opt_in );
      } catch {
	  chomp $_;
	  die "** Error: Cannot find group \"$opt_in\": $_\n";
      }; 
  }
  if ( $group_id ) {
      $params->{ 'parent_id' } = $group_id;
  }
  if ( $opt_visibility ) {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid group visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }

  my $endpoint = '/groups';
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      chomp $_;
      die "** Error: add group failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "create" . "d group " . join( "\n    ", map { $gitlab->substitute_format( '%n with path %F:full_path (Id: %i)', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_deletegrp {
  my $stat = "";

  my $this = shift;

  my ( $opt_force, $opt_recursive, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'recursive|r' => \$opt_recursive,
      'help' => \$opt_help,
      );

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!
  
  my $group_id;
  try {
      $group_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
  } catch {
      chomp $_;
      die "** Error: Cannot find group \"$subject\": $_\n";
  };
  my $group = $gitlab->rest_get_single( '/groups/' . $group_id );
  my $projects = $group->{ 'projects' };

  if ( scalar @{ $projects } and not $opt_recursive ) {
      die "** Error: Group \"$subject\" has " . scalar @{ $projects } .
	  " projects that would also be deleted.\n" .
	  "Use option --recursive if this is intended.\n";
  }
  my $warn_not_empty = ( scalar @{ $projects } ) ? '(and the ' . 
      scalar @{ $projects } . ' projects in it)' : '';
  if ( not ( $opt_force or $this->confirm( "Really delete group $subject $warn_not_empty?", 'no' ))) {
      $this->print( ucfirst "group $subject not deleted.\n" );
      return $stat;
  }
  
  my $endpoint = '/groups/';
  try {
      $gitlab->rest_delete( $endpoint . $group_id );
  } catch {
      die "** Error: Delete group \"$subject\" failed: $_.\n";
  };
  print "Deleted group \"$subject\".\n";

  return $stat;
}

sub cmd_editgrp {
  my $stat = "";

  my $this = shift;


  my ( $opt_help, $opt_group, $opt_name, $opt_path, $opt_in, $opt_enable_features, 
       $opt_disable_features, $opt_desc, $opt_visibility,  );
  GetOptions (
      'help' => \$opt_help,
      'group=s' => \$opt_group,
      'name|n=s' => \$opt_name,
      'path=s' => \$opt_path,
      'in=s' => \$opt_in,
      'enable=s' => \$opt_enable_features,
      'disable=s' => \$opt_disable_features,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      );

  my $json = JSON->new->allow_nonref;
  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  if ( not @ARGV ) {
      die "** Error: Missing group argument.\n";
  }
  if ( @ARGV > 1 and ( $opt_name or $opt_path ) ) {
      die "** Error: Cannot change name, or path in bulk operations.\n";
  }
  if ( $opt_visibility ) {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid group visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }

  my $ftr_map =  {
      'lfs' => 'lfs_enabled',
      'request_access' => 'request_access_enabled',
      'member_lock' => 'membership_lock',
      'membership_lock' => 'membership_lock',
      'share_with_group_lock' => 'share_with_group_lock',
      'share_lock' => 'share_with_group_lock',
      'request' => 'request_access_enabled',
  };
  my @group_features;
  if ( $opt_enable_features ) {
      my @features = split(',', $opt_enable_features );
      
      foreach my $ftr ( @features ) {
	  my $feature;
	  if ( not exists $ftr_map->{ lc $ftr } ) {
	      die "** Error: Enable requests invalid group feature $ftr.
** Enable one or more of:\n    " . join( "\n    ", sort keys %{ $ftr_map } ) . "\n";
	  } else {
	      push( @group_features, $ftr_map->{ lc $ftr } );
	  }
      }
  }
  
  my @group_no_features;
  if ( $opt_disable_features ) {
      my @features = split(',', $opt_disable_features );
      
      foreach my $ftr ( @features ) {
	  my $feature;
	  if ( not exists $ftr_map->{ lc $ftr } ) {
	      die "Disable requests invalid group feature $ftr.
** Disable one or more of:\n    " . join( "\n    ", sort keys %{ $ftr_map } ) . "\n";
	  } else {
	      push( @group_no_features, $ftr_map->{ lc $ftr } );
	  }
      }
  }
  my $params = $gitlab->build_params({
      'name' => $opt_name,
      'path' => $opt_path,
      'desc' => $opt_desc,
      'visibility' => $opt_visibility,
				     });								 
  foreach my $ftr ( @group_features ) {
      $params->{ $ftr } = 1;
  }
  foreach my $ftr ( @group_no_features ) {
      $params->{ $ftr } = 0;
  }
  
  my @results;
  foreach my $subject ( @ARGV ) {
      my $subject_id;
      try {
	  $subject_id = $gitlab->get_group_id( $subject, 'exact-match' => 1 );
      } catch {
	  die "Cannot determine id for group object \"$subject\": $_.\n";
      };
      
      # end this routine by returning a status indicator; not null means error!
      
  
      my $endpoint = '/groups/' . $subject_id;
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_put( $endpoint, $params );
      } catch {
	  chomp $_;
	  if ( ref $_ eq 'HASH' ) {
	      my $msg = "** Error: Edit group $subject failed:\n";
	      foreach my $k ( sort keys %{ $_ } ) {
		  my $msgs = $_->{ $k };
		  $msg .= "  $k: " . join( "\n    ", @{ $msgs } ) . "\n";
	      }
	      print STDERR $msg;
	  } else {
	      die "** Error: Edit group $subject failed: $_\n";
	  }
      };
      $result_obj or next; # assume error caught by catch; catch cannot do next.
      
      push( @results, $result_obj );
      print ucfirst "update" . "d group $subject sucessfully\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  
  return $stat;
}

sub cmd_transfer_project {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

my ( $opt_help, $opt_group, $opt_in, $opt_, $opt_project, $opt_project_id,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      'group=s' => \$opt_group,
      'in=i' => \$opt_in,
      '' => \$opt_,
      'project|p=s' => \$opt_project,
      'in=i' => \$opt_project_id,
      );

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  if ( not ( $opt_project_id or $opt_project ) ) {
      $opt_project_id ||= $this->set( 'current_gitlab_project_id' );
      return "Error: Please specify the project's name or id for which groups should be listed.\n"
          if ( not $opt_project_id );
  }

  my $prj_id = $opt_project_id;
  if ( not $prj_id ) {
      try {
	  $prj_id = $gitlab->get_object_id( 'project', $opt_project );
      } catch {
	  print "No such project \"$opt_project\"\n";
      };
  }
  my $endpoint_template = '/groups/:group-id/projects/:project-id';

  if ( $opt_group ) {
      
      if ( not $opt_in ) {
	  my $subject_id;
	  try {
	      $subject_id = $gitlab->get_object_id( 'group', $opt_group );
	  } catch {
	      die "Cannot determine id for group \"$opt_group\": $!\n";
	  };
	  $opt_in = $subject_id;
      }
      $endpoint_template = '/groups/' . $opt_in . '/projects';
  }
  if ( $opt_in ) {
     $endpoint_template = '/groups/' . $opt_in . '/projects';
  }
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'group' => $opt_group,
                                                                  'in' => $opt_in,
                                                                  '' => $opt_,
                                                                  'project' => $opt_project,
                                                                  'project_id' => $opt_project_id,
                                                                 'subject_id' => $subject_id,});
  my $params = $gitlab->build_params({ 'help' => $opt_help,
                                                                  'group' => $opt_group,
                                                                  'in' => $opt_in,
                                                                  '' => $opt_,
                                                                  'project' => $opt_project,
                                                                  'project_id' => $opt_project_id,
                                                                 'subject_id' => $subject_id,});								 
  
  
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  
  

  {
    local $Data::Dumper::Terse = 1;
    print $opt_json ? to_json( $_ ) : Dumper( $result_obj ) . "\n"; 
  }
  print "**** UNIMPLEMENTED: " . 'command transfer_project in GitLabCLI::Groups' . "\n";

  return $stat;
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
