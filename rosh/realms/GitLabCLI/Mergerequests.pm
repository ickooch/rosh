package GitLabCLI::Mergerequests;

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

use  GitLabCLI::Mergerequests_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsmr', 'cmd_lsmr' ],
     ['lsnotemr', 'cmd_lsnotemr' ],
     ['descmr', 'cmd_descmr' ],
     ['cmtmr', 'cmd_cmtmr' ],
     ['getmr', 'cmd_getmr' ],
     ['cancelmr', 'cmd_cancelmr' ],
     ['acceptmr', 'cmd_acceptmr' ],
     ['approvemr', 'cmd_approvemr' ],
     ['unapprovemr', 'cmd_unapprovemr' ],
     ['erasemr', 'cmd_erasemr' ],
     ['addmr', 'cmd_addmr' ],
     ['editmr', 'cmd_editmr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_lsmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_labels, $opt_milestone, $opt_limit, $opt_short, $opt_format, $opt_all, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'labels|type=s' => \$opt_labels,
      'milestone=s' => \$opt_milestone,
      'limit|max=i' => \$opt_limit,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'all|a' => \$opt_all,
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
  
  
  my $endpoint_template = '/projects/:project-id/merge_requests';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/merge_requests';
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  @results = grep { not $_->{ 'state' } eq 'merged' } @results
      if ( not $opt_all );
  if ( $filter_re ) {
      @results = grep{ $_->{ 'description' } =~ m/${filter_re}/i } @results;
  }
  if ( @results ) {
      if ( $opt_format ) {
	  print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
      } elsif ( $opt_long ) {
	  print join( "\n", map { $_->{ 'iid' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
      } else {
	  print join( "\n", map { $_->{ 'iid' } . ', [' . $_->{ 'state' } . ']: ' . $_->{ 'title' } } @results ) . "\n";
      }
  } else {
      print 'No ' . ( $opt_all ? '' : 'open ' ) . 'merge requests found.' . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_lsnotemr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_lsnotemr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsnotemr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_limit, $opt_short, $opt_format, $opt_in,  );
  GetOptions (
      'help|h' => \$opt_help,
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
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing merge argument.\n";
  }
  my $subject_id = $subject;

  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid/notes';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list comments to merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject_id . '/notes';
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'description' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "Comment-id %i: %F:author.name said on %F:created_at:\n  %F:body\n";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_descmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_with, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'with=s' => \$opt_with,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id = $subject;

  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  if ( $opt_with ) {
      foreach my $res ( @results ) {
	  if ( $this->with( 'Comments', $opt_with ) ) {	 
	      $res->{ 'comments' } = $gitlab->condense_comments( 
	      $gitlab->rest_get_list( '/projects/' . $project_id . 
				      '/merge_requests/' . $res->{ 'iid' } . 
				      '/notes' )
		  );
	  }
	  unless ( $this->without( 'Description', $opt_with ) ) {
	      $res->{ 'description' } = $this->wrap_text( $res->{ 'description' } );
	  }
      }
  }
  
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $default_format = '%F:iid (%f:labels) - %F:title\n  From: %F:source_branch\n  To: %F:target_branch\n  Assigned to: %f:assignee.username (%f:assignee.name)\n';

      # description is put out by default - unless explicitly shunned
      $default_format .= '\nDESCRIPTION:\n============\n%D\n'
	  unless ( $this->without( 'Description', $opt_with ) );
      # comments are not listed - unless explicitly requested
      $default_format .= '\nCOMMENTS:\n' . '=' x length( 'COMMENTS:' ) . '\n  %F:comments\n'
	  if ( $this->with( 'Comments', $opt_with ) );
      print join( "\n", map { $gitlab->substitute_format( $default_format, $_ ) } @results ) . "\n";
  }
  
  return $stat;
}

sub cmd_cmtmr {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Mergerequests_IF::gcli_cmtmr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_cmtmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_comment,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'comment|c=s' => \$opt_comment,
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
      return "Error: Missing merge argument.\n";
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "comment merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  $opt_comment ||= $this->get_description( $opt_comment );
  $opt_comment ||= $this->get_text( 'Please enter your comment (Markdown allowed):' );
  
  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject . '/notes';

  my $params = {
      'body' => $opt_comment,
  };

  my @result;
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "comment merge failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @result, $result );
  print ucfirst "comment" . "ed merge request $subject.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @result ) . "\n";
  }

  return $stat;
}

sub cmd_getmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_getmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_getmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_commits, $opt_changes, $opt_file,  );
  GetOptions (
      'help|h' => \$opt_help,
      'in=s' => \$opt_in,
      'commits' => \$opt_commits,
      'changes' => \$opt_changes,
      'file|f' => \$opt_file,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id = $subject;

  my $what;
  if ( $opt_commits ) {
      die "Error: please select either commits, or changes - not both.\n"
	  if ( $opt_changes );
      $what = 'commits';
  }
  if ( $opt_changes ) {
      die "Error: please select either commits, or changes - not both.\n"
	  if ( $what );
      $what = 'changes';
  }
  # end this routine by returning a status indicator; not null means error!

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "get merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject_id . '/' . $what;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  return $stat;
}

