package JiraCLI::Boards;

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

use  JiraCLI::Boards_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsbrd', 'cmd_lsbrd' ],
     ['descbrd', 'cmd_descbrd' ],
     ['addbrd', 'cmd_addbrd' ],
     ['deletebrd', 'cmd_deletebrd' ],
     ['editbrd', 'cmd_editbrd' ], 
		 ]);
  
  return $this;
}


sub cmd_lsbrd {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Boards_IF::gcli_lsbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'favorite|fave' => \$opt_fave,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $filter_re;
  my $board_id;
  if ( @ARGV ) {
      try {
	  $board_id= $jira->get_board_id( @ARGV[ 0 ] );
      } catch {
	  $filter_re = '(' . join( '|', @ARGV ) . ')';
      };
      if ( $board_id ) {
	  # if "list board <board-id>" is given, and "board_id" is an id or
	  # precise match, we dispatch the command to "list issues --on-board <id>"
	  my $did_it = 0;
	  try {
	      use JiraCLI::Issues;
	      @ARGV = ( '--on', $board_id );
	      JiraCLI::Issues::cmd_lsiss( $this );
	      $did_it = 1;
	  } catch {
	      print "Warning: Could not dispatch call to 'list issues --on-board $board_id': $_\n";
	      print "  => argument $board_id is ignored.\n";
	  };
	  return $stat
	      if ( $did_it );
      }
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/board';

  my @results;								 
  $jira->load_base_url( '/agile/1.0' );
  try {
      @results = @{ $jira->rest_get_single( $endpoint . '?maxResults=10000' )->{ 'values' } };
  } catch {
      die "Failed to request list of boards: $_\n";
  };
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map {  $jira->substitute_format( "%n\t%F:type (%F:id)", $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descbrd {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Boards_IF::gcli_descbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
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
      return "Error: Missing filter ID.\n";
  }
  if ( not $subject =~ m/^\d+$/ ) {
      return "Error: Invalid filter \"$subject\" - please use all numeric board id.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/board/' . $subject . '/configuration';
  my @results;								 

  my $result_obj = $jira->load_base_url( '/agile/1.0' )->rest_get_single( $endpoint );
  my $status_map = {};
  foreach my $this_state ( @{ $jira->rest_get_list( '/status' ) } ) {
      $status_map->{ $this_state->{ 'id' } } = $this_state->{ 'name' };
  }
  foreach my $colspec ( @{ $result_obj->{ 'columnConfig' }->{ 'columns' } } ) {
      foreach my $col_state ( @{ $colspec->{ 'statuses' } } ) {
	  $col_state->{ 'name' } = $status_map->{  $col_state->{ 'id' } };
      }
  }
  my $flt;
  try {
      my $flt = $result_obj->{ 'filter' }->{ 'id' };
      $flt = $jira->rest_get_single( '/filter/' . $flt );
      $result_obj->{ 'filter' } = $flt;
  } catch {
      die "Error: Cannot get filter definition for board: $_\n";
  };

  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%i: %n (%F:type)\n\nAdmin: %F:filter.owner\n\nFilter: %F:filter.name\n  jql: %F:filter.jql\n";
      print $jira->substitute_format( $norm_format, $result_obj ) . "\n";
      print "Columns:\n";
      foreach my $coldef ( @{ $result_obj->{ 'columnConfig' }->{ 'columns' } } ) {
	  print "  $coldef->{ 'name' } (states: " . 
	      join( ', ', map { $_->{ 'name' } } @{ $coldef->{ 'statuses' } } ) .
	      ")\n";
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addbrd {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = JiraCLI::Boards_IF::gcli_addbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_jql, $opt_desc, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'jql=s' => \$opt_jql,
      'desc|d=s' => \$opt_desc,
      'favorite|fave' => \$opt_fave,
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
      return "Error: Missing filter argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $jira->assert_object_id( 'filter', $subject );
  } catch {
      die "Cannot determine id for filter object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/rest/agile/1.0/board';

  my $params = { 'help' => $opt_help,
                'name' => $opt_name,
                'jql' => $opt_jql,
                'desc' => $opt_desc,
                'fave' => $opt_fave,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      die "add filter failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d filter " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command addbrd in JiraCLI::Boards' . "\n";

  return $stat;
}

sub cmd_deletebrd {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Boards_IF::gcli_deletebrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deletebrd ';
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing Board argument(s).\n";
  }
  my %bmap;
  my @delete_boards;
  foreach my $bid ( @ARGV ) {
      my $result_obj; 
      try {
	  $result_obj = $jira->load_base_url( '/agile/1.0' )->rest_get_single( '/board/' . $bid . '/configuration' );
	  $bmap{ $bid } = "$result_obj->{ 'name' } ($result_obj->{ 'type' })";
	  push( @delete_boards, $bid );
      } catch {
	  chomp $_;
	  print "No such board $bid: $_.\n";
      }
  }
  if ( @delete_boards ) {
      if ( not ( $opt_force or $this->confirm( "Really delete these Boards:\n  " . 
					       join( "\n  ", map { "$_ - $bmap{ $_ }" } @delete_boards ) . " ?", 'no' ))) {
	  $this->print( ucfirst "Boards not deleted.\n" );
	  return $stat;
      }
  } else {
      print "No boards to delete.\n";
      return $stat;
  }

  my $endpoint = '/board/';
  my @results;								 

  foreach my $subject ( @delete_boards ) {
      my $result_obj;
      try {
	  $result_obj = $jira->load_base_url( '/agile/1.0' )->rest_delete( $endpoint . $subject );
      } catch {
	  print "Could not delete Board $subject: $_\n";
	  next;
      };
      
      push( @results, $bmap{ $subject } );
  }
  if ( @results == 1 ) {
      print "Deleted board " . $results[0] . "\n";
  } elsif ( @results > 1 ) {
      print "Deleted boards:\n  " . join( "\n  ", @results ) . "\n";
  } else {
      print "Nothing deleted.\n";
  }
#  print ucfirst "delete" . "d filter " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_editbrd {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = JiraCLI::Boards_IF::gcli_editbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_desc, $opt_jql, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'desc|d=s' => \$opt_desc,
      'jql=s' => \$opt_jql,
      'favorite|fave' => \$opt_fave,
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
      return "Error: Missing filter argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $jira->assert_object_id( 'filter', $subject );
  } catch {
      die "Cannot determine id for filter object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/rest/api/2/filter/{id}';

  my $params = { 'help' => $opt_help,
                'name' => $opt_name,
                'desc' => $opt_desc,
                'jql' => $opt_jql,
                'fave' => $opt_fave,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "edit filter failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "edit" . "d filter " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editbrd in JiraCLI::Boards' . "\n";

  return $stat;
}

1;
