package GitLabCLI::Commits;

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

use  GitLabCLI::Commits_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lscmit', 'cmd_lscmit' ],
     ['desccmit', 'cmd_desccmit' ], 
     ['diffcmit', 'cmd_diffcmit' ], 
		 ]);
  
  return $this;
}


sub cmd_lscmit {
  my $stat = "";

  my $this = shift;


  my $long_usage = GitLabCLI::Commits_IF::gcli_lscmit_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lscmit ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_limit, $opt_in, $opt_ref, $opt_since, $opt_until,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'limit|max=i' => \$opt_limit,
      'in=s' => \$opt_in,
      'branch|b=s' => \$opt_ref,
      'ref=s' => \$opt_ref,
      'since=s' => \$opt_since,
      'until=s' => \$opt_until,
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
      die "list commit requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/repository/commits';
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @params;
  if ( $opt_since ) {
      push( @params, "since=$opt_since" );
  }
  if ( $opt_until ) {
      push( @params, "until=$opt_until" );
  }
  if ( $opt_ref ) {
      push( @params, "ref_name=$opt_ref" );
  }
  if ( @params ) {
      $endpoint .= '?' . join( '&', @params );
  }
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) };
  if ( $filter_re ) {
      @results = grep{ $_->{ 'title' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_limit ) {
      @results = splice( @results, 0, $opt_limit );
  }

  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $default_format = '%F:short_id %F:committed_date %F:title / [by %F:author_name]';
      print join( "\n", map {
	  my @f = split( /\s/, $gitlab->substitute_format( $default_format, $_ ), 3);
	  $f[1] =~ s/\..*//; join( ' ', @f )
		  } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_desccmit {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Commits_IF::gcli_desccmit_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_desccmit ';
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
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing commit argument.\n";
  }

  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe commit requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/repository/commits/:commit';
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:commit/\/$subject/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  my $cmit_diff = $gitlab->rest_get_single( $endpoint . '/diff' );
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
      print join( "\n",  map { $_->{ 'new_path' } . "\n" . '=' x length($_->{ 'new_path' }) . "\n$_->{ diff }\n"  } @{ $cmit_diff } ) . "\n";  
  } else {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
      print "Modified files:\n" . join( "\n",  map { $_->{ 'new_path' } } @{ $cmit_diff } ) . "\n";  
  }
  if ( $opt_long ) {
      my $cmit_diff = $gitlab->rest_get_single( $endpoint . '/diff' );
      if ( ref $cmit_diff ) {
	  print join( "\n",  map { $_->{ 'new_path' } . "\n" . '=' x length($_->{ 'new_path' }) . "\n$_->{ diff }\n"  } @{ $cmit_diff } ) . "\n";
      }
#      print $json->pretty->encode( $cmit_diff ) . "\n";
  }
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_diffcmit {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Commits_IF::gcli_diffcmit_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_diffcmit ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_from_original, $opt_to_target, $opt_in, $opt_filter );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'from=s' => \$opt_from_original,
      'to=s' => \$opt_to_target,
      'in=s' => \$opt_in,
      'filter=s' => \$opt_filter,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  if ( @ARGV ) {
      if ( not $opt_from_original ) {
	  $opt_from_original = shift @ARGV;
      }
  }
  if ( @ARGV ) {
      if ( not $opt_to_target ) {
	  $opt_to_target = shift @ARGV;
      }
  }
  if ( not $opt_from_original ) {
      die "Error: No base commit was specified for the compare. Use option --from <commit>.\n";
  }
  if ( not $opt_to_target ) {
      die "Error: No target commit was specified for the compare. Use option --to <commit>.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "diff|compare|comp commit requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = "/projects/:id/repository/compare?from=$opt_from_original&to=$opt_to_target";
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  my $diffs = $result_obj->{ 'diffs' };
  push( @results, @{ $result_obj->{ 'diffs' } } );
  if ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      if ( @results ) {
	  print "A total of " . scalar( @results ) . 
	      " differences between commits from $opt_from_original to $opt_to_target:\n";
	  my ($a, $d, $m, $r ) = ( 0, 0, 0, 0 );
	  $a = grep { $_->{ 'new_file' } } @results;
	  $d = grep { $_->{ 'deleted_file' } } @results;
	  $r = grep { $_->{ 'renamed_file' } } @results;
	  $m = scalar @results - ( $a + $d + $r );
	  print "  $m files modified\n  $a files added\n  $d files deleted\n  $r files renamed\n";
	  print '=' x length( "A total of " . scalar( @results ) . 
			      " differences between commits from $opt_from_original to $opt_to_target:" ) . "\n";
      }
      my ( $all_diffs, $new, $del, $mod, $ren );
      if ( not $opt_filter ) {
	  $all_diffs = 1;
      } else {
	  $new = ( $opt_filter =~ m/a/i );
	  $del = ( $opt_filter =~ m/d/i );
	  $mod = ( $opt_filter =~ m/m/i );
	  $ren = ( $opt_filter =~ m/r/i );
      }
      if ( not $opt_short ) {
	  foreach my $d ( @results ) {
	      if ( $d->{ 'renamed_file' } and ( $all_diffs or $ren ) ) {
		  print "R $d->{ 'old_path' } -> $d->{ 'new_path' }\n";
		  next;
	      }
	      if ( $d->{ 'deleted_file' } and ( $all_diffs or $del ) ) {
		  print "D $d->{ 'old_path' }\n";
		  next;
	      }
	      if ( $d->{ 'new_file' } and ( $all_diffs or $new ) ) {
		  print "A $d->{ 'new_path' }\n";
		  next;
	      }
	      next
		  if ( not $all_diffs and ( $d->{ 'new_file' } or $d->{ 'deleted_file' } or $d->{ 'renamed_file' } ));
	      if ( $all_diffs or $mod ) {
		  print "M $d->{ 'old_path' }\n";
	      }
	  }
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
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
