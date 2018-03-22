package JiraCLI::Issues;

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

use  JiraCLI::Issues_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsiss', 'cmd_lsiss' ],
     ['lsmyiss', 'cmd_lsmyiss' ],
     ['desciss', 'cmd_desciss' ], 
     ['addiss', 'cmd_addiss' ],
     ['asgiss', 'cmd_asgiss' ],
     ['attiss', 'cmd_attiss' ],
     ['cmtiss', 'cmd_cmtiss' ],
     ['watiss', 'cmd_watiss' ],
     ['uwatiss', 'cmd_uwatiss' ],
     ['transiss', 'cmd_transiss' ], 
     ['get_issue', 'cmd_get_issue' ], 
		 ]);
  
  return $this;
}


sub cmd_lsiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_lsiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_limit, $opt_in, 
       $opt_jql, $opt_show_jql, $opt_board, $opt_filter, $opt_all,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'limit|max=i' => \$opt_limit,
      'in=s' => \$opt_in,
      'jql=s' => \$opt_jql,
      'show-jql' => \$opt_show_jql,
      'on|on-board|board=s' => \$opt_board,
      'filter|flt=s' => \$opt_filter,
      'all|a' => \$opt_all,
      );

  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );
  if ( $opt_help ) {
      print $long_usage;
      print "\nFields / Columns available:\n  " . join( "\n  ", sort @{ $jira->get_issue_fieldnames() }) . "\n";
      return 0;
  }

  # initial option checking here
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  if (  defined( $opt_jql ) + defined( $opt_filter ) + defined( $opt_board ) > 1 ) {
      die "Error: Options --jql, --filter, and --on-board are mutually exclusive.
Please use only one of these options.\n";
  }
  if ( $opt_jql ) {
      $opt_jql = $this->get_description( $opt_jql );
  }
  if ( $opt_filter ) {
      if ( not $opt_filter =~ m/^\d+$/ ) {
	  return "Error: Invalid filter \"$opt_filter\" - please use all numeric filter id.\n";
      }
      my $flt;
      try { 
	  $flt = $jira->rest_get_single( '/filter/' . $opt_filter );
	  $opt_jql = $flt->{ 'jql' };
      } catch {
	  die "Error: Invalid filter specified: $_\n";
      };
  }
  if ( $opt_board ) {
      $opt_board = $jira->get_board_id( $opt_board );
      my $board;
      try {
	  my $endpoint = '/board/' . $opt_board . '/configuration';
	  my $board = $jira->load_base_url( '/agile/1.0' )->rest_get_single( $endpoint );
	  my $flt = $board->{ 'filter' }->{ 'id' };
	  $flt = $jira->rest_get_single( '/filter/' . $flt );
	  $opt_jql = $flt->{ 'jql' };
	  $opt_board = $board;
      } catch {
	  die "Error: Invalid board specified: $_\n";
      };
  }
  my $active_states = $jira->get_active_states();
  if ( $opt_in ) {
      die "Error: Use only one of the switches --in, --filter, or --jql.\n"
	  if ( $opt_jql );
      $opt_jql = 'project in (' . $opt_in . ')';
      if ( not $opt_all ) {
	  $opt_jql .= ' AND status in ("' . join( '","', @{ $active_states } ) . '")';
      }
  }
  if ( not $opt_jql ) {
      die "No query specified - use either --in <project-id>, --filter <filter-id> or --jql \"<jql-expression>\".\n";
  }
  $opt_limit ||= 10000; # be careful with the amount of data

  my $default_format = '%F:key (%F:issuetype, %F:status) - %F:summary';
  my $actual_format = $opt_format ? $opt_format : $default_format;
  if ( not $opt_all ) {
      $actual_format .= ' %F:status' ;
  }
  my $required_fields = $jira->format_required_fields( $actual_format );
  my $endpoint = '/search';

  my @results;
  if ( $opt_show_jql ) {
      print "JQL: $opt_jql\n";
  }
  try {
      @results = @{ $jira->rest_get_single( $endpoint . '?jql=' . $opt_jql . '&maxResults=' . $opt_limit . 
					    '&fields=' . $required_fields )->{ 'issues' } };
      @results = map { 
	  $_->{ 'fields' }->{ 'key' } = $_->{ 'key' }; 
	  $_->{ 'fields' }->{ 'id' } = $_->{ 'id' };
	  $_->{ 'fields' }
      } @results;
  } catch {
      die "Search issues failed: $_\n";
  };
  if ( $filter_re ) {
      @results = grep{ $_->{ 'summary' } =~ m/${filter_re}/i } @results;
  }
  if ( not $opt_all ) {
      my $state_re = '^(' . join( '|', @{ $active_states } ) . ')';
      @results = grep{ $_->{ 'status' }->{ 'name' } =~ m/${state_re}/i } @results;
  }
  print scalar( @results ) . " issues.\n";
  if ( $opt_board ) {
      my $status_map = {};
      foreach my $this_state ( @{ $jira->rest_get_list( '/status' ) } ) {
	  $status_map->{ $this_state->{ 'id' } } = $this_state->{ 'name' };
      } 
      my $colspec = [];
      print '* ' . uc( $opt_board->{ 'type' } ) . ' board "' . 
	  $opt_board->{ 'name' } . "\":\n";
      foreach my $this_colspec ( @{ $opt_board->{ 'columnConfig' }->{ 'columns' } } ) {
	  print "=== $this_colspec->{ 'name' } ===\n";
	  my $col_states = '^(' . join( '|', map { $_->{ 'id' } } @{ $this_colspec->{ 'statuses' } } ) . ')$';
	  my @col_results = grep { $_->{ 'status' }->{ 'id' } =~ m/${col_states}/ } @results;
	  if ( @col_results ) {
	      if ( $opt_format ) {
		  print join( "\n", map { $jira->substitute_format( $opt_format, $_, 'check_mapped' => 1 ) } @col_results ) . "\n"; 
	      } elsif ( $opt_long ) {
		  print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @col_results ) . "\n";
	      } else {
		  print join( "\n", map { $jira->substitute_format( $default_format, $_, 'check_mapped' => 1 ) } @col_results ) . "\n";
	      }
	  } else {
	      print "<Column is empty - no issues>\n";
	  }
	  print "\n";
      }
  } elsif ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_, 'check_mapped' => 1 ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print '[Format: "' . $default_format . '"]' . "\n";
      print join( "\n", map { $jira->substitute_format( $default_format, $_, 'check_mapped' => 1 ) } @results ) . "\n";
  }
  print "\n" . scalar( @results ) . ' issues found.' . "\n";
  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_lsmyiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_lsmyiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsmyiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my @orig_argv = @ARGV;
  
  my ( $opt_help, $opt_long, $opt_short, $opt_userid, $opt_format, $opt_all, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'userid=i' => \$opt_userid,
      'format|fmt=s' => \$opt_format,
      'all|a' => \$opt_all,
      'in=s' => \$opt_in,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $jql =  $this->preference( 'jira_myissues' );
  $jql ||= "assignee in (currentUser()) or reporter in (currentUser()) ORDER BY Rang ASC";
  push( @ARGV, @orig_argv, '--jql', $jql );

  $this->cmd_lsiss();
  
  return $stat;
}

