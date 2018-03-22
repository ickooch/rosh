package AwsCLI::Vpcs;

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

use  AwsCLI::Vpcs_IF;

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
     ['lsvpc', 'cmd_lsvpc' ],
     ['descvpc', 'cmd_descvpc' ], 
		 ]);
  
  return $this;
}


sub cmd_lsvpc {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Vpcs_IF::awscli_lsvpc_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsvpc ';
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


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'ec2 describe-vpcs';

  my @results;								 
  @results = @{ $aws->rest_get_list( $endpoint ) }; 

  foreach my $subnet ( @results ) {
      try_set_name( $subnet );
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/  or $_->{ 'VpcId' } =~ m/${filter_re}/ } @results;
  }
  my $maxnamelen = $this->max_strlen( [ map { $_->{ 'name' } } @results ] );

  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'VpcId' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:name(' . $maxnamelen . ') (%F:VpcId)';
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
    
sub cmd_descvpc {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = AwsCLI::Vpcs_IF::awscli_descvpc_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descvpc ';
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
      return "Error: Missing vpc argument.\n";
  }
  push( @ARGV, '-l' );
  
  return $this->cmd_lsvpc();
}


1;
