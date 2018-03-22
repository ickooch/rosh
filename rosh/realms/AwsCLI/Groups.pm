package AwsCLI::Groups;

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

use  AwsCLI::Groups_IF;

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
     ['lsgrp', 'cmd_lsgrp' ], 
     ['descgrp', 'cmd_descgrp' ], 
		 ]);
  
  return $this;
}

sub cmd_lsgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Groups_IF::awscli_lsgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsgrp ';
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

  my $endpoint = 'iam list-groups';

  my @results;								 
  @results = @{ $aws->rest_get_list( $endpoint ) };
  my $maxnamelen = $this->max_strlen( [ map { $_->{ 'GroupName' } } @results ] );
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'GroupId' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:GroupName(' . $maxnamelen . ') (%F:GroupId)';
      print join( "\n", map { $aws->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


sub cmd_descgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Groups_IF::awscli_descgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descgrp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_short, $opt_long, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'short|s' => \$opt_short,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
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
      return "Error: Missing group argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = 'iam get-group --group-name ' . $subject;

  my @results;								 

  my $result_obj = $aws->rest_get_single( $endpoint );
  my $group_policies = $aws->rest_get_list( 'iam list-group-policies --group-name ' . $subject );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:Group.GroupName (Id: %F:Group.GroupId)";
      print $aws->substitute_format( $norm_format, $result_obj  ) .  "\n";
      print "  Policies:\n    " . ( scalar( @{ $group_policies } ) ? 
	  join( "\n    ", @{ $group_policies } ) : 
	  '*no attached group policies*' ) . "\n\n";
      print "  Members:\n    " . join( "\n    ", map { $_->{ 'UserName' } } @{ $result_obj->{ 'Users' } } ) . "\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

1;