sub cmd_desciss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_desciss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_desciss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_with,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'with=s' => \$opt_with,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my @results;								 

  my $default_format = '%F:key (%F:issuetype, %F:status) - %F:summary\nReporter: %F:reporter (%F:reporter.displayName)\nAssigned to: %F:assignee (%F:assignee.displayName)\n';

  # description is put out by default - unless explicitly shunned
  $default_format .= '\nDESCRIPTION:\n============\n%D\n'
      unless ( $this->without( 'Description', $opt_with ) );
  # subscribers are not listed - unless explicitly requested
  $default_format .= '\nWatched by:\n' . '=' x length( 'Watched by:' ) . '\n  %F:watchers\n'
      if ( $this->with( 'Watchers', $opt_with ) );
  
  # comments are not listed - unless explicitly requested
  $default_format .= '\nCOMMENTS:\n' . '=' x length( 'COMMENTS:' ) . '\n  %F:comment\n'
      if ( $this->with( 'Comments', $opt_with ) );
  
  my $actual_format = $opt_format ? $opt_format : $default_format;
  if ( not $opt_long ) {
      $actual_format .= ' %F:status' ;
  }
  my $required_fields = $jira->format_required_fields( $actual_format );

  my $endpoint = '/issue/' . $subject . '?expand=changelog';
  if ( not $opt_long ) {
      $endpoint .=  '&fields=' . $required_fields;
  }
  my $result_obj = $jira->rest_get_single( $endpoint );
  push( @results, $result_obj );      
  @results = map { 
      $_->{ 'fields' }->{ 'key' } = $_->{ 'key' }; 
      $_->{ 'fields' }->{ 'id' } = $_->{ 'id' };
      unless ( $this->without( 'Description', $opt_with ) ) {
	  $_->{ 'fields' }->{ 'description' } = $this->wrap_text( $_->{ 'fields' }->{ 'description' } );
      }
      if ( $this->with( 'Comments', $opt_with ) ) {
	  $_->{ 'fields' }->{ 'comment' } = $this->condense_comments( $_->{ 'fields' }->{ 'comment' } );
      }
      $_->{ 'fields' }
  } @results;
  if ( $this->with( 'Watchers', $opt_with ) ) {
      foreach my $issue ( @results ) {
	  my $watchers = $jira->rest_get_single( '/issue/' . $issue->{ 'key' } . '/watchers' );
	  $issue->{ 'watchers' } = [ map { $_->{ 'name' } } @{ $watchers->{ 'watchers' } } ];
      }
  }
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_, 'check_mapped' => 1 ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { $jira->substitute_format( $default_format, $_, 'check_mapped' => 1 ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub condense_comments {
    my ( $this, $issue_comment ) = @_;

    return [ map { '('. $_->{ 'id' } . ') ' . $this->short_date( $_->{ 'updated' } ) . ', ' . 
		       $_->{ 'author' }->{ 'name' } . ":\n  " .
		       '-' x length( '('. $_->{ 'id' } . ') ' . 
				     $this->short_date( $_->{ 'updated' } ) . 
				     ', ' . $_->{ 'author' }->{ 'name' } . 
				     ':' ) . "\n" .
		       $this->wrap_text( $_->{ 'body' }, '  ' ) . "\n" } 
	     reverse @{ $issue_comment->{ 'comments' } } ];
}

sub cmd_addiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_addiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_labels, $opt_title, $opt_type, $opt_desc, $opt_in, $opt_assign,  );
  GetOptions (
      'help' => \$opt_help,
      'labels=s' => \$opt_labels,
      'title=s' => \$opt_title,
      'type|kind=s' => \$opt_type,
      'desc|d=s' => \$opt_desc,
      'in=s' => \$opt_in,
      'assign-to=s' => \$opt_assign,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "new issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  if ( not $opt_title ) {
      die "** Missing title for issue. Please provide title with option '--title <..>'.\n";
  }
  my %issue_types;
  try {
      foreach my $it ( @{ $jira->rest_get_list( '/issuetype' ) } ) {
	  $issue_types{ $it->{ 'name' } } = $it;
      }
  } catch {
      chomp $_;
      die "** Error: Failed to get issue types: $_.\n";
  };
  if ( not $opt_type ) {
      die "** Missing type for new issue. Please provide type with option '--type <..>'.
** Available issue types:\n    " . join( "\n    ", sort keys %issue_types ) . "\n";
  }
  if ( not exists $issue_types{ $opt_type } ) {
      die "** Invalid type \"$opt_type\" requested for new issue.
** Valid issue types:\n    " . join( "\n    ", map { $_->{ 'name' } } sort keys %issue_types ) . "\n";
  }

  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  if ( not $opt_desc ) {
      if ( my $template = $this->get_template( $opt_type ) ) {
	  $opt_desc = $this->get_text( $template, 'Enter description for the ' . $opt_type . ':' );
      } else {
	  $opt_desc = $this->get_text( 'Enter description for the ' . $opt_type . ':' );
      }
  }
  
  my $me = $jira->rest_get_single( '/myself' );

  my $endpoint = '/issue';
  my $params = { 'fields' => {
      'project' => { 'id' => $project_id },
      'summary' => $opt_title,
      'issuetype' => { 'id' => $issue_types{ $opt_type }->{ 'id' } },
		 }
  };
  if ( $opt_desc ) {
      $params->{ 'fields' }->{ 'description' } = $opt_desc;
  }
  if ( $opt_labels ) {
      $params->{ 'fields' }->{ 'labels' } = [ split( /,/, $opt_labels ) ];
  }
  if ( $opt_assign ) {
      $params->{ 'fields' }->{ 'assignee' }->{ 'name' } = $opt_assign;
  }
		 
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      chomp $_;
      die "** Error: Create issue failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "Crated issue " . join( "\n    ", map { $jira->substitute_format( "'$opt_title'" . ' as %F:key', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub get_template {
    my ( $this, $tmpl_name ) = @_;

    my $jira = $this->preference( 'jira_connector' );
    my $project = $this->preference( 'current_project' );

    my $app_data_path = $this->get_app_data_path() . '/issue_templates';
    my $tmpl_dir;
    foreach my $trypath ( $app_data_path . '/' . $project, $app_data_path ) { 
	next
	    if ( not -f "$trypath/${tmpl_name}.md" );
	open( my $tmpl_fh, '<', $trypath . '/' . ${tmpl_name} . '.md' )
	    or return '';
	my $filedat = join( '', <$tmpl_fh> );
	close $tmpl_fh;
	return $filedat;
    }
    if ( -f $app_data_path . '/Generic.md' ) {
	open( my $tmpl_fh, '<', $app_data_path . '/Generic.md'  )
	    or return '';
	my $filedat = join( '', <$tmpl_fh> );
	close $tmpl_fh;
	return $filedat;
    }
    return "";
}

