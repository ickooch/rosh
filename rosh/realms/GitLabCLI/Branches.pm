package GitLabCLI::Branches;

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

use  GitLabCLI::Branches_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsbr', 'cmd_lsbr' ],
     ['descbr', 'cmd_descbr' ],
     ['protbr', 'cmd_protbr' ],
     ['unprotbr', 'cmd_unprotbr' ],
     ['mkbr', 'cmd_mkbr' ],
     ['delbr', 'cmd_delbr' ],
     ['delmrgbr', 'cmd_delmrgbr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_lsbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsbr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_limit, $opt_all, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'limit|max=i' => \$opt_limit,
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
  
  my $endpoint_template = '/projects/:id/repository/branches';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches';
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  @results = grep { not $_->{ 'merged' } } @results
      if ( not $opt_all );
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { "$_->{ 'name' }\t (" . ( $_->{ 'merged' } ? 'merged' : 'unmerged' ) . 
				  ( $_->{ 'protected' } ? ',protected' : '' ) . ')' } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  

  return $stat;
}

sub cmd_descbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_descbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descbr ';
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
      return "Error: Missing branch argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  
  my $endpoint_template = '/projects/:id/repository/branches/:branch';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches/' . $subject;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      # TODO / FIXME - define custom normal format
      my $norm_format = "Branch: %n\n  protected: %F:protected\n merged: %F:merged";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }
  
  return $stat;
}

sub cmd_protbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_protbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_protbr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_can_push, $opt_can_merge,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'allow-push' => \$opt_can_push,
      'allow-merge' => \$opt_can_merge,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing branch argument.\n";
  }
  my $subject_id = $subject; # no id for branches

  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint_template = '/projects/:id/repository/branches/:branch/protect';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "protect branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  $opt_can_push = ( defined $opt_can_push ? 1 : 0 );
  $opt_can_merge = ( defined $opt_can_merge ? 1 : 0 );
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches/' . $subject_id . '/protect';
  my $params = $gitlab->build_params({ 'id' => $project_id,
				       'developers_can_push' => $opt_can_push,
				       'developers_can_merge' => $opt_can_merge,
				       'branch' => $subject_id,});
  my @results;								 
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  return $stat;
}

sub cmd_unprotbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_unprotbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_unprotbr ';
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
      return "Error: Missing branch argument.\n";
  }
  my $subject_id = $subject; # no id fior branches
  # end this routine by returning a status indicator; not null means error!
  my $endpoint_template = '/projects/:id/repository/branches/:branch/unprotect';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "unprotect branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches/' . $subject_id . '/unprotect';
  my $params = $gitlab->build_params({ 'id' => $project_id,
				       'branch' => $subject_id,});
  my @results;								 
  
  my $result_obj = $gitlab->rest_put( $endpoint, $params );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  return $stat;
}

sub cmd_mkbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_mkbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkbr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_for_id, $opt_ref,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'for=s' => \$opt_for_id,
      'ref=s' => \$opt_ref,
      );

  if ( $opt_help ) {
      print $usage;
      return 0;
  }

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  # intial option checking here
  if ( $opt_for_id ) {
      # try to get the name of the branch from an issue
      if ( $subject ) {
	  die "** Error: Contradicting arguments --for <issue> and explicit branch name\n  $subject\n" .
	      "Use only one way to choose the branch name.\n";
      }
      if ( is_gitlab_issue_id ( $opt_for_id ) ) {
	  try {
	      $subject = $this->get_gitlab_issue_title( $opt_for_id );
	  } catch {
	      chomp $_;
	      die "** Error: Could not obtain issue title for $opt_for_id: $_\n";
	  };
      } elsif ( is_jira_issue_id ( $opt_for_id ) ) {
	  try {
	      $subject = $this->get_jira_issue_title( $opt_for_id );
	  } catch {
	      chomp $_;
	      die "** Error: Could not obtain issue title for $opt_for_id: $_\n";
	  };
      } else {
	  die "** Error: Cannot recognize issue id format of \"$opt_for_id\".\n";
      }
  }
  
  if ( not $subject ) {
      return "Error: Missing branch argument.\n";
  }
  my $subject_id = $subject; # no id for branches
  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint_template = '/projects/:id/repository/branches';
  
  $opt_ref ||= 'master';
  
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches';
  my $params = $gitlab->build_params({ 'id' => $project_id,
				       'ref' => $opt_ref,
				       'branch' => $subject_id,});
  my @results;								 

  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  push( @results, $result_obj );
  
  print "Created new remote branch $subject off $opt_ref in repository $opt_in.\n";
  
  return $stat;
}

sub is_gitlab_issue_id {
    my $id = shift;

    return $id =~ m/^\d+$/;
}

sub get_gitlab_issue_title {
    my ( $this, $id ) = @_;

    my $project_id = $this->preference( 'current_project_id' );
    my $gitlab = $this->preference( 'gitlab_connector' );

    my $issue = $gitlab->rest_get_single( '/projects/' . $project_id . '/issues/' . $id );
    my $title = $issue->{ 'iid' } . '-' . $issue->{ 'title' };
    $title =~ s/\s+/-/g;

    return $title;
}

sub is_jira_issue_id {
    my $id = shift;

    return $id =~ m/^\w+-\d+$/;
}

sub get_jira_issue_title {
    my ( $this, $id ) = @_;

    my $issue;
    try {
	$issue = $this->get_shell->request_service( 'jira', 'get_issue', $id );
    } catch {
	chomp $_;
	die "Cannot get jira issue title: $_\n";
    };
    my $title = $issue->{ 'key' } . '-' . $issue->{ 'fields' }->{ 'summary' };
    $title =~ s/\s+/-/g;

    return $title;
}    

sub cmd_delbr {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Branches_IF::gcli_delbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_delbr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_in,  );
  GetOptions (
      'force|f' => \$opt_force,
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
      return "Error: Missing branch argument.\n";
  }
  my $subject_id = $subject; # no ids for branches

  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint_template = '/projects/:id/repository/branches/:branch';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/repository/branches/' . $subject;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_delete( $endpoint );
  push( @results, $result_obj );

  print "Deleted branch \"$subject\" in remote repository $opt_in.\n";
  
  return $stat;
}

sub cmd_delmrgbr {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $usage = GitLabCLI::Branches_IF::gcli_delmrgbr_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_delmrgbr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_in,  );
  GetOptions (
      'force|f' => \$opt_force,
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
      return "Error: Missing branch argument.\n";
  }
  my $subject_id = $subject;
  # end this routine by returning a status indicator; not null means error!
  
  my $endpoint_template = '/projects/:id/repository/branches/:branch';
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "delete merged branch requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - fill in the correct endpoint format
  my $endpoint = '/projects/:id/repository/branches/:branch';
  
  my @results;								 
  
  
  my $result_obj = $gitlab->rest_delete( $endpoint );
  push( @results, $result_obj );
  
  print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  
  print "**** UNIMPLEMENTED: " . 'command delmrgbr in GitLabCLI::Branches' . "\n";

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