sub cmd_cancelmr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Mergerequests_IF::gcli_cancelmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_cancelmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
      'help|h' => \$opt_help,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'merge', $subject );
  } catch {
      die "Cannot determine id for merge object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "cancel merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds';
  my $params = $gitlab->build_params({ 'help|h' => $opt_help,
                                                                  'in' => $opt_in,
                                                                 'subject_id' => $subject_id,});
  my @results;								 
  
  
  
  
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command cancelmr in GitLabCLI::Mergerequests' . "\n";

  return $stat;
}

sub cmd_acceptmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_acceptmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_acceptmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_sha, $opt_message, $opt_rmsrc_branch,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'sha=s' => \$opt_sha,
      'message|msg=s' => \$opt_message,
      'rm-source-branch|delete-branch' => \$opt_rmsrc_branch,
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
      return "Error: Missing mergerequest argument.\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid/merge';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "accept merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # verify existing merge request
  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject;
  my @results;								 
  my $merge_request = $gitlab->rest_get_single( $endpoint );
  my $subject_id = $subject;

  $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject_id . '/merge';
  
  my $params = $gitlab->build_params({
      'id' => $project_id,
      'merge_request_iid' => $subject_id,
      'merge_commit_message' => $opt_message,
      'sha' => $opt_sha,
				     });
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  push( @results, $result_obj );
  
  print "Merged merge request $subject_id ($merge_request->{ 'title' }) from $merge_request->{ 'source_branch' } to $merge_request->{ 'target_branch' }.\n";
  
  return $stat;
}

sub cmd_approvemr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Mergerequests_IF::gcli_approvemr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_approvemr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
      'help|h' => \$opt_help,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'merge', $subject );
  } catch {
      die "Cannot determine id for merge object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid/approve';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "approve merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:id/merge_requests/:merge_request_iid/approve';
  my $params = $gitlab->build_params({ 'help|h' => $opt_help,
                                                                  'in' => $opt_in,
                                                                 'subject_id' => $subject_id,});
  my @results;								 
  
  
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  push( @results, $result_obj );
  
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command approvemr in GitLabCLI::Mergerequests' . "\n";

  return $stat;
}

sub cmd_unapprovemr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Mergerequests_IF::gcli_unapprovemr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_unapprovemr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
  GetOptions (
      'help|h' => \$opt_help,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'merge', $subject );
  } catch {
      die "Cannot determine id for merge object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid/unapprove';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "unapprove merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:id/merge_requests/:merge_request_iid/unapprove';
  my $params = $gitlab->build_params({ 'help|h' => $opt_help,
                                                                  'in' => $opt_in,
                                                                 'subject_id' => $subject_id,});
  my @results;								 
  
  
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  push( @results, $result_obj );
  
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command unapprovemr in GitLabCLI::Mergerequests' . "\n";

  return $stat;
}

sub cmd_erasemr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Mergerequests_IF::gcli_erasemr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_erasemr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_force, $opt_in,  );
  GetOptions (
      'help|h' => \$opt_help,
      'force|f' => \$opt_force,
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
      return "Error: Missing merge argument.\n";
  }
  my $subject_id;
  try {
      $subject_id = $gitlab->get_object_id( 'merge', $subject );
  } catch {
      die "Cannot determine id for merge object \"$subject\".\n";
  };

  # end this routine by returning a status indicator; not null means error!

  
  
  my $endpoint_template = '/projects/:id/merge_requests/:merge_request_iid';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "delete merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:id/merge_requests/:merge_request_iid';
  
  my @results;								 
  
  
  my $result_obj = $gitlab->rest_delete( $endpoint );
  push( @results, $result_obj );
  
  
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command erasemr in GitLabCLI::Mergerequests' . "\n";

  return $stat;
}