sub cmd_asgiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_asgiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_asgiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_to_target,  );
  GetOptions (
      'help' => \$opt_help,
      'to=s' => \$opt_to_target,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing issue argument(s).\n";
  }
  
  if ( not $opt_to_target ) {
      return "Error: Missing assignee - use --to <user name> switch.\n";
  }

  my @results;								 
  foreach my $this_issue ( @ARGV ) {
      my $endpoint = "/issue/$this_issue/assignee";

      my $params = { 'name' => $opt_to_target };

      try {
	  $jira->rest_put( $endpoint, $params );
	  push( @results, $this_issue );
      } catch {
	  chomp $_;
	  print ucfirst "assign issue $this_issue to $opt_to_target failed: $_.\n";      
      };
  }
  print "Assigned issue(s) to $opt_to_target: " . join( "  \n", @results ) . "\n"; 

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_attiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_attiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_attiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_file,  );
  GetOptions (
      'help' => \$opt_help,
      'file|f=s' => \$opt_file,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      die "** Error: Missing issue argument.\n";
  }
  if ( not $opt_file ) {
      die "** Error: Missing file argument (--file <file to attach>).\n";
  }
  if ( not -r $opt_file ) {
      die "** Error: Cannot open file to attach \"$opt_file\".\n";
  }
  
  my $endpoint = '/issue/' . $subject . '/attachments';

  my $params = $opt_file;
  my @results;								 

  my $result_obj;
  try {
      $jira->add_extra_header( { 'X-Atlassian-Token' => 'no-check' } );
      $jira->cancel_header( qw( Content-Type ) );
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      chomp $_;
      die "attach file to issue failed: $_.\n";
  };
  my $result;
  try {
      $result = from_json( $result_obj->{ 'body' } );
  } catch {
      print $result_obj->{ 'body' } . "\n";
      return $stat;
  };
  push( @results, $result );
  print ucfirst "attach file to" . "d issue " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_cmtiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_cmtiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_cmtiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_comment,  );
  GetOptions (
      'help' => \$opt_help,
      'comment|c=s' => \$opt_comment,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }

  $opt_comment ||= $this->get_description( $opt_comment );
  $opt_comment ||= $this->get_text( 'Please enter your comment (Markdown allowed):' );

  my $endpoint = '/issue/' . $subject . '/comment';

  my $params = { 'body' => $opt_comment };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      chomp $_;
      die "** Error: Comment issue failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );

  print "Added comment to issue $subject.\n";
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


