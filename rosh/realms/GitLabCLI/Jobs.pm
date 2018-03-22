package GitLabCLI::Jobs;

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

use  GitLabCLI::Jobs_IF;

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
     ['lsjob', 'cmd_lsjob' ],
     ['lsnamejob', 'cmd_lsnamejob' ],
     ['descjob', 'cmd_descjob' ],
     ['getjob', 'cmd_getjob' ],
     ['getatfjob', 'cmd_getatfjob' ],
     ['downloadatfjob', 'cmd_downloadatfjob' ],
     ['canceljob', 'cmd_canceljob' ],
     ['retryjob', 'cmd_retryjob' ],
     ['erasejob', 'cmd_erasejob' ],
     ['playjob', 'cmd_playjob' ], 
		 ]);
  
  return $this;
}


sub cmd_lsjob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_lsjob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsjob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_limit, $opt_short, $opt_format, $opt_in, $opt_branch,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'limit|max=i' => \$opt_limit,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      'branch|b=s' => \$opt_branch,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/projects/:project-id/jobs';
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "No project specified for which to list CI jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  
  my $endpoint = '/projects/' . $project_id . '/jobs';
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_branch ) {
      @results = grep { $_->{ 'ref' } =~ m/${opt_branch}/ } @results;
  }
  if ( $opt_limit and ( $opt_limit < @results ) ) {
      @results = splice( @results, 0, $opt_limit );
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:status\t %n,\t ID: %i; Branch: %F:ref";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_lsnamejob {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Jobs_IF::gcli_lsnamejob_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsnamejob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_all, $opt_long, $opt_limit, $opt_short, $opt_format, $opt_branch,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'all|a' => \$opt_all,
      'long|l' => \$opt_long,
      'limit|max=i' => \$opt_limit,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'branch|b=s' => \$opt_branch,
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
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list names of jobs requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/jobs';

  my @results = @{ $gitlab->rest_get_list( $endpoint ) };

  if ( not $opt_all ) {
      my %jobdesc;								 
      foreach my $j ( @results ) {
	  $jobdesc{ $j->{ 'name' } } = 1;
      } 
      
      @results = sort keys %jobdesc;
      if ( $filter_re ) {
	  @results = grep{ $_ =~ m/${filter_re}/ } @results;
      }
      
      if ( @results ) {
	  print "Job names:\n  " . join( "\n  ", @results ) . "\n";
      } else {
	  print "No job definitions found.\n";
      }
      return $stat;
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_branch ) {
      @results = grep { $_->{ 'ref' } =~ m/${opt_branch}/ } @results;
  }
  if ( $opt_limit and ( $opt_limit < @results ) ) {
      @results = splice( @results, 0, $opt_limit );
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:status\t %n,\t ID: %i; Branch: %F:ref";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  return $stat;
}

sub cmd_descjob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_descjob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descjob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_in );
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

  $opt_in ||= $this->preference( 'current_project' );

  # intial option checking here
  if ( not $opt_in ) {
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject;  
  my $result_obj = $gitlab->rest_get_single( $endpoint );

  print $json->pretty->encode( $result_obj ) . "\n"; 
  
  return $stat;
}

sub cmd_getjob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_getjob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_getjob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_file,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'file|f' => \$opt_file,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $this->preference( 'current_project' );

  # intial option checking here
  if ( not $opt_in ) {
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject . '/trace';
  my $result_obj = $gitlab->rest_get_single( $endpoint );

  print $result_obj . "\n";
  
  return $stat;
}

sub cmd_getatfjob {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Jobs_IF::gcli_getatfjob_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_getatfjob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
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
      return "Error: Missing job argument.\n";
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "get artifacts from job requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject . '/artifacts';

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );

  my $atf_fh;
  open( $atf_fh, '>', 'job-artifacts' ) or
      die "Cannot open artifacts file.\n";
  binmode $atf_fh;
  print $atf_fh $result_obj;
  close $atf_fh;

  print "Stored artifacts file.\n";
  
  return $stat;
}

sub cmd_downloadatfjob {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Jobs_IF::gcli_downloadatfjob_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_downloadatfjob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_ref, $opt_file,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'ref=s' => \$opt_ref,
      'file|f' => \$opt_file,
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
      return "Error: Missing job argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $gitlab->assert_object_id( 'job', $subject );
  } catch {
      die "Cannot determine id for job object \"$subject\".\n";
  };
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "get job requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/jobs/artifacts/:ref_name/download?job=name';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  print ucfirst "get" . "d job " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command downloadatfjob in GitLabCLI::Jobs' . "\n";

  return $stat;
}

sub cmd_canceljob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_canceljob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_canceljob ';
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
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject . '/cancel';
  my $params = $gitlab->build_params({ 'help' => $opt_help,
				       'id' => $opt_in,
				       'job_id' => $subject,});								 
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );

  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $result = from_json( $result_obj->{ 'body' } );
      print $gitlab->substitute_format( "cancel job $subject as %i => %F:status", $result ) . "\n";
  }

  return $stat;
}

sub cmd_retryjob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_retryjob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_retryjob ';
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
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject . '/retry';
  my $params = $gitlab->build_params({ 'help' => $opt_help,
				       'id' => $opt_in,
				       'job_id' => $subject,});								 
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $result = from_json( $result_obj->{ 'body' } );
      print $gitlab->substitute_format( "retry job $subject as %i => %F:status", $result ) . "\n";
  }
  return $stat;
}

sub cmd_erasejob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_erasejob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_erasejob ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_force, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'force|f' => \$opt_force,
      'in=s' => \$opt_in,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $this->preference( 'current_project' );

  # intial option checking here
  if ( not $opt_in ) {
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my @jobs = ( $subject, @ARGV );
  my $params = { 'id' => $project_id };
  foreach my $job ( @jobs ) {
      my $endpoint = '/projects/' . $project_id . '/jobs/' . $job . '/erase';
      $params->{ 'job_id' } = $job;
      my $result_obj = $gitlab->rest_post( $endpoint, $params );
      if ( $this->preference( 'verbose' ) ) {
	  print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
      } else {
	  my $result = from_json( $result_obj->{ 'body' } );
	  print $gitlab->substitute_format( "erase job files for job $job", $result ) . "\n";
      }
  }
  
  return $stat;
}

sub cmd_playjob {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Jobs_IF::gcli_playjob_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_playjob ';
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
      die "No project specified in which to look for Jobs. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing job argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  my $endpoint = '/projects/' . $project_id . '/jobs/' . $subject . '/play';
  my $params = $gitlab->build_params({ 'help' => $opt_help,
				       'id' => $opt_in,
				       'job_id' => $subject,});								 
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $result = from_json( $result_obj->{ 'body' } );
      print $gitlab->substitute_format( "play job $subject as %i => %F:status", $result ) . "\n";
  }

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
