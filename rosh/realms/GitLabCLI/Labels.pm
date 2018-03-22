package GitLabCLI::Labels;

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

use  GitLabCLI::Labels_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lslbl', 'cmd_lslbl' ],
     ['desclbl', 'cmd_desclbl' ],
     ['mklbl', 'cmd_mklbl' ],
     ['dellbl', 'cmd_dellbl' ], 
		 ]);
  
  return $this;
}


sub cmd_lslbl {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Labels_IF::gcli_lslbl_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lslbl ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_limit, $opt_short, $opt_format, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'limit|max=i' => \$opt_limit,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
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
      die "list label requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  my $endpoint = '/projects/:id/labels';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

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

sub cmd_desclbl {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Labels_IF::gcli_desclbl_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_desclbl ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
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
      return "Error: Missing label argument.\n";
  }

  my $filter_re;
  $filter_re = '^(' . $subject . ')';

  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "** Error: Describe label requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/labels';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @results;								 

  my @results = @{ $gitlab->rest_get_list( $endpoint ) };
  @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)\nDescription: %d\nColor: %F:color\nPriority: %F:priority";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mklbl {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Labels_IF::gcli_mklbl_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mklbl ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_desc, $opt_color,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      'color|col=s' => \$opt_color,
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
      return "Error: Missing label argument.\n";
  }
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add label requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/labels';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  my $params = {
      'name' => $subject,
      'color' => '#FFAABB'
  };
  if ( $opt_desc ) {
      $params->{ 'description' } = $opt_desc;
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "add label failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d label " . join( "\n    ", map { $gitlab->substitute_format( '%n', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_dellbl {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Labels_IF::gcli_dellbl_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_dellbl ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_in,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      'in=s' => \$opt_in,
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
      return "Error: Missing label argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'label', $subject );
  } catch {
      die "Cannot determine id for label object \"$subject\".\n";
  };
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove label requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  if ( not ( $opt_force or $this->confirm( "Really remove label $subject ?", 'no' ))) {
      $this->print( ucfirst "label $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/labels';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such label: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d label " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command dellbl in GitLabCLI::Labels' . "\n";

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
