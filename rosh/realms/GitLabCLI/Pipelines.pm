package GitLabCLI::Pipelines;

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

use  GitLabCLI::Pipelines_IF;

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
     ['lspip', 'cmd_lspip' ],
     ['descpip', 'cmd_descpip' ], 
		 ]);
  
  return $this;
}


sub cmd_lspip {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Pipelines_IF::gcli_lspip_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lspip ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_limit, $opt_short, $opt_format, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'limit=i' => \$opt_limit,
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
  
  
  my $endpoint_template = '/projects/:project-id/pipelines';

  $opt_in ||= $this->preference( 'current_project' );

  if ( not $opt_in ) {
      die "No project specified in which to look for pipelines. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/pipelines';
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'description' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_limit and ( $opt_limit < @results ) ) {
      @results = splice( @results, 0, $opt_limit );
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%i %F:status @ %F:ref (%F:sha(7) by %F:user.username)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descpip {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Pipelines_IF::gcli_descpip_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descpip ';
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
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing pipeline argument.\n";
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "No project specified in which to check pipeline. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
    
  my $endpoint_template = '/projects/:project-id/pipelines/:id';

  my $endpoint = '/projects/' . $project_id . '/pipelines/' . $subject;
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  
  if ( $opt_format ) {
      print $gitlab->substitute_format( $opt_format, $result_obj ) . "\n"; 
  } elsif ( $opt_long ) {
      print $json->pretty->encode( $result_obj ) . "\n";
  } else {
      my $norm_format = "%i %F:status @ %F:ref (%F:sha(7) by %F:user.username)";
      print join( "\n", $gitlab->substitute_format( $norm_format, $result_obj ) ) . "\n"; 
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
