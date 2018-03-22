package AwsCLI::Subnets;

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

use  AwsCLI::Subnets_IF;

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
     ['lsnet', 'cmd_lsnet' ],
     ['descnet', 'cmd_descnet' ], 
		 ]);
  
  return $this;
}


sub cmd_lsnet {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Subnets_IF::awscli_lsnet_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsnet ';
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

  my $endpoint = 'ec2 describe-subnets';

  my @results;								 
  @results = @{ $aws->rest_get_list( $endpoint ) }; 

  foreach my $subnet ( @results ) {
      try_set_name( $subnet );
  }

  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/  or $_->{ 'SubnetId' } =~ m/${filter_re}/ } @results;
  }
  @results = sort { $a->{ 'name' } cmp $b->{ 'name' } } @results;
  my $maxnamelen = $this->max_strlen( [ map { $_->{ 'name' } } @results ] );
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'SubnetId' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:name(' . $maxnamelen . ') (%F:SubnetId)';
      print join( "\n", map { $aws->substitute_format( $norm_format, $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

# some AWS objects do not have proper (intelligible) names but are
# tagged by the user with 'Name' tags.
# If such a tag is found in the passed object, a 'name' attribute
# is created in the object.
#
sub try_set_name {
    my $obj = shift;

    if ( exists $obj->{ 'Tags' } and grep { $_->{ 'Key' } eq 'Name' } @{ $obj->{ 'Tags' } } ) {
	$obj->{ 'name' } = ( grep { $_->{ 'Key' } eq 'Name' } @{ $obj->{ 'Tags' } } )[ 0 ]->{ 'Value' };
    } else {
	$obj->{ 'name' } = '*unnamed*';
    }
}
    
sub cmd_descnet {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Subnets_IF::awscli_descnet_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descnet ';
      print join(', ', @ARGV ); print "\n";
  }
  my $opt_help;
  GetOptions (
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }

  # initial option checking here
  my $subject = $ARGV[ 0 ];
  if ( not $subject ) {
      return "Error: Missing subnet argument.\n";
  }
  push( @ARGV, '-l' );
  
  return $this->cmd_lsnet();
}


1;
