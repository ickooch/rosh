package GitLabCLI::CIYML;

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

use  GitLabCLI::CIYML_IF;

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
     ['lsyml', 'cmd_lsyml' ],
     ['descyml', 'cmd_descyml' ],
     ['catyml', 'cmd_catyml' ], 
		 ]);
  
  return $this;
}


sub cmd_lsyml {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::CIYML_IF::gcli_lsyml_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsyml ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short,  $opt_json );
  GetOptions (
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/templates/gitlab_ci_ymls';

  
  
  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'help' => $opt_help,
                                                                  'long' => $opt_long,
                                                                  'short' => $opt_short,
                                                                 });
  								 
  my @results = @{ $gitlab->rest_get_list( $endpoint ) }; 

  print join( "\n", map { $_->{ 'name' } } @results ) . "\n";

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descyml {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::CIYML_IF::gcli_descyml_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descyml ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help );
  GetOptions (
      'help' => \$opt_help,
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
      return "Error: Missing yml-template argument.\n";
  }
  my $subject_id = $subject;

  # end this routine by returning a status indicator; not null means error!  
  
  my $endpoint_template = '/templates/gitlab_ci_ymls/:key';

  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'subject_id' => $subject_id });
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_get_single( $endpoint );
  } catch {
      die "Cannot find a .gitlab-ci.yml template '$subject_id'.n";
  };
  print "\"$subject_id\" template for .gitlab-ci.yml:\n";
  print $result_obj->{ 'content' } . "\n"; 

  return $stat;
}

sub cmd_catyml {
  my $stat = "";

  my $this = shift;


  my $usage = GitLabCLI::CIYML_IF::gcli_catyml_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_catyml ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_installyml );
  GetOptions (
      'help' => \$opt_help,
      'get' => \$opt_installyml,
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
      return "Error: Missing yml-template argument.\n";
  }
  my $subject_id = $subject;

  # end this routine by returning a status indicator; not null means error!  
  
  my $endpoint_template = '/templates/gitlab_ci_ymls/:key';

  my $endpoint = $gitlab->execute_endpoint_template( $endpoint_template, { 'subject_id' => $subject_id });
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_get_single( $endpoint );
  };
  my $out_fn = '.gitlab-ci.yml';
  if ( -e $out_fn ) {
      warn "Gitlab-CI control file '$out_fn' exists. Saving control file as '$subject_id.$out_fn'\n";
      $out_fn = $subject_id . $out_fn;
  }
  open( my $out_fh, '>', $out_fn ) or
      die "Cannot create output file handle for $out_fn: $!\n";
  print "Saving $subject_id template for .gitlab-ci.yml as $out_fn\n";
  print $out_fh "# Based on \"$subject_id\" template for .gitlab-ci.yml:\n";
  print $out_fh $result_obj->{ 'content' } . "\n";
  close $out_fh;

  return $stat;
}


1;