sub cmd_watiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_watiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_watiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_userid,  );
  GetOptions (
      'help' => \$opt_help,
      'userid=s' => \$opt_userid,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }
  if ( not $opt_userid ) {
      my $me = $jira->rest_get_single( '/myself' );
      $opt_userid = $me->{ 'name' };
  }
  
  my $endpoint = '/issue/' . $subject . '/watchers';

  my $params = {
      'username' => $opt_userid
  };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, '"' . $opt_userid . '"' );
  } catch {
      die "** Error: watch issue failed: $_.\n";
  };
  print ucfirst "Added watcher" . " to issue $subject.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_uwatiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_uwatiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_uwatiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_userid,  );
  GetOptions (
      'help' => \$opt_help,
      'userid=s' => \$opt_userid,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }
  if ( not $opt_userid ) {
      my $me = $jira->rest_get_single( '/myself' );
      $opt_userid = $me->{ 'name' };
  }
  
  my $endpoint = '/issue/' . $subject . '/watchers?username=' . $opt_userid;

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_delete( $endpoint );
  } catch {
      chomp $_;
      die "Unwatch issue $subject failed: $_\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "unwatch" . "ed issue $subject (removed user $opt_userid from issue subscribers).\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_transiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Issues_IF::gcli_transiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_transiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_to_target, $opt_no_comment, $opt_comment );
  GetOptions (
      'help' => \$opt_help,
      'to=s' => \$opt_to_target,
      'no-comment|nc' => \$opt_no_comment,
      'comment|c=s' => \$opt_comment,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }

  if ( not $opt_to_target ) {
      # show the possible transitions

      my $endpoint = '/issue/' . $subject . '/transitions';
      my $tx_data;
      try {
	  $tx_data = $jira->rest_get_single( $endpoint );
      } catch {
	  chomp $_;
	  die "** Error: Cannot get possible issue transitions for issue $subject: $_.\n";
      };
      print "Possible transitions for issue $subject:\n  ";
      print join( "\n  ", map { $_->{ 'id' } . ' to ' . $_->{ 'to' }->{ 'name' } .
				    ' (Op: ' . $_->{ 'name' } . ')' } 
		  @{ $tx_data->{ 'transitions' } } ) . "\n";
      return 0;
  }
  # a transition is actually requested.
  my $tx_id;
  try {
      $tx_id = $this->get_transition_id( $subject, $opt_to_target );
  } catch {
      chomp $_;
      die "** Error: Cannot transition $subject to $opt_to_target: $_.\n";
  };
  if ( not $opt_no_comment ) {
      $opt_comment ||= $this->get_description( $opt_comment );
      $opt_comment ||= $this->get_text( 'Please enter comment for issue transition (Markdown allowed):' );
  }
  my $endpoint = '/issue/' . $subject . '/transitions';

  my $params = {
      'transition' => { 'id' => $tx_id },
  };
  if ( $opt_comment ) {
      $params->{ 'update' }->{ 'comment' } = [
	  {
	      'add' => { 'body' => $opt_comment }
	  }
	  ];
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      chomp $_;
      die "** Error: transition issue failed: $_.\n";
  };
  push( @results, $subject );

  print "Moved issue(s) " . join( "\n ", @results ) . " to state $opt_to_target.\n"; 

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub get_transition_id {
    my ( $this, $issue_id, $transition ) = @_;

    my $jira = $this->preference( 'jira_connector' );
    my $endpoint = '/issue/' . $issue_id . '/transitions';
    my $tx_data;
    try {
	$tx_data = $jira->rest_get_single( $endpoint );
    } catch {
	chomp $_;
	die "** Error: Cannot get possible issue transitions for issue $issue_id: $_.\n";
    };
    my @transitions = grep { $_->{ 'to' }->{ 'name' } eq $transition }
    @{ $tx_data->{ 'transitions' } };

    my $tx;
    if ( @transitions ) {
	$tx = shift @transitions;
    } else {
	die "Transition to $transition not possible.\n";
    }
    return $tx->{ 'id' };
}

sub cmd_get_issue {
    my ( $this, $issue_id ) = @_;

    my $json = JSON->new->allow_nonref;

    my $jira = $this->preference( 'jira_connector' );

    my $endpoint = "/issue/$issue_id";
    my $result_obj = $jira->rest_get_single( $endpoint );
    
    return $result_obj;
}

sub assert_project_id {
    my ($this, $pid ) = @_;

    my $jira = $this->preference( 'jira_connector' );

    my $project;
    try {
	$project = $jira->rest_get_single( '/project/' . $pid )
    } catch {
	die "Cannot determine id for project \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $project->{ 'key' } );
    $this->set( 'current_project_id', $project->{ 'id' } );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project->{ 'id' };
}

1;
