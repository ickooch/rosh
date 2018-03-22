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
     ['addnod', 'cmd_addnod' ],
     ['deletenod', 'cmd_deletenod' ],
     ['startnod', 'cmd_startnod' ],
     ['stopnod', 'cmd_stopnod' ], 
		 ]);
  
  return $this;
}


sub cmd_lsnod {
  my $stat = "";

  my $this = shift;

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
  @results = @{ $aws->rest_get_list( $endpoint ) }; 
  #
  # We get "Reservations" here, that contain the actual instances.
  # Since we're not interested in the Reservation objects, we pluck the
  # instances out of the Reservations objects.
  #
  @results = map { @{ $_->{ 'Instances' } } } @results;

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
  my $stat = "";

  my $this = shift;

  my $long_usage = AwsCLI::Nodes_IF::awscli_descnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descnod ';
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
      return "Error: Missing node argument.\n";
  }
  push( @ARGV, '-l' );
  
  return $this->cmd_lsnod();
}

sub cmd_addnod {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = AwsCLI::Nodes_IF::awscli_addnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addnod ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_desc,  );
  GetOptions (
      'help' => \$opt_help,
      'desc|d=s' => \$opt_desc,
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
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $aws->assert_object_id( 'node', $subject );
  } catch {
      die "Cannot determine id for node object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'run-instances';

  my $params = { 'help' => $opt_help,
                'desc' => $opt_desc,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $aws->rest_post( $endpoint, $params );
  } catch {
      die "add node failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d node " . join( "\n    ", map { $aws->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command addnod in AwsCLI::Nodes' . "\n";

  return $stat;
}

sub cmd_deletenod {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

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
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $aws->assert_object_id( 'node', $subject );
  } catch {
      die "Cannot determine id for node object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really delete node $subject ?", 'no' ))) {
      $this->print( ucfirst "node $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/usermanagement/1/node';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $aws->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such node: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "delete" . "d node " . join( "\n    ", map { $aws->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command deletenod in AwsCLI::Nodes' . "\n";

  return $stat;
}

sub cmd_startnod {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = AwsCLI::Nodes_IF::awscli_startnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_startnod ';
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
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $aws->assert_object_id( 'node', $subject );
  } catch {
      die "Cannot determine id for node object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'start-instance';

  my $params = { 'help' => $opt_help,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $aws->rest_post( $endpoint, $params );
  } catch {
      die "start node failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "start" . "d node " . join( "\n    ", map { $aws->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command startnod in AwsCLI::Nodes' . "\n";

  return $stat;
}

sub cmd_stopnod {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = AwsCLI::Nodes_IF::awscli_stopnod_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_stopnod ';
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
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $aws->assert_object_id( 'node', $subject );
  } catch {
      die "Cannot determine id for node object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really stop node $subject ?", 'no' ))) {
      $this->print( ucfirst "node $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = 'stop-instance';

  my $params = { 'force' => $opt_force,
                'help' => $opt_help,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $aws->rest_post( $endpoint, $params );
  } catch {
      die "stop node failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "stop" . "d node " . join( "\n    ", map { $aws->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command stopnod in AwsCLI::Nodes' . "\n";

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $aws = $this->preference( 'aws_connector' );

    my $project_id;
    try {
	$project_id = $aws->get_project_id( $pid );
    } catch {
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

1;
