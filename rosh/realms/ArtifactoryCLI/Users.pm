package ArtifactoryCLI::Users;

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

use  ArtifactoryCLI::Users_IF;

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

  my $long_usage = ArtifactoryCLI::Users_IF::atfcli_lsusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsusr ';
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

  my $artifactory = $this->preference( 'atf_connector' );
  if ( not $artifactory->is_admin() ) {
      die "The 'list users' command requires admin privileges.\n";
  }
  # initial option checking here
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/security/users';

  my @results;								 
  @results = @{ $artifactory->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  @results = sort { $a->{ 'name' } cmp $b->{ 'name' } } @results;
          
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:name (authenticated via %F:realm)';
      print join( "\n", map { $artifactory->substitute_format( $norm_format, $_ ) } @results ) . "\n";
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

  my $long_usage = ArtifactoryCLI::Users_IF::atfcli_descusr_usage();
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

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing user argument(s).\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/security/users';
  my @results;								 

  foreach my $subject ( @ARGV ) {
      my $result_obj = $artifactory->rest_get_single( $endpoint . '/' . $subject );
      push( @results, $result_obj );
  }

  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n\nLast logon: %F:lastLoggedIn (via %F:realm)
Email: %F:email
Member of: %F:groups
Is admin: %F:admin";
      print join( "\n\n", map { $artifactory->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mkusr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Users_IF::atfcli_mkusr_usage();
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

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'user', $subject );
  } catch {
      die "Cannot determine id for user object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/user';

  my $params = { 'help' => $opt_help,
                'prototype' => $opt_prototype,
                'groups' => $opt_groups,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_post( $endpoint, $params );
  } catch {
      die "update user failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "update" . "d user " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command mkusr in ArtifactoryCLI::Users' . "\n";

  return $stat;
}

sub cmd_rmusr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Users_IF::atfcli_rmusr_usage();
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

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'user', $subject );
  } catch {
      die "Cannot determine id for user object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really remove user $subject ?", 'no' ))) {
      $this->print( ucfirst "user $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/group/user?groupname=';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such user: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d user " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command rmusr in ArtifactoryCLI::Users' . "\n";

  return $stat;
}


1;
