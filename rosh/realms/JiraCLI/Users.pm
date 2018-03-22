package JiraCLI::Users;

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

use  JiraCLI::Users_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsusr', 'cmd_lsusr' ],
     ['descusr', 'cmd_descusr' ], 
     ['mkusr', 'cmd_mkusr' ], 
     ['rmusr', 'cmd_rmusr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Users_IF::gcli_lsusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
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
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/user/search?maxResults=10000';
  if ( @ARGV ) {
      $endpoint .= '&username=' . $ARGV[0];
  } else { 
      $endpoint .= '&username=.';
  }
      
  my @results;								 
  @results = @{ $jira->rest_get_list( $endpoint ) }; 
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { exists $_->{ 'name' } ? "$_->{ 'displayName' }\t ($_->{ 'name' })" : "($_->{ 'name' })" } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Users_IF::gcli_descusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
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
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user-id argument.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/user?username=' . $subject . '&expand=groups,applicationRoles';
  my @results;								 

  my $result_obj = $jira->rest_get_single( $endpoint );
  $this->condense_user( $result_obj );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "User: %F:key\nName: %F:displayName\nGroups: %F:groups\nApplications: %F:applicationRoles";
      print join( "\n", map { $jira->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub condense_user {
    my ( $this, $user ) = @_;

    $user->{ 'groups' } = [ map { $_->{ 'name' } } @{ $user->{ 'groups' }->{ 'items' } } ];
    $user->{ 'applicationRoles' } = [ map { $_->{ 'name' } } @{ $user->{ 'applicationRoles' }->{ 'items' } } ];

    return;
}

sub cmd_mkusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Users_IF::gcli_mkusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_prototype, $opt_groups,  );
  GetOptions (
      'help' => \$opt_help,
      'proto=s' => \$opt_prototype,
      'groups=s' => \$opt_groups,
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
      return "Error: Missing user argument.\n";
  }
  my $subject_id;
  my ( $verify_user, $proto_user );
  try {
      $verify_user = $jira->rest_get_single( '/user?username=' . $subject . '&expand=groups,applicationRoles' );
      $this->condense_user( $verify_user );
  } catch {
      die "No such user \"$subject\": $_\n";
  };
  if ( $opt_groups ) {
      $opt_groups = [ split( ',', $opt_groups ) ];
  }
  if ( $opt_prototype ) {
      if ( $opt_groups ) {
	  die "Cannot use option --groups and --proto together.\n";
      }
      try {
	  $proto_user = $jira->rest_get_single( '/user?username=' . $opt_prototype . '&expand=groups,applicationRoles' );
	  $this->condense_user( $proto_user );
      } catch {
	  die "Protoype user \"$opt_prototype\" is unknown: $_\n";
      };
      $opt_groups = $proto_user->{ 'groups' };
  }

  if ( $opt_prototype ) {
      # remove all current group memberships
      foreach my $grp ( @{ $verify_user->{ 'groups' } } ) {
	  my $endpoint = '/group/user?groupname=';
	  my @results;								 
	  my $result_obj;
	  try {
	      $result_obj = $jira->rest_delete( $endpoint . $grp . '&username=' . $verify_user->{ 'key' } );
	  } catch {
	      warn "* Warning: Could not clear membership in group $grp - possibly managed in r/o directory (Crowd?)\n";
	  };
      }
  }

  my $endpoint = '/user';
  my $params = {
      'name' => $subject
  };
  my @results;								 

  foreach my $grp ( @{ $opt_groups } ) {
      my $endpoint = '/group/user?groupname=' . $grp;

      my $result_obj;
      try {
	  $result_obj = $jira->rest_post( $endpoint, $params );
      } catch {
	  die "update user failed: $_.\n";
      };
      my $result = from_json( $result_obj->{ 'body' } );
      push( @results, $result );
  }

  print ucfirst "update" . "d group memberships of user $subject: " . join( ", ", @{ $opt_groups } ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_rmusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Users_IF::gcli_rmusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_force,  );
  GetOptions (
      'help' => \$opt_help,
      'force|f' => \$opt_force,
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
      return "Error: Missing user argument.\n";
  }

  my $confirm_users = "user $subject";
  if ( @ARGV ) {
      my $last = pop @ARGV;
      $confirm_users = "users $subject, " . join( ', ', @ARGV ) . " and $last";
  }
  if ( not ( $opt_force or $this->confirm( "Really remove $confirm_users from Jira ?", 'no' ))) {
      $this->print( ucfirst "$confirm_users not removed.\n" );
      return $stat;
  }

  my $endpoint = '/group/user?groupname=';

  my @results;
  foreach my $this_user ( $subject, @ARGV ) {
      # first get current user entry
      my $curr_user;
      try {
	  $curr_user = $jira->rest_get_single( '/user?username=' . $this_user . '&expand=groups' );
	  $this->condense_user( $curr_user );
      } catch {
	  warn "User \"$this_user\" is unknown: $_\n";
	  $curr_user = '';
      };
      next
	  unless ( $curr_user );
      
      my $groups = $curr_user->{ 'groups' };
      my $result_obj;
      foreach my $grp ( @{ $groups } ) {
	  my $bail_out = 0;
	  try {
	      $result_obj = $jira->rest_delete( $endpoint . $grp . '&username=' . $curr_user->{ 'key' } );
	  } catch {
	      warn "Could not remove $this_user from group $grp - possibly managed in r/o directory (Crowd?); $_\n";
	      $bail_out = 1;
	  };
	  last
	      if ( $bail_out );
	  push( @results, $result_obj );
      }
  }
  $confirm_users =~ s/users? //;
  print ucfirst "Suspended $confirm_users from Jira.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


1;