sub cmd_addmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_addmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_from_original, $opt_to_target, 
       $opt_title, $opt_desc, $opt_rmsrc_branch, $opt_assign, 
       $opt_labels, $opt_squash, $opt_milestone, $opt_nodesc );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'from=s' => \$opt_from_original,
      'to=s' => \$opt_to_target,
      'title=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'no-description|nodesc|no-desc|nd' => \$opt_nodesc,
      'rm-source-branch|delete-branch' => \$opt_rmsrc_branch,
      'assign-to=s' => \$opt_assign,
      'labels=s' => \$opt_labels,
      'squash' => \$opt_squash,
      'milestone=s' => \$opt_milestone,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  if ( $opt_assign ) {
      try {
	  $opt_assign = $gitlab->get_user_id( $opt_assign );
      } catch {
	  die "Requested assignee \"$opt_assign\" is not known.\n";
      };
  }
  # end this routine by returning a status indicator; not null means error!

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  try {
      $this->assert_branch( $project_id, $opt_from_original );
  } catch {
      die "Invalid source branch \"$opt_from_original\" in merge request.\n";
  };
  try {
      $this->assert_branch( $project_id, $opt_to_target );
  } catch {
      die "Invalid target branch \"$opt_to_target\" in merge request.\n";
  };

  $opt_title ||= $this->ask( "Merge headline: " );
  die "Please provide a title for the merge request (possibly containing the applicable issue id).\n"
      if ( not $opt_title );

  if ( not $opt_nodesc ) {
      $opt_desc ||= $this->get_description();
      $opt_desc ||= $this->get_text( 'Please describe this merge request (Markdown allowed):' );
  }
  
  my $endpoint = '/projects/' . $project_id . '/merge_requests';
  my $params = {
      'id' => $project_id,
      'source_branch' => $opt_from_original,
      'target_branch' => $opt_to_target,
      'title' => $opt_title,
      'description' => $this->get_description( $opt_desc ),
      'assignee_id' => $opt_assign,
      'remove_source_branch' => $opt_rmsrc_branch,
      'labels' => $opt_labels,
      'squash' => $opt_squash,
      'milestone_id' => $opt_milestone,
  };
  my @results;								 
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  push( @results, $result_obj );
  
  print "Submitted merge request for branch $opt_from_original to $opt_to_target.\n";
  
  return $stat;
}

sub cmd_editmr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Mergerequests_IF::gcli_editmr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editmr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_title, $opt_desc, $opt_assign, 
       $opt_to_target, $opt_rmsrc_branch, $opt_labels, $opt_squash, 
       $opt_milestone,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'title=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'assign-to=s' => \$opt_assign,
      'to=s' => \$opt_to_target,
      'rm-source-branch|delete-branch' => \$opt_rmsrc_branch,
      'labels=s' => \$opt_labels,
      'squash' => \$opt_squash,
      'milestone=s' => \$opt_milestone,
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
      return "Error: Missing mergerequest argument.\n";
  }
  if ( $opt_assign ) {
      try {
	  $opt_assign = $gitlab->get_user_id( $opt_assign );
      } catch {
	  die "Requested assignee \"$opt_assign\" is not known.\n";
      };
  }
  
  # end this routine by returning a status indicator; not null means error!

  my $endpoint_template = '/projects/:project-id/merge_requests/:merge_request_iid';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit merge requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  if ( $opt_to_target ) {
      try {
	  $this->assert_branch( $project_id, $opt_to_target );
      } catch {
	  die "Invalid target branch \"$opt_to_target\" in merge request.\n";
      };
  }

  # verify existing merge request
  my $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject;
  my @results;								 
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  my $subject_id = $subject;
  
  $endpoint = '/projects/' . $project_id . '/merge_requests/' . $subject_id;
  my $params = $gitlab->build_params({ 
      'id' => $project_id,
      'merge_request_iid' => $subject_id,
      'target_branch' => $opt_to_target,
      'title' => $opt_title,
      'description' => $this->get_description( $opt_desc ),
      'assignee_id' => $opt_assign,
      'remove_source_branch' => $opt_rmsrc_branch,
      'labels' => $opt_labels,
      'squash' => $opt_squash,
      'milestone_id' => $opt_milestone
				     });
  my @results;								 
  
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  push( @results, $result_obj );
  
  print "Updated merge request $subject_id ($result_obj->{ 'title' })\n";

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

sub assert_branch {
    my ($this, $project_id, $br_name ) = @_;

    $br_name or
	die "No branch name specified.\n";
    
    my $gitlab = $this->preference( 'gitlab_connector' );

    my $branch_id;
    try {
	$branch_id = $gitlab->get_branch_id( $project_id, $br_name );
    } catch {
	die "Cannot determine id for branch \"$br_name\" ($_).\n";
    };

    return $branch_id;
}

1;
