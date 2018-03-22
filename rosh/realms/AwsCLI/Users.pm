package AwsCLI::Users;

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

use  AwsCLI::Users_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsusr', 'cmd_lsusr' ],
     ['descusr', 'cmd_descusr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Users_IF::awscli_lsusr_usage();
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

  my $aws = $this->preference( 'aws_connector' );

  # initial option checking here
    
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = 'iam list-users';

  my @results;								 
  @results = @{ $aws->rest_get_list( $endpoint ) }; 
  my $maxnamelen = $this->max_strlen( [ map { $_->{ 'UserName' } } @results ] );
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:UserName(' . $maxnamelen . ') (%F:UserId)';
      print join( "\n", map { $aws->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
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

  my $long_usage = AwsCLI::Users_IF::awscli_descusr_usage();
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

  my $aws = $this->preference( 'aws_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing user argument.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = 'iam get-user --user-name ';

  my @results;								 

  my $result_obj = $aws->rest_get_single( $endpoint . $subject );
  my $user_policies = $aws->rest_get_list( 'iam list-user-policies --user-name ' . $subject );
  my $user_groups = $aws->rest_get_list( 'iam list-groups-for-user --user-name ' . $subject );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:User.UserName (Id: %F:User.UserId)";
      print $aws->substitute_format( $norm_format, $result_obj  ) .  "\n";
      print "  Policies:\n    " . ( scalar( @{ $user_policies } ) ? 
	  join( "\n    ", @{ $user_policies } ) : 
	  '*no attached user policies*' ) . "\n\n";
      print "  Groups:\n    " . join( "\n    ", map { $_->{ 'GroupName' } } @{ $user_groups } ) . "\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

1;
