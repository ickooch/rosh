package GitLabCLI::Users;

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

use  GitLabCLI::Users_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsusr', 'cmd_lsusr' ],
     ['descusr', 'cmd_descusr' ], 
     ['addusr', 'cmd_addusr' ], 
     ['rmusr', 'cmd_rmusr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsusr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Users_IF::gcli_lsusr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_format, $opt_short, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
      'short|s' => \$opt_short,
      'in=s' => \$opt_in,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  my ( $project_id, $group_id );
  if ( $opt_in ) {
      try {
	  $project_id = $gitlab->get_project_id( $opt_in );
      };
      $project_id or try {
	  $group_id = $gitlab->get_group_id( $opt_in, 'exact-match' => 1 );
      } catch {
	  chomp $_;
	  die "** Error: Unknown project or group \"$opt_in\": $_\n";
      };
  }

  # verify project id
  if ( $project_id ) {
      $project_id = $this->assert_project_id( $project_id );
  }
  
  my $endpoint;
  if ( $project_id ) {
      $endpoint = "/projects/$project_id/members";
  } elsif ( $group_id ) {
      $endpoint = "/groups/$group_id/members";
  } else {
      $endpoint = '/users';
      if ( @ARGV ) {
	  $endpoint .= '?search=' . shift @ARGV;
      }
  }
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { exists $_->{ 'name' } ? "$_->{ 'name' }\t ($_->{ 'username' } / $_->{ 'id' })" : "($_->{ 'id' })" } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descusr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Users_IF::gcli_descusr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_format, $opt_short,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
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
      return "Error: Missing user argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/users/' . $subject;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      # TODO / FIXME - define custom normal format
      my $norm_format = "%n (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }
  
  return $stat;
}

sub cmd_addusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Users_IF::gcli_addusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_to_target, $opt_perm,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'to=s' => \$opt_to_target,
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
  my @users = @ARGV;

  die "** Error: No group or project specified to which the user(s) shall be added.\n"
      if ( not $opt_to_target );

  my ( $project_id, $group_id );
  try {
      $project_id = $gitlab->get_project_id( $opt_to_target );
  };
  $project_id or try {
      $group_id = $gitlab->get_group_id( $opt_to_target, 'exact-match' => 1 );
  } catch {
      chomp $_;
      die "** Error: Unknown project or group \"$opt_to_target\": $_\n";
  };
  
  if ( $project_id ) {
      try {
	  use GitLabCLI::Projects;
	  @ARGV = ( $opt_to_target );
	  if ( $opt_perm ) {
	      push( @ARGV, ( '--as', $opt_perm ) );
	  }
	  push( @ARGV, $subject, @users );
	  GitLabCLI::Projects->new( $this->frame() )->cmd_addprj_members();
      } catch {
	  die "** Error: Could not dispatch call to 'add project member --as $opt_perm $opt_to_target $subject': $_\n";
      };
  } elsif ( $group_id ) {
      try {
	  use GitLabCLI::Groups;
	  @ARGV = ( $opt_to_target );
	  if ( $opt_perm ) {
	      push( @ARGV, ( '--as', $opt_perm ) );
	  }
	  push( @ARGV, $subject, @users );
	  GitLabCLI::Groups->new( $this->frame() )->cmd_addgrp_members();
      } catch {
	  die "** Error: Could not dispatch call to 'add group member --as $opt_perm $opt_to_target $subject': $_\n";
      };
  }

  return $stat;
}

sub cmd_rmusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Users_IF::gcli_rmusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_from_original,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'from=s' => \$opt_from_original,
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
  my @users = @ARGV;

  die "** Error: No group or project specified from which the user(s) shall be removed.\n"
      if ( not $opt_from_original );

  my ( $project_id, $group_id );
  try {
      $project_id = $gitlab->get_project_id( $opt_from_original );
  };
  $project_id or try {
      $group_id = $gitlab->get_group_id( $opt_from_original, 'exact-match' => 1 );
  } catch {
      chomp $_;
      die "** Error: Unknown project or group \"$opt_from_original\": $_\n";
  };
  
  if ( $project_id ) {
      try {
	  use GitLabCLI::Projects;
	  @ARGV = ( $opt_from_original );
	  push( @ARGV, $subject, @users );
	  GitLabCLI::Projects->new( $this->frame() )->cmd_rmprj_members();
      } catch {
	  die "** Error: Could not dispatch call to 'remove project member $opt_from_original $subject': $_\n";
      };
  } elsif ( $group_id ) {
      try {
	  use GitLabCLI::Groups;
	  @ARGV = ( $opt_from_original );
	  push( @ARGV, $subject, @users );
	  GitLabCLI::Groups->new( $this->frame() )->cmd_rmgrp_members();
      } catch {
	  die "** Error: Could not dispatch call to 'remove group member $opt_from_original $subject': $_\n";
      };
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

1;
