package AwsCLI::Nodes;

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

use  AwsCLI::Nodes_IF;

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
     ['lsnod', 'cmd_lsnod' ],
     ['descnod', 'cmd_descnod' ],
     ['consolenod', 'cmd_consolenod' ],
     ['addnod', 'cmd_addnod' ],
     ['deletenod', 'cmd_deletenod' ],
     ['startnod', 'cmd_startnod' ],
     ['stopnod', 'cmd_stopnod' ], 
		 ]);
  
  return $this;
}


sub cmd_lsnod {
  my $stat = "";

  my ( $this, @instance_ids ) = @_;

  my $long_usage = AwsCLI::Nodes_IF::awscli_lsnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsnod ';
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
  
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = 'ec2 describe-instances';


  my @results;
  try {
    @results = @{ $aws->rest_get_list( $endpoint . ( @instance_ids ? ' --instance-ids ' . join( ' ', @instance_ids ) : '' ) ) };
  } catch {
    chomp $_;
    die "** Error: $_\n";
  };
  #
  # We get "Reservations" here, that contain the actual instances.
  # Since we're not interested in the Reservation objects, we pluck the
  # instances out of the Reservations objects.
  #
  @results = map { @{ $_->{ 'Instances' } } } @results;

  if ( ( caller() )[ 0 ] ne 'AppRegister' ) {
    return \@results;
  }
  
  # the instances have no names, but names are often represented as a tag, so look for it
  foreach my $inst ( @results ) {
      if ( exists $inst->{ 'Tags' } and grep { $_->{ 'Key' } eq 'Name' } @{ $inst->{ 'Tags' } } ) {
	  $inst->{ 'name' } = ( grep { $_->{ 'Key' } eq 'Name' } @{ $inst->{ 'Tags' } } )[ 0 ]->{ 'Value' };
      } else {
	  $inst->{ 'name' } = '*unnamed*';
      }
  }
  
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/  or $_->{ 'InstanceId' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $aws->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'InstanceId' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:InstanceId(20) %n %F:InstanceType %F:State.Name";
      print join( "\n", map { $aws->substitute_format( $norm_format, $_ ) } 
		  sort { $a->{ 'name' } cmp $b->{ 'name' } } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descnod {
  my ( $this, $nodeid ) = @_;
  
  my $stat = "";

  my $long_usage = AwsCLI::Nodes_IF::awscli_descnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descnod ';
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

  # initial option checking here
  my $subject = $ARGV[ 0 ];
  $subject ||= $nodeid;
  if ( not $subject ) {
      return "Error: Missing node argument.\n";
  }
  push( @ARGV, '-l' );
  
  my $results;
  try {
    $results = $this->cmd_lsnod( $subject );
  } catch {
    die "** ERROR: Cannot find compute node with id '$subject'\n";
  };

  my $nodeinfo = $results->[ 0 ];
  if ( $nodeid ) { # we've been called as a subroutine, not as a command
    return $nodeinfo;
  }
  
  my $aws = $this->preference( 'aws_connector' );
  my $json = JSON->new->allow_nonref;

  if ( $opt_format ) {
      print $aws->substitute_format( $opt_format, $nodeinfo ) . "\n"; 
  } elsif ( $opt_long ) {
      print $nodeinfo->{ 'InstanceId' } . ': ' . $json->pretty->encode( $nodeinfo ) . "\n";
  } else {
    $this->desc_node( $nodeinfo );
  }

  return $stat;
}

sub desc_node {
  my ( $this, $nodeinfo ) = @_;

  my $aws = $this->preference( 'aws_connector' );

  my $norm_format_running = "Node: %F:InstanceId(20) %n %F:InstanceType %F:State.Name
  DNS (intern): %F:PrivateDnsName
  DNS (public): %F:PublicDnsName
  IP (intern): %F:PrivateIpAddress
  IP (extern): %F:PublicIpAddress
  Subnet Id: %F:SubnetId
  VPC Id: %F:VpcId
  Image-Id: %F:ImageId
  Launched on: %F:LaunchTime";
      
  my $norm_format_stopped = "Node: %F:InstanceId(20) %n %F:InstanceType %F:State.Name
  DNS (intern): %F:PrivateDnsName
  Subnet Id: %F:SubnetId
  VPC Id: %F:VpcId
  Image-Id: %F:ImageId";
      my $norm_format = ( $nodeinfo->{ 'State' }->{ 'Name' } eq 'running' ) ? $norm_format_running : $norm_format_stopped;
  print $aws->substitute_format( $norm_format, $nodeinfo ) . "\n";

  return $this;
}

sub cmd_consolenod {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_consolenod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_consolenod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help,  );
  GetOptions (
      'help' => \$opt_help,
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
      return "Error: Missing node argument.\n";
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'ec2 get-console-output --instance-id ';

  my $result_obj = $aws->rest_get_single( $endpoint  . $subject );

  print "[node $subject console on $result_obj->{ 'Timestamp' }]\n";
  print $result_obj->{ 'Output' } . "\n";

  return $stat;
}

sub cmd_addnod {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_addnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addnod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_prototype, $opt_type, $opt_wait, $opt_count, $opt_image,  );
  GetOptions (
      'help' => \$opt_help,
      'proto|like=s' => \$opt_prototype,
      'type=s' => \$opt_type,
      'wait|w' => \$opt_wait,
      'count|num|#=i' => \$opt_count,
      'image=s' => \$opt_image,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }

  # validate arguments
  my @proto_args;
  if ( $opt_prototype ) {
    my $proto_node;
    try {
      $proto_node = $this->cmd_descnod( $opt_prototype );
    } catch {
      chomp $_;
      die "** Invalid node prototype instance specified: $_.\n";
    };
    $opt_type ||= $proto_node->{ 'InstanceType' };
    $opt_image ||= $proto_node->{ 'ImageId' };
    @proto_args = ( '--subnet-id', $proto_node->{ 'SubnetId' } );
  }
  if ( $opt_count ) {
    push( @proto_args, '--count', $opt_count );
  }
  die "** Error: No image id or protoype instance specified. Need to specify a machine image.\n"
    if ( not $opt_image );

  $opt_type ||= 'm1.micro'; # the AWS default instance type

  my $json = JSON->new->allow_nonref;

  my $aws = $this->preference( 'aws_connector' );

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'ec2 run-instances';

  my @new_nodes;
  try {
    @new_nodes = @{ $aws->rest_post( "$endpoint --image-id $opt_image --instance-type $opt_type " .
				 join( ' ', @proto_args ) )->{ 'Instances' } };
  } catch {
    chomp $_;
    die "add node failed: $_.\n";
  };
  print "Added new node" . ( @new_nodes > 1 ? 's' : '' ) . ":\n";
  foreach my $node ( @new_nodes ) {
    $this->desc_node( $node );
    print "\n";
  }
  
  return $stat;
}

sub cmd_deletenod {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_deletenod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deletenod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
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
      return "Error: Missing node argument.\n";
  }
  
  if ( not ( $opt_force or $this->confirm( "Really delete node $subject ? Data stored on ephemeral storage will be lost!", 'no' ))) {
      $this->print( ucfirst "node $subject not d.\n" );
      return $stat;
  }

  my $endpoint = 'ec2 terminate-instances --instance-ids ';

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $aws->rest_delete( "$endpoint $subject" );
  } catch {
    chomp $_;
    die "** Error: delete node $subject failed: $_\n";
  };

  print "Terminated node $subject. It will remain visible for approx. 1 hour before disappearing for good.\n";
  
  return $stat;
}

