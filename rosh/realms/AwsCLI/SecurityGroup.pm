package AwsCLI::SecurityGroup;

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

use  AwsCLI::SecurityGroup_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lssecg', 'cmd_lssecg' ],
     ['descsecg', 'cmd_descsecg' ], 
		 ]);
  
  return $this;
}


sub cmd_lssecg {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::SecurityGroup_IF::awscli_lssecg_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lssecg ';
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
  my $endpoint = 'ec2 describe-security-groups';


  my @results;								 
  @results = @{ $aws->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'GroupName' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:GroupName (id: %F:GroupId) in VPC %F:VpcId';
      print join( "\n", map { $aws->substitute_format( $norm_format, $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub desc_item {
  my ( $this, $item ) = @_;

  my $aws = $this->preference( 'aws_connector' );

  my $norm_format = "Security Group: %F:GroupName (id: %F:GroupId) in VPC %F:VpcId
  \"%F:Description\"\n";
  my $perm_format = "  %F:IpProtocol Port(s) %F:Ports ok from %F:Targets\n";
  my $itm_desc = $aws->substitute_format( $norm_format, $item );
  foreach my $perm ( @{ $item->{ 'IpPermissions' } } ) {
    my $ports = $perm->{ 'FromPort' };
    $ports .= " - $perm->{ 'ToPort' }"
      if ( $perm->{ 'FromPort' } != $perm->{ 'ToPort' } );
    $perm->{ 'Ports' } = $ports;
    $perm->{ 'Targets' } = join( ', ', map { $_->{ 'CidrIp' } } @{ $perm->{ 'IpRanges' } } );
    $itm_desc .= $aws->substitute_format( $perm_format, $perm );
  }

  print $itm_desc . "\n";
  
  return $this;
}


sub cmd_descsecg {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::SecurityGroup_IF::awscli_descsecg_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descsecg ';
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
      return "Error: Missing sgroup argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = 'ec2 describe-security-groups';

  my @results;								 

  my $result_obj;
  try {
    $result_obj = $aws->rest_get_single( "$endpoint --group-ids $subject" );
  };
  if ( not ref $result_obj ) {
    try {
      $result_obj = $aws->rest_get_single( "$endpoint --group-names $subject" );
    };
  }
  if ( not ref $result_obj ) {
    die "** Error: invalid secutiy group identifier '$subject'.\n";
  }
  $result_obj = $result_obj->{ 'SecurityGroups' }->[ 0 ];
    
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
    $this->desc_item( $result_obj );
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


1;
