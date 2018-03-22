package GitLabCLI::Issues;

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
use URL::Encode::XS qw( url_encode url_decode );
use File::Basename;
use MIME::Base64 qw( decode_base64 );

use  GitLabCLI::Issues_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsiss', 'cmd_lsiss' ],
     ['lsmyiss', 'cmd_lsmyiss' ],
     ['lstmpiss', 'cmd_lstmpiss' ],
     ['desciss', 'cmd_desciss' ],
     ['addiss', 'cmd_addiss' ],
     ['deliss', 'cmd_deliss' ],
     ['asgiss', 'cmd_asgiss' ],
     ['crbriss', 'cmd_crbriss' ],
     ['cmtiss', 'cmd_cmtiss' ],
     ['watiss', 'cmd_watiss' ],
     ['uwatiss', 'cmd_uwatiss' ],
     ['transiss', 'cmd_transiss' ],
		 ]);

  return $this;
}


sub cmd_lsiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_lsiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_limit,
       $opt_in, $opt_board, $opt_filter, $opt_all,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'limit|max=i' => \$opt_limit,
      'in=s' => \$opt_in,
      'on|on-board|board=s' => \$opt_board,
      'filter=s' => \$opt_filter,
      'all|a' => \$opt_all,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  # verify project id
  my ( $project_id, $group_id );
  if ( $opt_in and $opt_board ) {
      die "** Error: Options --board, and --in are incompatible, please use only one of them.\n";
  }
  # in gitlab CE, a board is tied 1:1 to a project
  $opt_in ||= $opt_board;
  if ( $opt_in ) {
      try {
	  $project_id = $gitlab->get_project_id( $opt_in );
      };
      $project_id or try {
	  $group_id = $gitlab->get_group_id( $opt_in, 'exact-match' => 1 );
      } catch {
	  chomp $_;
	  die "** Error: Unknown project or group \"$opt_in\": $_\n";
      };
  }

  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  if ( defined( $opt_filter ) + defined( $opt_board ) + defined( $opt_all ) > 1 ) {
      die "** Error: Options --filter, and --all are incompatible with --on-board.
Please use only one of these options.\n";
  }

  $opt_in ||= $this->preference( 'current_project' )
      unless ( $opt_all );
  
  my $board_lists;
  if ( $opt_board ) {
      die "** Error: List issues on board requires a defined project context. Use option --in <project>.\n"
	  if ( not $project_id );
      my $board = $gitlab->rest_get_list( '/projects/' . $project_id . '/boards' );
      die "** Error: No board defined for project $opt_in.\n"
	  if ( not @{ $board } );
      $board_lists = [ map { [ $_->{ 'position' }, $_->{ 'label' }->{ 'name' } ] } @{ $board->[0]->{ 'lists' } } ];
      $opt_filter = 'labels=' . join( '|', map { $_->[1] } @{ $board_lists } );
  }
  
  my $endpoint = defined $project_id ? "/projects/$project_id/issues" :
      ( defined $group_id ? "/groups/$group_id/issues" : '/issues' );
  my @query;
  if ( not $opt_all ) {
      push( @query, 'state=opened' );
  }
  my @filter_query;
  if ( $opt_filter ) {
      push( @query, 'scope=all' );
      push( @filter_query, $this->filter2query( $opt_filter ) );
  }
  my @results;
  
  if ( @filter_query ) {
      foreach my $this_term ( @filter_query ) {
	  push( @results, @{ $gitlab->rest_get_list( $endpoint . '?' . join( '&', @query, @{ $this_term } ) ) } );
      }
      # remove possible doubles
      my %reg;
      foreach my $iss ( @results ) {
	  $reg{ $iss->{ 'iid' } } = $iss;
      }
      @results = sort { $a->{ 'created_at' } cmp $b->{ 'created_at' } } values %reg;
  } else {
      @results = @{ $gitlab->rest_get_list( $endpoint . ( scalar @query ? '?' . join( '&', @query ) : '' ) ) };
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'title' } =~ m/${filter_re}/ } @results;
  }
  if ( not $opt_long ) {
      foreach my $r ( @results ) {
	  $r->{ 'created_at' } = $this->short_date( $r->{ 'created_at' } );
      }
  }
  if ( $opt_board ) {
      my $pinfo = $gitlab->get_project_from_id( $project_id );
      print '* Issue board "' . $pinfo->{ 'name' } . "\":\n";
      foreach my $this_colspec ( sort { $a->[0] <=> $b->[0] } @{ $board_lists } ) {
	  print "=== $this_colspec->[1] ===\n";
	  my $col_states = '^(' . $this_colspec->[1] . ')$';
	  my @col_results = grep { grep { $_ =~ m/${col_states}/ } @{ $_->{ 'labels' } } } @results;
	  if ( @col_results ) {
	      if ( $opt_format ) {
		  print join( "\n", map { $gitlab->substitute_format( $opt_format, $_, 'check_mapped' => 1 ) } @col_results ) . "\n"; 
	      } elsif ( $opt_long ) {
		  print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @col_results ) . "\n";
	      } else {
		  my $norm_fmt_open = '%F:iid / %Pn: (%F:labels) %F:title - by %F:author.name on %F:created_at';
		  my $norm_fmt_closed = '%F:iid / %Pn: [closed] %F:title - by %F:author.name on %F:created_at';
		  print join( "\n", map { 
		      ( $_->{ 'state' } eq 'closed' ) ? 
			  $gitlab->substitute_format( $norm_fmt_closed, $_ ) :
			  $gitlab->substitute_format( $norm_fmt_open, $_ ) 
			      } @col_results ) . "\n";
	      }
	  } else {
	      print "<Column is empty - no issues>\n";
	  }
	  print "\n";
      }
  } elsif ( $opt_format ) {
      print 'Found ' . scalar @results . ' issues:' . "\n";
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n";
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print 'Found ' . scalar @results . ' issues:' . "\n";
      print "(formatting output)\n"
	  if ( scalar @results > 20 );
      my $norm_fmt_open = '%F:iid / %Pn: (%F:labels) %F:title - by %F:author.name on %F:created_at';
      my $norm_fmt_closed = '%F:iid / %Pn: [closed] %F:title - by %F:author.name on %F:created_at';
      print join( "\n", map { 
	  ( $_->{ 'state' } eq 'closed' ) ? 
	      $gitlab->substitute_format( $norm_fmt_closed, $_ ) :
	      $gitlab->substitute_format( $norm_fmt_open, $_ ) 
		  } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_lsmyiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_lsmyiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsmyiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_userid, $opt_format, $opt_all, $opt_filter, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'userid=i' => \$opt_userid,
      'format|fmt=s' => \$opt_format,
      'all|a' => \$opt_all,
      'filter=s' => \$opt_filter,
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
  my $endpoint = '/issues';
  
  my @query;
  if ( not $opt_all ) {
      push( @query, 'state=opened' );
  }
  my @filter_query;
  $opt_filter .= 'scope=assigned-to-me|created-by-me';
  if ( $opt_filter ) {
      push( @filter_query, $this->filter2query( $opt_filter ) );
  }
  my @results;
  if ( @filter_query ) {
      foreach my $this_term ( @filter_query ) {
	  push( @results, @{ $gitlab->rest_get_list( $endpoint . '?' . join( '&', @query, @{ $this_term } ) ) } );
      }
      # remove possible doubles
      my %reg;
      foreach my $iss ( @results ) {
	  $reg{ $iss->{ 'iid' } } = $iss;
      }
      @results = sort { $a->{ 'created_at' } cmp $b->{ 'created_at' } } values %reg;
  } else {
      @results = @{ $gitlab->rest_get_list( $endpoint . @query ? '?' . join( '&', @query ) : '' ) };
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( not $opt_long ) {
      foreach my $r ( @results ) {
	  $r->{ 'created_at' } = $this->short_date( $r->{ 'created_at' } );
      }
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n";
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_fmt_open = '%F:iid / %Pn: (%f:labels) %F:title - by %F:author.name on %F:created_at';
      my $norm_fmt_closed = '%F:iid / %Pn: [closed] %F:title - by %F:author.name on %F:created_at';
      print join( "\n", map { 
	  ( $_->{ 'state' } eq 'closed' ) ? 
	      $gitlab->substitute_format( $norm_fmt_closed, $_ ) :
	      $gitlab->substitute_format( $norm_fmt_open, $_ ) 
		  } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub filter2query {
    my ( $this, $filter ) = @_;

    # $filter = 'labels=foo,bar;milestone=1.0.0;author=<id or name>;assigned'
    # GET /issues?state=opened
    # GET /issues?state=closed
    # GET /issues?labels=foo
    # GET /issues?labels=foo,bar
    # GET /issues?labels=foo,bar&state=opened
    # GET /issues?milestone=1.0.0
    # GET /issues?milestone=1.0.0&state=opened
    # GET /issues?iids[]=42&iids[]=43
    # GET /issues?author_id=5
    # GET /issues?assignee_id=5
    # GET /issues?my_reaction_emoji=star

    my $gitlab = $this->preference( 'gitlab_connector' );

    my @terms = split( /;/, $filter );
    my @norm_terms;
    my %xterm;
    foreach my $this_term ( @terms ) {
	my ( $key, $val ) = split( /=/, $this_term );
	$key = $this->norm_key( $key );
	my @or_vals = split( /\|/, $val );
	if ( $key =~ m/_id$/ ) {
	    @or_vals = map { $gitlab->get_user_id( $_ ) } @or_vals;
	}
	push( @norm_terms, { $key => \@or_vals } );
    }
    # build cartesian product of @norm_terms
    my @result_terms = cartesian( @norm_terms );

    return @result_terms;
}

sub cartesian {
    my @terms = @_;

    my $term = shift @terms;
    my ( $k, $vals ) = %{ $term };
    my @result;
    foreach my $v ( map { url_encode( $_ ) } @{ $vals } ) {
	if ( @terms ) {
	    my @ct = cartesian( @terms );
	    push( @result, map { [ "$k=$v", ref $_ ? @{ $_ } : $_ ] } @ct );
	} else {
	    push( @result, [ "$k=$v" ] );
	}
    }
    return @result;
}

sub norm_key {
    my ( $this, $raw_key ) = @_;

    my $key_map = {
	'label' => 'labels',
	'lbl' => 'labels',
	'mstone' => 'milestone',
	'release' => 'milestone',
	'rel' => 'milestone',
	'author' => 'author_id',
	'reporter' => 'author_id',
	'author' => 'author_id',
	'assigned' => 'assignee_id',
	'assigned_to' => 'assignee_id',
	'assgn' => 'assignee_id',
    };
    my $nkey = $key_map->{ $raw_key };
    if ( not $nkey and ( $raw_key =~ m/(\s+)s$/ ) ) {
	$nkey = $key_map->{ $1 };
    }
    $nkey ||= $raw_key;

    return $nkey;
}

sub cmd_lstmpiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_lstmpiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lstmpiss ';
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
      die "list templates for issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/repository/tree';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint . '?path=.gitlab/issue_templates' ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }

  if ( @results ) {
      if ( $opt_long ) { 
	  print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
      } else {
	  print join( "\n", map { basename( $_->{ 'name' }, '.md' ) } @results ) . "\n";
      }
  } else {
      print "No issue templates in project $opt_in.\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_desciss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_desciss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_desciss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_in, $opt_with,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      'with=s' => \$opt_with,
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
      return "Error: Missing issue argument.\n";
  }

  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/issues/' . $subject;

  my @results;

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  if ( $opt_with ) {
      foreach my $res ( @results ) {
	  if ( $this->with( 'Comments', $opt_with ) ) {	 
	      $res->{ 'comments' } = $gitlab->condense_comments( 
	      $gitlab->rest_get_list( '/projects/' . $project_id . 
				      '/issues/' . $res->{ 'iid' } . 
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
      # TODO / FIXME - define custom normal format
      my $norm_fmt_open = '%F:iid (%f:labels) -  %F:title\nReporter: %F:author.username (%F:author.name)\nAssigned to: %f:assignees.username (%f:assignees.name)\n';
      my $norm_fmt_closed = '%F:iid [closed] -  %F:title\nReporter: %F:author.username (%F:author.name)\nAssigned to: %f:assignees.username (%f:assignees.name)\n';
      my $default_format = '';

      # description is put out by default - unless explicitly shunned
      $default_format .= '\nDESCRIPTION:\n============\n%D\n'
	  unless ( $this->without( 'Description', $opt_with ) );
      # comments are not listed - unless explicitly requested
      $default_format .= '\nCOMMENTS:\n' . '=' x length( 'COMMENTS:' ) . '\n  %F:comments\n'
	  if ( $this->with( 'Comments', $opt_with ) );
      print join( "\n", map { 
	  ( $_->{ 'state' } eq 'closed' ) ? 
	      $gitlab->substitute_format( $norm_fmt_closed . $default_format, $_ ) :
	      $gitlab->substitute_format( $norm_fmt_open . $default_format, $_ ) 
		  } @results ) . "\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_addiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_labels, $opt_title, $opt_desc, $opt_assign, $opt_milestone,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'labels|type=s' => \$opt_labels,
      'title=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'assign-to=s' => \$opt_assign,
      'milestone=s' => \$opt_milestone,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "new issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  $opt_title ||= $this->ask( "Issue headline: " );
  die "** Error: Please provide a title for the new issue.\n"
      if ( not $opt_title );
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }

  my $endpoint = '/projects/:id/issues';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  if ( not $opt_desc ) {
      if ( my $template = $this->get_template( $opt_labels ? $opt_labels : 'Generic' ) ) {
	  $opt_desc = $this->get_text( $template, 'Enter description of the new issue:' );
      } else {
	  $opt_desc = $this->get_text( '/title ' . $opt_title, 
				       'Enter description of the new issue:' );
      }
  }
  
  my $params = {
      'id' => $project_id,
      'title' => $opt_title,
      'description' => $opt_desc,
  };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "new issue failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "Create" . "d issue " . join( "\n    ", map { $gitlab->substitute_format( '%F:iid: %F:title', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub get_template {
    my ( $this, $tmpl_name ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );
    my $project_id = $this->preference( 'current_project_id' );

    my $endpoint = '/projects/' . $project_id . '/repository/tree?path=.gitlab/issue_templates';
    my @tmpl_files = @{ $gitlab->rest_get_list( $endpoint ) };

    my $tmpl_re;
    if ( ref $tmpl_name eq 'ARRAY' ) {
	$tmpl_re = '(' . join( '|', @{ $tmpl_name  } ) . ')';
    } else {
	$tmpl_re = '(' . join( '|', split( /,/, $tmpl_name ) ) . ')';
    }
    my @templ = grep{ $_->{ 'name' } =~ m/${tmpl_re}/ } @tmpl_files;

    if ( @templ ) {
	$endpoint = '/projects/' . $project_id . '/repository/files/' . 
	    url_encode( '.gitlab/issue_templates/' . 
			 $templ[ 0 ]->{ 'name' } ) . '?ref=master'; 
	my $filedat = $gitlab->rest_get_single( $endpoint );
	return decode_base64( $filedat->{ 'content' } );
    }
    return "";
}

sub cmd_deliss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_deliss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deliss ';
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
      return "Error: Missing issue argument.\n";
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $issue;
  try {
      $issue = $gitlab->rest_get_single( '/projects/' . $project_id .
					 '/issues/' . $subject );
  } catch {
      chomp $_;
      die "** Error: No such issue with iid $subject: $_\n";
  };
  if ( not ( $opt_force or $this->confirm( "Really remove issue $subject?\n[\"$issue->{ 'title' }\"]", 'no' ))) {
      $this->print( ucfirst "issue $subject not deleted.\n" );
      return $stat;
  }

  my $endpoint = '/projects/' . $project_id . '/issues/' . $subject;

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      die "No such issue: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d issue $subject (\"$issue->{ 'title' }\").\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_asgiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_asgiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_asgiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_to_target, $opt_comment, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'to=s' => \$opt_to_target,
      'comment|c=s' => \$opt_comment,
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
      return "Error: Missing issue argument.\n";
  }

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "assign issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  if ( not $opt_to_target ) {
      return "Error: Missing assignee (use --to <username> to assign).\n";
  }
  my $comment = $opt_comment;
  $comment ||= "Assign to user $opt_to_target.\n";
  $comment .= "/assign $opt_to_target\n";

  # dispatch the assign command to 'comment issue'
  @ARGV = ( '--comment', $comment, '--in', $project_id, $subject );

  return $this->cmd_cmtiss();
}


sub cmd_crbriss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_crbriss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_crbriss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_for_id, $opt_in,  );
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
      return "Error: Missing issue argument.\n";
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "** Error: Create branch for issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # if "create branch for <issue>" is given, we dispatch the command to 
  # "create branch --for <issue-id> [--in <project>]"
  my $did_it = 0;
  try {
      use GitLabCLI::Branches;
      @ARGV = ( '--for', $subject );
      GitLabCLI::Branches->new( $this->frame() )->cmd_mkbr( );
      $did_it = 1;
  } catch {
      die "** Error: Could not dispatch call to 'create branch --for $subject': $_\n";
  };
  return $stat;
}

sub cmd_cmtiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_cmtiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_cmtiss ';
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
      return "Error: Missing issue argument.\n";
  }

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "comment issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  $opt_comment ||= $this->get_description( $opt_comment );
  $opt_comment ||= $this->get_text( 'Please enter your comment (Markdown allowed):' );
  
  my $endpoint = '/projects/' . $project_id . '/issues/' . $subject . '/notes';

  my $params = {
      'body'  => $opt_comment,
  };
  my @results;

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "comment issue failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "comment" . "ed issue $subject.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_transiss {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Issues_IF::gcli_transiss_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_transiss ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_from_original, $opt_to_target, $opt_no_comment, $opt_in, $opt_comment,  );
  GetOptions (
      'help' => \$opt_help,
      'from=s' => \$opt_from_original,
      'to=s' => \$opt_to_target,
      'no-comment|nc' => \$opt_no_comment,
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
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "comment issue requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing issue argument.\n";
  }
  my $comment = $opt_comment;
  if ( $this->preference( 'verb' ) =~ m/^(close|reopen)$/ ) {
      $comment ||= '[' . ( $this->preference( 'verb' ) eq 'close' ? 'closing' : 'reopening' ) .
	  ' issue]' . "\n";
      $comment .= '/' . $this->preference( 'verb' ) . "\n";
  } else {
      $opt_from_original = $this->verify_label( $opt_from_original );
      $opt_to_target = $this->verify_label( $opt_to_target );
      if ( not ( $opt_from_original and $opt_to_target ) ) {
	  die "** Error: Need to specify from- and to-states for moving issues in workflow.\n";
      }
      try {
	  $this->assert_from_state( $subject, $opt_from_original );
      } catch {
	  chomp $_;
	  die "** Error: Issue $subject cannot be promoted to state $opt_to_target: $_\n";
      };
      try {
	  $this->assert_to_state( $opt_to_target );
      } catch {
	  chomp $_;
	  die "** Error: Issue $subject cannot be promoted to state $opt_to_target: $_\n";
      };
      $comment ||= "Promote issue from state $opt_from_original to $opt_to_target.\n";
      $comment .= "/unlabel ~\"$opt_from_original\"\n";
      $comment .= "/label ~\"$opt_to_target\"\n";
  }
  

  # dispatch the labeling command to 'comment issue'
  @ARGV = ( '--comment', $comment, '--in', $project_id, $subject );

  return $this->cmd_cmtiss();
}

sub assert_from_state {
    my ( $this, $issue_id, $label ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $project_id = $this->preference( 'current_project_id' );

    my $endpoint = '/projects/' . $project_id . '/issues/' . $issue_id;
    my $issue = $gitlab->rest_get_single( $endpoint );
    my @lbls = grep { $_ =~ m/${label}/i } @{ $issue->{ 'labels' } };

    die "Issue is not labelled \"$label\".\n"
	unless ( @lbls );

    return;
}

# return label name for id or die
sub verify_label {
    my ( $this, $label ) = @_;

    # if the label's name is given we 'believe' it
    return $label
	if ( not $label =~ m/^\d+$/ );

    my $gitlab = $this->preference( 'gitlab_connector' );
    my $project_id = $this->preference( 'current_project_id' );
    my $lbls = $gitlab->rest_get_list( '/projects/' . $project_id . '/labels' );
    my $lbl;
    if ( ref $lbls eq 'ARRAY' ) {
	my @lbl = grep { $_->{ 'id' } == $label } @{ $lbls };
	if ( @lbl ) {
	    $lbl = shift @lbl;
	}
    }
    die "No label found with id $label\n"
	if ( not $lbl );

    return $lbl->{ 'name' };
}

sub assert_to_state {
    my ( $this, $label ) = @_;

    my $gitlab = $this->preference( 'gitlab_connector' );

    my $project_id = $this->preference( 'current_project_id' );

    my $endpoint = '/projects/' . $project_id . '/labels';
    my @results;								 
    @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
    @results = grep{ $_->{ 'name' } =~ m/${label}/i } @results;
    
    die "Target state \"$label\" does not exist (no such label defined).\n"
	unless ( @results );

    return;
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
