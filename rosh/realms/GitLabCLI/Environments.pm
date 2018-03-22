package GitLabCLI::Environments;

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

use  GitLabCLI::Environments_IF;

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
     ['lsenv', 'cmd_lsenv' ],
     ['descenv', 'cmd_descenv' ],
     ['addenv', 'cmd_addenv' ],
     ['stopenv', 'cmd_stopenv' ],
     ['rmenv', 'cmd_rmenv' ],
     ['editenv', 'cmd_editenv' ], 
		 ]);
  
  return $this;
}


sub cmd_lsenv {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Environments_IF::gcli_lsenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsenv ';
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
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/environments';
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'key' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'key' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { "$_->{ name } ($_->{ id })" } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descenv {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Environments_IF::gcli_descenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descenv ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'in=s' => \$opt_in,
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
      return "Error: Missing env argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
    
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/environments';
  
  my @results;								 
  
  my $result_obj;
  try {
      my @envs = grep { ( $_->{ 'name' } eq $subject ) or ( $_->{ 'id' } eq $subject ) }
      @{ $gitlab->rest_get_list( "/projects/$project_id/environments" ) };
      $result_obj = shift @envs;
  } catch {
      die "Cannot determine id for environment object \"$subject\" ($_).\n";
  };
  
  push( @results, $result_obj );
  
  if ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }
  
  return $stat;
}

sub cmd_addenv {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Environments_IF::gcli_addenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addenv ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_url,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'url=s' => \$opt_url,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing env argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  my $endpoint = '/projects/' . $project_id . '/environments';
  my $params = {
      'id' => $project_id,
      'name' => $subject,
  };
  $params->{ 'external_url' } = $opt_url
      if ( $opt_url );

  my @results;								 
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "Create environment $subject failed: $_\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );

  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $desc;
      my $norm_format = "%n (%i)\n";
      foreach my $r ( @results ) {
	  $desc = $gitlab->substitute_format( $norm_format, $r );
	  $desc .= '  slug: ' . $r->{ 'slug' } . "\n";
	  $desc .= '  ext_url: ' . $r->{ 'external_url' } . "\n"
	      if ( exists $r->{ 'external_url' } );
      }
  }

  return $stat;
}

sub cmd_stopenv {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Environments_IF::gcli_stopenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_stopenv ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_url,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'url=s' => \$opt_url,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing env argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'env', $subject );
  } catch {
      die "Cannot determine id for env object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  
  my $endpoint_template = '/projects/:project-id/environments/stop';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:project-id/environments/stop';
  my $params = $gitlab->build_params({ 'help' => $opt_help,
                                                                  'in' => $opt_in,
                                                                  'url' => $opt_url,
                                                                 'subject_id' => $subject_id,});
  my @results;								 
  
  
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  push( @results, $result_obj );
  
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command stopenv in GitLabCLI::Environments' . "\n";

  return $stat;
}

sub cmd_rmenv {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Environments_IF::gcli_rmenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmenv ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_in,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing env argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  my $subject_id = $this->assert_env_id( $subject, $project_id );

  my $endpoint = '/projects/' . $project_id . '/environments/' . $subject_id;
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      die "No such environment: '$subject'\n";
  };
      
  print "Deleted environment $subject\n";

  return $stat;
}

sub cmd_editenv {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Environments_IF::gcli_editenv_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editenv ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_url,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'url=s' => \$opt_url,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing env argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit env requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );
  my $subject_id = $this->assert_env_id( $subject, $project_id );

  my $endpoint = '/projects/' . $project_id . '/environments/' . $subject_id;
  my $params = {
      'id' => $project_id,
      'name' => $subject,
  };
  $params->{ 'external_url' } = $opt_url
      if ( $opt_url );

  my @results;								 
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_put( $endpoint, $params );
  } catch {
      die "Cannot modify environment $subject: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );

  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $desc;
      my $norm_format = "%n (%i)\n";
      foreach my $r ( @results ) {
	  $desc = $gitlab->substitute_format( $norm_format, $r );
	  $desc .= '  slug: ' . $r->{ 'slug' } . "\n";
	  $desc .= '  ext_url: ' . $r->{ 'external_url' } . "\n"
	      if ( exists $r->{ 'external_url' } );
	  print "Updated environment $r->{ 'name' }\n";
      }
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

sub assert_env_id {
    my ($this, $env_name, $pid ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $env_id;
    try {
	my @envs = grep { ( $_->{ 'name' } eq $env_name ) or ( $_->{ 'id' } eq $env_name ) } 
	@{ $gitlab->rest_get_list( "/projects/$pid/environments" ) };
	$env_id = @envs[ 0 ]->{ 'id' };
    } catch {
	die "Cannot determine id for environment object \"$env_name\" ($_).\n";
    };
    
    return $env_id;
}

1;
