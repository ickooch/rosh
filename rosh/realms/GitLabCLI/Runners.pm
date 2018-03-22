package GitLabCLI::Runners;

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

use  GitLabCLI::Runners_IF;

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
     ['lsrun', 'cmd_lsrun' ],
     ['descrun', 'cmd_descrun' ],
     ['enablerun', 'cmd_enablerun' ],
     ['disablerun', 'cmd_disablerun' ], 
     ['deleterun', 'cmd_deleterun' ], 
		 ]);
  
  return $this;
}


sub cmd_lsrun {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Runners_IF::gcli_lsrun_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsrun ';
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
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here

  # verify project id
  my $project_id;
  if ( $opt_in ) {
      $project_id = $this->assert_project_id( $opt_in );
  }
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint = '/runners';

  if ( $project_id ) {
      $endpoint = '/projects/' . $project_id . '/runners';
  }
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'description' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      # if opt_format is specified, we mighgt be interested in more than jusrt what the
      # list command returns. So we fetch all the details for each runner.
      my @enhanced_results;
      foreach my $this_result ( @results ) {
	  my $result_obj = $gitlab->rest_get_single( '/runners/' . $this_result->{ 'id' } );
	  push( @enhanced_results, $result_obj );
      }
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @enhanced_results ) . "\n"; 
  } else {
      print join( "\n", map { $gitlab->substitute_format( "%D (%i)", $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descrun {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Runners_IF::gcli_descrun_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descrun ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_show_projects,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'projects|P' => \$opt_show_projects,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing runner argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'runner', $subject );
  } catch {
      die "Cannot determine id for runner object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/runners/:runner-id';

  
  
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'long' => $opt_long,
                                                                  'short' => $opt_short,
                                                                  'format' => $opt_format,
                                                                  'show_projects' => $opt_show_projects,
                                                                 'subject_id' => $subject_id,});
  								 
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  
  my $norm_fmt = "%i: %D\nVersion: %V\nHeartbeat: %F:contacted_at";
  my $short_fmt = '%i: %D';
  my $result;
  if ( $opt_short ) {
      $result = $gitlab->substitute_format( $short_fmt, $result_obj );
  } elsif ( $opt_long ) {
      $result = $json->pretty->encode( $result_obj ) . "\n";
  } elsif ( $opt_format ) {
      $result = $gitlab->substitute_format( $opt_format, $result_obj );
  } else {
      $result = $gitlab->substitute_format( $norm_fmt, $result_obj );
  }
  if ( $opt_show_projects and exists $result_obj->{ 'projects' } and not $opt_long ) {
      $result .= "\nEnabled for projects:\n  " . join( "\n  ", 
						     map { "$_->{ 'name_with_namespace' } ($_->{ 'id' })" } 
						     @{ $result_obj->{ 'projects' } } ) . "\n";
  }
  print $result . "\n";
  
  return $stat;
}

sub cmd_enablerun {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Runners_IF::gcli_enablerun_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_enablerun ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $this->preference( 'current_project' );

  if ( not $opt_in ) {
      die "No project specified for which to enable the runner. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # intial option checking here
  my $subject_list = join( ',', @ARGV );
  if ( not $subject_list ) {
      return "Error: Missing runner argument(s).\n";
  }
  foreach my $subject_id ( split( ',', $subject_list ) ) {
      my $runner;
      # verify runner
      try {
	  $runner = $gitlab->rest_get_single( '/runners/' . $subject_id );
      } catch {
	  die "Cannot find runner with id $subject_id.\n";
      };

      # end this routine by returning a status indicator; not null means error!
      
      my $endpoint = '/projects/' . $project_id . '/runners';
      my $params = $gitlab->build_params({ 'help' => $opt_help,
					   'in' => $opt_in,
					   'runner_id' => $subject_id,});								 
  
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_post( $endpoint, $params )->{ 'body' };
      } catch {
	  print "Failed to enable runner $subject_id for project $opt_in: $_\n";
      };
      $result_obj = from_json( $result_obj );
      print "Runner $result_obj->{ description } ($result_obj->{ id }) now enabled for project $opt_in.\n";
  }
  
  return $stat;
}

sub cmd_disablerun {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Runners_IF::gcli_disablerun_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_disablerun ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $this->preference( 'current_project' );

  # intial option checking here
  if ( not $opt_in ) {
      die "No project specified for which to disable the runner. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject_list = join( ',', @ARGV );
  if ( not $subject_list ) {
      return "Error: Missing runner argument(s).\n";
  }
  foreach my $subject ( split( ',', $subject_list ) ) {
      # verify runner
      my $runner;
      try {
	  $runner = $gitlab->rest_get_single( '/runners/' . $subject );
      } catch {
	  die "Cannot find runner with id $subject.\n";
      };

      # end this routine by returning a status indicator; not null means error!

      my $endpoint = '/projects/' . $project_id . '/runners/' . $subject;
      my $result_obj;
      try {
	  $result_obj = $gitlab->rest_delete( $endpoint );
      } catch {
	  die "Could not disable runner $subject: $_\n";
      };
      
      print "Runner $subject disabled in project $opt_in" . ".\n";
  }
  
  return $stat;
}


sub cmd_deleterun {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Runners_IF::gcli_deleterun_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deleterun ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help  );
  GetOptions (
      'help' => \$opt_help,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing runner argument.\n";
  }
  my $subject_id = $subject;
  # end this routine by returning a status indicator; not null means error!

  my $endpoint = '/runners/' . $subject_id;
  
  my @results;								 
  
  
  my $result_obj = $gitlab->rest_delete( $endpoint );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
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