sub cmd_startnod {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_startnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_startnod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_wait,  );
  GetOptions (
      'help' => \$opt_help,
      'wait|w' => \$opt_wait,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }

  # initial option checking here
  my $subject = $ARGV[ 0 ];
  if ( not $subject ) {
      return "Error: Missing node argument.\n";
  }

  my $aws = $this->preference( 'aws_connector' );

  my $endpoint = 'ec2 start-instances --instance-ids';

  my $response = $aws->rest_get_single( $endpoint . ' ' . $subject ); 
  my $nodeinfo;
  if ( $opt_wait ) {
    print "Compute node $subject started. Waiting for it to come up..\n";
    my $waitfor = 'running';
    my $timeout = 200;
    my $interval = 5;
    my $waited = 0;
    while ( $nodeinfo = $this->cmd_descnod( $subject ) and
	    ( $nodeinfo->{ 'State' }->{ 'Name' } ne $waitfor ) ) {
      if ( $waited > $timeout ) {
	die "** Error: Compute node $subject started but didn't come up.\n";
      }
      select( STDOUT );
      $| = 1;
      print "\r" . 100 x ' ' . "\r[current state is " . $nodeinfo->{ 'State' }->{ 'Name' } .
	" waiting for $waitfor ($waited)]";
      $| = 0;
      sleep( $interval );
      $waited += $interval;
    }
    print "\nCompute node $subject now up and running.\n";
    print 
  } else {
    print "Compute node $subject started, current state is '" .
      $response->{ 'StartingInstances' }->[0]->{ 'CurrentState' }->{ 'Name' } . "'.\n";
  }
  $nodeinfo = $this->cmd_descnod( $subject );
  print "Connect $subject at IP " . $nodeinfo->{ 'PublicIpAddress' } . " (" .
    $nodeinfo->{ 'PublicDnsName' } . ")\n";
    
  return $stat;
}

sub cmd_stopnod {
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_startnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_startnod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_wait, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'wait|w' => \$opt_wait,
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }

  # initial option checking here
  my $subject = $ARGV[ 0 ];
  if ( not $subject ) {
      return "Error: Missing node argument.\n";
  }

  my $aws = $this->preference( 'aws_connector' );

  my $endpoint = 'ec2 stop-instances --instance-ids';

  my $response = $aws->rest_get_single( $endpoint . ' ' . $subject ); 

  my $nodeinfo;
  if ( $opt_wait ) {
    print "Requested compute node $subject to stop. Waiting for it to come down..\n";
    my $waitfor = 'stopped';
    my $timeout = 200;
    my $interval = 5;
    my $waited = 0;
    while ( $nodeinfo = $this->cmd_descnod( $subject ) and
	    ( $nodeinfo->{ 'State' }->{ 'Name' } ne $waitfor ) ) {
      if ( $waited > $timeout ) {
	die "** Error: Requested compute node $subject to stop but doesn't go down.\n";
      }
      select( STDOUT );
      $| = 1;
      print "\r" . 100 x ' ' . "\r[current state is " . $nodeinfo->{ 'State' }->{ 'Name' } .
	" waiting for $waitfor ($waited)]";
      $| = 0;
      sleep( $interval );
      $waited += $interval;
    }
    print "\nCompute node $subject stopped.\n";
  } else {
    print "Requested compute node $subject to stop, current state is '" .
      $response->{ 'StoppingInstances' }->[0]->{ 'CurrentState' }->{ 'Name' } . "'.\n";
  }

  return $stat;
}

1;
