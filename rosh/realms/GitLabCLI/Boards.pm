package GitLabCLI::Boards;

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

use  GitLabCLI::Boards_IF;

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

  my $long_usage = GitLabCLI::Boards_IF::gcli_lsbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_in, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'in=s' => \$opt_in,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "ls board requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/boards';

  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { exists $_->{ 'name' } ? "$_->{ 'name' }\t ($_->{ 'id' })" : "($_->{ 'id' })" } @results ) . "\n";
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

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Boards_IF::gcli_descbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_in, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'in=s' => \$opt_in,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing board argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'board', $subject );
  } catch {
      die "Cannot determine id for board object \"$subject\".\n";
  };
  
  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe board requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/boards/:board_id/lists';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      # TODO / FIXME - define custom normal format
      my $norm_format = "%n (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command descbrd in GitLabCLI::Boards' . "\n";

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

  my $long_usage = GitLabCLI::Boards_IF::gcli_addbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_in, $opt_desc,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing board argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'board', $subject );
  } catch {
      die "Cannot determine id for board object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add board requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/boards/:board_id/lists';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  my $params = { 'help' => $opt_help,
                'name' => $opt_name,
                'in' => $opt_in,
                'desc' => $opt_desc,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "add board failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d board " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command addbrd in GitLabCLI::Boards' . "\n";

  return $stat;
}

sub cmd_deletebrd {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Boards_IF::gcli_deletebrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deletebrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_in, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'in=s' => \$opt_in,
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing board argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'board', $subject );
  } catch {
      die "Cannot determine id for board object \"$subject\".\n";
  };
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "delete board requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  if ( not ( $opt_force or $this->confirm( "Really delete board $subject ?", 'no' ))) {
      $this->print( ucfirst "board $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/boards/:board_id/lists/:list_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such board: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "delete" . "d board " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command deletebrd in GitLabCLI::Boards' . "\n";

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

  my $long_usage = GitLabCLI::Boards_IF::gcli_editbrd_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editbrd ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_in, $opt_desc,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing board argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'board', $subject );
  } catch {
      die "Cannot determine id for board object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit board requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/boards/:board_id/lists/:list_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  my $params = { 'help' => $opt_help,
                'name' => $opt_name,
                'in' => $opt_in,
                'desc' => $opt_desc,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "edit board failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "edit" . "d board " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editbrd in GitLabCLI::Boards' . "\n";

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $project_id;
    try {
	$project_id = $gitlab->get_project_id( $pid );
    } catch {
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

1;
