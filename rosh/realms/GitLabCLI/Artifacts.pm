package GitLabCLI::Artifacts;

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
use GitLabCLI::Artifacts_IF;

use File::Temp qw/ tempfile tempdir /;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use URL::Encode::XS qw( url_encode url_decode );
use Time::localtime;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsatf', 'cmd_lsatf' ],
     ['getatf', 'cmd_getatf' ], 
		 ]);
  
  return $this;
}


sub cmd_lsatf {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Artifacts_IF::gcli_lsatf_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsatf ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_job, $opt_ref, $opt_long, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'job=s' => \$opt_job,
      'ref=s' => \$opt_ref,
      'long|l' => \$opt_long,
      'in=s' => \$opt_in,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  if ( not $opt_job ) {
      die "No job was given. You must specify a job id or name via option '--job <job-id>'.\n";
  }
  $opt_job =~ s/"//g; # Job names may contain spaces, so it may be quoted.

  my $job_name_given = ( $opt_job !~ m/^\d+$/ ); # if opt_job is all digits, it's a job id - otherwise job name
  if ( $job_name_given ) {
      die "Retrieving artifacts from jobname requires a branch name. Please specify branch with '--ref <branch>' option.\n"
	  unless ( $opt_ref );
      $opt_job = url_encode( $opt_job );
  }
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list artifact requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint;

  if ( $opt_ref ) {
      $endpoint = '/projects/' . $project_id . '/jobs/artifacts/' . 
	  $opt_ref . '/download?job=' . $opt_job;
  } else {
      $endpoint = '/projects/' . $project_id . '/jobs/' . $opt_job . '/artifacts';
  }

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );

  my ($atf_fh, $atf_filename) = tempfile();
  binmode $atf_fh;
  print $atf_fh $result_obj;
  close $atf_fh;

  my $zip = Archive::Zip->new();
  unless ( $zip->read( $atf_filename ) == AZ_OK ) {
      die "read error - cannot read temporary artifacts file $atf_filename: $!\n";
  }

  my @results;
  if ( $opt_long ) {
      @results = $zip->members();
      if ( $filter_re ) {
	  @results = grep { $_->fileName() =~ m/${filter_re}/ } @results;
      }
      print "Artifacts:\n  " . join( "\n  ", map { sprintf( "%8s %s %s", 
							    $_->uncompressedSize(),
							    ctime($_->lastModTime()) ,
							    $_->fileName()) } @results ) . "\n";
  } else {
      @results = $zip->memberNames();
      if ( $filter_re ) {
	  @results = grep { $_ =~ m/${filter_re}/ } @results;
      }
      
      print "Artifacts:\n  " . join( "\n  ", @results ) . "\n";
  }
  unlink $atf_filename;
      
  return $stat;
}

sub cmd_getatf {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Artifacts_IF::gcli_getatf_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_getatf ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_job, $opt_long, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'job=s' => \$opt_job,
      'long|l' => \$opt_long,
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
      return "Error: Missing artifact argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'artifact', $subject );
  } catch {
      die "Cannot determine id for artifact object \"$subject\".\n";
  };
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "get artifact requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/jobs/:job_id/artifacts';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
if ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      # TODO / FIXME - define custom normal format
      my $norm_format = "%n (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command getatf in GitLabCLI::Artifacts' . "\n";

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
