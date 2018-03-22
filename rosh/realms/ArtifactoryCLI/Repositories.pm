package ArtifactoryCLI::Repositories;

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

use  ArtifactoryCLI::Repositories_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsrep', 'cmd_lsrep' ],
     ['descrep', 'cmd_descrep' ],
     ['mkrep', 'cmd_mkrep' ],
     ['rmrep', 'cmd_rmrep' ],
     ['editrep', 'cmd_editrep' ], 
		 ]);
  
  return $this;
}

my $get_file_details;
my $time_ordered;
my $size_ordered;
my $reverse_order;

sub cmd_lsrep {
  my $stat = "";

  my $this = shift;

  $get_file_details = 0;
  
  my $long_usage = ArtifactoryCLI::Repositories_IF::atfcli_lsrep_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsrep ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_all, $opt_my_repos,
  $opt_recursive, $opt_repo_class, $opt_time_ordered,
       $opt_reverse_ordered, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'all|a' => \$opt_all,
      'my' => \$opt_my_repos,
      'recursive|rec|R' => \$opt_recursive,
      'class=s' => \$opt_repo_class,
      't' => \$opt_time_ordered,
      'r' => \$opt_reverse_ordered,
      'format|fmt=s' => \$opt_format,
      );
  
  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  
  my $repo_classes = {
      'v' => 'VIRTUAL',
      'virt' => 'VIRTUAL',
      'virtual' => 'VIRTUAL',
      'VIRTUAL' => 'VIRTUAL',
      'r' => 'REMOTE',
      'rem' => 'REMOTE',
      'remote' => 'REMOTE',
      'REMOTE' => 'REMOTE',
      'l' => 'LOCAL',
      'loc' => 'LOCAL',
      'local' => 'LOCAL',
      'LOCAL' => 'LOCAL',
  };

  # if we want to see interesting repos only, restrict to local
  # also include all virtual repos that have one of our locally
  # accessible repos in its configuration!  
  my @my_repositories;
  if ( $opt_my_repos ) {
      if ( $artifactory->is_admin() ) {
	  warn "** Running in admin mode - option '--my' ignored.\n";
	  $opt_my_repos = undef;
      }
  }
  
  if ( $opt_repo_class ) {
      if ( exists $repo_classes->{ lc $opt_repo_class } ) {
	  $opt_repo_class =  $repo_classes->{ $opt_repo_class };
      } else {
	  die "Invalid class of repository requested (\"$opt_repo_class\") - use LOCAL (l), REMOTE (r), or VIRTUAL (v).\n";
      }
  }
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
      $get_file_details = 1;
  }

  if ( $opt_format ) {
      $opt_short = '';
      $get_file_details = 1;
  }

  my $endpoint = '/repositories';

  my @results;								 
  my @list_repo_contents;

  @results = @{ $artifactory->rest_get_list( $endpoint ) };
  if ( $filter_re ) {
      @results = grep{ $_->{ 'key' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_repo_class ) {
      @results = grep{ $_->{ 'type' } eq ${opt_repo_class} } @results;
  } 
  if ( $get_file_details ) {
      foreach my $this_repo ( @results ) {
	  my $reponame = $this_repo->{ 'key' };
	  my ( $details, $effective_perm );
	  try {
	      $details = $artifactory->rest_get_single( '/repositories/' . $reponame );
	  } catch {
	      chomp $_;
	      die "**Error: Cannot obtain details for repository $reponame: $_.\n";
	  };
	  foreach my $key ( keys %{ $details } ) {
	      $this_repo->{ $key } = $details->{ $key }
	      if ( not exists  $this_repo->{ $key } );
	  }
      }
  }
  
  if ( @ARGV == 1 ) {
      # if the only argument exactly matches a repo name, interpret this 
      # as request to list the contents of the repository
      my $reponame = ( $ARGV[0] =~ m/\// ) ? (split( '/',  $ARGV[0] ))[0] : $ARGV[0];
      @list_repo_contents = grep{ $_->{ 'key' } eq $reponame } @results;
      if (( @list_repo_contents == 0 ) and ( $ARGV[0] =~ m/\// )) {
	  return "**Error: Invalid repository given. $reponame is unknown.\n";
      }
  }
  if ( @list_repo_contents ) {
      my $repo_key = $ARGV[0];
      @results = @{ $artifactory->rest_get_single( '/storage/' . $repo_key )->{ 'children' } };
      if ( @results ) {
	  print "$repo_key:\n";
	  foreach my $entry ( @results ) {
	      my $name = $entry->{ 'uri' };
	      $name =~ s/^\// /;
	      if ( $get_file_details ) {
		  if ( not $entry->{ 'folder' } ) {
		      my $details = $artifactory->rest_get_single( '/storage/' . $repo_key . '/' . $name );
		      $details->{ 'created' } =~ s/\..*//;
		      foreach my $key ( keys %{ $details } ) {
			  $entry->{ $key } = $details->{ $key }
			  if ( not exists  $entry->{ $key } );
		      }
		  }
	      }
	  }
	  if ( $time_ordered ) {
	      @results = sort { $a->{ 'created' } cmp $b->{ 'created' } } @results;
	  }
	  if ( $size_ordered ) {
	      @results = sort { $a->{ 'size' } <=> $b->{ 'size' } } @results;
	  }
	  if ( $reverse_order ) {
	      @results = reverse @results;
	  }
	  foreach my $entry ( @results ) {
	      my $name = $entry->{ 'uri' };
	      $name =~ s/^\// /;
	      print $name;
	      if ( $entry->{ 'folder' } ) {
		  print "/\n";
	      } else {
		  if ( $get_file_details ) {
		      print "  $entry->{ 'created' } by $entry->{ 'createdBy' } (" .
			  short_size($entry->{ 'size' }) . ')'; 
		  }
		  print "\n";
	      }
	  }
	  if ( $opt_recursive ) {
	      foreach my $entry ( @results ) {
		  next
		      if ( not $entry->{ 'folder' } );
		  print "\n";
		  $this->print_folder_tree( $repo_key, $entry );
	      }
	  }
      }
      return $stat;
  }
  foreach my $repo ( @results ) {
      next
	  unless ( $repo->{ 'type' } eq 'LOCAL' );
      my $key = $repo->{ 'key' };
      my @child = @{ $artifactory->rest_get_single( '/storage/' . $key )->{ 'children' } };
      $repo->{ 'num_child' } = scalar @child ? scalar @child . ' entries' : 'empty';
      my $access = $this->is_public( $repo );
      if ( defined $access ) {
	  $repo->{ 'access' } = $access ? 'public' : 'restricted';
      }
  }
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'key' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my @loc_repos =  sort{ $a->{ 'key' } cmp $b->{ 'key' } }
      grep{ $_->{ 'type' } eq 'LOCAL' } @results;
      if ( $opt_my_repos ) {
	  @loc_repos =  sort{ $a->{ 'key' } cmp $b->{ 'key' } }
	  grep{ defined $_->{ 'access' } } @loc_repos;
	  @my_repositories = map { $_->{ 'key' } } @loc_repos;
      }
      if ( @loc_repos ) {
	  print "Local repositories:\n" . '==================================================' . "\n";
	  print join( "\n", map { $artifactory->substitute_format( '%F:key [access: %F:access] (%F:num_child)', $_ ) } @loc_repos ) . 
	      "\n*Got " . scalar @loc_repos . " repositories.\n\n";
      }
      if ( not $opt_my_repos ) {
	  my @rem_repos =  sort{ $a->{ 'key' } cmp $b->{ 'key' } }
	  grep{ $_->{ 'type' } eq 'REMOTE' } @results;
	  if ( @rem_repos ) {
	      print "Remote repositories:\n" . '==================================================' . "\n";
	      print join( "\n", map { $artifactory->substitute_format( '%F:key - %F:url', $_ ) } @rem_repos ) . 
		  "\n*Got " . scalar @rem_repos . " repositories.\n\n";
	  }
      }
      my @virt_repos =  sort{ $a->{ 'key' } cmp $b->{ 'key' } }
      grep{ $_->{ 'type' } eq 'VIRTUAL' } @results;
      if ( @my_repositories ) {
	  # get details of each local repo, and search if the any of
	  # our @local_repos matches the configured content repos of
	  # the virtual.
	  #
	  # this call adds configured repositories
	  select( STDOUT );
	  $| = 1;
	  print "[probing virtual repositories...]\r";
	  $this->get_repo_details( \@virt_repos );
	  print "                                 \r";
	  $| = 0;
	  my $my_repo_re = '^(' . join('|', @my_repositories ) . ')$';
	  my @my_virtuals;
	  foreach my $vr ( @virt_repos ) {
	      push( @my_virtuals, $vr )
		  if ( grep{ $_ =~ m/$my_repo_re/ } @{ $vr->{
		      'repositories' } } );
	  }
	  @virt_repos = @my_virtuals;
      }
      if ( @virt_repos ) {
	  print "Virtual repositories:\n" . '==================================================' . "\n";
	  print join( "\n", map { $artifactory->substitute_format( '%F:key - %F:url', $_ ) } @virt_repos ) . 
	      "\n*Got " . scalar @virt_repos . " repositories.\n";
      }
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub get_repo_details {
    my ( $this, $repo_list ) = @_;

    my $artifactory = $this->preference( 'atf_connector' );
    my $repo;
    foreach my $r ( @{ $repo_list } ) {
	try {
	    $repo = $artifactory->rest_get_single( '/repositories/'
						   . $r->{ 'key' } );
	    $r->{ 'repositories' } = $repo->{ 'repositories' };
	} catch {
	    die "**Error: Invalid repository given. $r->{ 'key' } is unknown.\n";
	};
    }
    return $this;
}

sub is_public {
    my ( $this, $repo_obj ) = @_;

    my $artifactory = $this->preference( 'atf_connector' );
#    return 0
#	if ( not $artifactory->is_admin() );
    
    my $public;
    if (( $repo_obj->{ 'rclass' } eq 'local' ) or ( $repo_obj->{ 'type' } eq 'LOCAL' ) ) {
	#/api/storage/libs-release-local/org/acme?permissions
	my $effective_perm;
	try {
	    $effective_perm = $artifactory->rest_get_single( '/storage/' . $repo_obj->{ 'key' } . 
							     '?permissions' );
	    if ( grep { $_ =~ m/anonymous/ } keys %{ $effective_perm->{ 'principals' }->{ 'users' } } ) {
		$public = 1;
	    } else {
		$public = 0;
	    }
	} catch {
	    chomp $_;
#	    warn "**Warning: Cannot obtain effective permissions for repository $repo_obj->{ 'key' }: $_.\n";
	    $public = undef;
	};
    }
    return $public;
}

# transform largely varying byte sizes into a length constrained
# format that scales to K, M, or G respectively
# Input is a number from 1 ( "     1") to 999999999999 ("999,9 G")
sub short_size {
    my $num = shift;

    my $dim_pole = 'KKMMMGGG';
    if ( $num < 100000 ) {
	return sprintf("%6d", $num);
    }

    # the abbreviated format starts at 100000 bytes = 99,8 K
    
    # first compute no of kB - at least ~97,x
    my $kb = $num / 1024;

    # compute the integral no of kB
    my $whole = int( $kb );

    # compute power of ten of the kB number to build index in our
    # dimension key string.
    #
    my $d = int( log( $kb ) / log( 10 ) );

    # find the applicable scale key, K (KBytes), M (MByte), G ..
    my $dim = substr( $dim_pole, $d-1, 1 );

    my %multiplier = (
	'K' => 10 ** 0,
	'M' => 10 ** 3,
	'G' => 10 ** 6
	);
    # adjust whole number part to scale
    $whole = substr( $whole, 0, ($d % 3)+1 );
    my $whole_kbs = $whole * $multiplier{ $dim };
    my $rest_kb = $kb - $whole_kbs;
    my $rest = substr( $rest_kb, 0, 1);

    return sprintf( "%3d,$rest%s", $whole, $dim );
} 
	
sub print_folder_tree {
    my ( $this, $root, $node ) = @_;

    print "$root" . $node->{ 'uri' } . ":\n";

    my $json = JSON->new->allow_nonref;

    my $artifactory = $this->preference( 'atf_connector' );

    my @results = @{ $artifactory->rest_get_single( '/storage/' . "$root/" . $node->{ 'uri' } )->{ 'children' } };

    # first, print the immediate children
    foreach my $entry ( @results ) {
	my $name = $entry->{ 'uri' };
	$name =~ s/^\// /;
	if ( $get_file_details ) {
	    if ( not $entry->{ 'folder' } ) {
		my $details = $artifactory->rest_get_single( '/storage/' . $root . 
							     $node->{ 'uri' } . 
							     '/' . $name );
		$details->{ 'created' } =~ s/\..*//;
		foreach my $key ( keys %{ $details } ) {
		    $entry->{ $key } = $details->{ $key }
		    if ( not exists  $entry->{ $key } );
		}
	    }
	}
    }
    if ( $time_ordered ) {
	@results = sort { $a->{ 'created' } cmp $b->{ 'created' } } @results;
    }
    if ( $size_ordered ) {
	@results = sort { $a->{ 'size' } <=> $b->{ 'size' } } @results;
    }
    if ( $reverse_order ) {
	@results = reverse @results;
    }
    foreach my $entry ( @results ) {
	my $name = $entry->{ 'uri' };
	$name =~ s/^\// /;
	print $name;
	if ( $entry->{ 'folder' } ) {
	    print "/\n";
	} else {
	    if ( $get_file_details ) {
		print "  $entry->{ 'created' } by $entry->{ 'createdBy' } (" .
		    short_size($entry->{ 'size' }) . ')'; 
	    }
	    print "\n";
	}
    }
    foreach my $entry ( @results ) {
	next
	    if ( not $entry->{ 'folder' } );
	print "\n";
	$this->print_folder_tree( "$root" . $node->{ 'uri' } , $entry );
    }
    return;
}

sub cmd_descrep {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Repositories_IF::atfcli_descrep_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descrep ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing repository argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  # distinguish cases for access to repo content and the repo itself
  my $acc_repo_contents;
  my $reponame = ( $subject =~ m/\// ) ? (split( '/',  $subject ))[0] : $subject;
  my $repo;
  try {
      $repo = $artifactory->rest_get_single( '/repositories/' . $reponame );
  } catch {
      die "**Error: Invalid repository given. $reponame is unknown.\n";
  };
  if ( $repo->{ 'rclass' } eq 'local' ) {
      #/api/storage/libs-release-local/org/acme?permissions
      my $effective_perm;
      try {
	  $effective_perm = $artifactory->rest_get_single( '/storage/' . $reponame . 
							   '?permissions' );
      } catch {
	  chomp $_;
	  die "**Error: Cannot obtain effective permissions for repository $reponame: $_.\n";
      };
      $repo->{ 'effective_permissions' } = $effective_perm;
  }

  $acc_repo_contents = $reponame ne $subject;

  my @results;								 
  if ( $acc_repo_contents ) {
      try {
	  push( @results, $artifactory->rest_get_single( '/storage/' . $subject ) );
      } catch {
	  die "Cannot access item in repository: $subject: $_\n";
      };
  } else {
      push( @results, $artifactory->rest_get_single( '/repositories/' . $subject ) );
  }
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my %pmap = (
	  'm' => 'admin', 
	  'd' => 'delete', 
	  'w' => 'deploy',
	  'n' => 'annotate',
	  'r' => 'read'
	  );
      foreach my $result_obj ( @results ) {
	  foreach my $k ( keys %{ $result_obj } ) {
	      delete $result_obj->{ $k }
	      if ( not $result_obj->{ $k } or ( $result_obj->{ $k } eq 'false' ) );
	  }
	  print $json->pretty->encode( $result_obj ) . "\n";
	  if ( $artifactory->is_admin() ) {
	      my @aperm = $this->get_repository_permissions( $result_obj->{ 'key' } );
	      if ( @aperm ) {
		  print "Applied permissions:\n" . '=' x length( 'Applied permissions:' ) . "\n  " .
		      join( "\n  ", @aperm ) . "\n";
	      } else {
		  print "Applied permissions: none\n" . '=' x length( 'Applied permissions:' ) . "\n";
	      }
	  }
	  if ( $result_obj->{ 'rclass' } eq 'local' ) {
	      print "\n";
	      print "Effective permissions:\n" . '=' x length( 'Effective permissions:' ) . "\n";
	      my $eff_perm;
	      try {
		  $eff_perm = $artifactory->rest_get_single( '/storage/' .  $result_obj->{ 'key' } . '?permissions' );
	      } catch {
		  chomp $_;
		  warn "* Could not get effective permissions for repository $result_obj->{ 'key' }: $_.\n";
	      };
	      $eff_perm or next;
	      my $users = $eff_perm->{ 'principals' }->{ 'users' };
	      my $groups = $eff_perm->{ 'principals' }->{ 'groups' };
	      print "  Users:" . "\n  " . '-' x length( 'Users:' ) . "\n    " . 
		  join( "\n    ", map { "$_ : [" . 
					    join( ', ', map { $pmap{ $_ } } @{ $users->{ $_ } } ) . ']' }
			sort keys %{ $users } ) . "\n";
	      print "  Groups:" . "\n  " . '-' x length( 'Groups:' ) . "\n    " . 
		  join( "\n    ", map { "$_ : [" . 
					    join( ', ', map { $pmap{ $_ } } @{ $groups->{ $_ } } ) . ']' }
			sort keys %{ $groups } ) . "\n";
	  }
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub get_repository_permissions {
    my ( $this, $repo ) = @_;

    my $artifactory = $this->preference( 'atf_connector' );
    my @permissions = map { $_->{ 'name' } } @{ $artifactory->rest_get_list( '/security/permissions' ) };
    my @repo_perms;
    foreach my $this_perm ( @permissions ) {
	my $perm = $artifactory->rest_get_single( '/security/permissions/' . $this_perm );
	push( @repo_perms, $this_perm )
	    if ( grep { $_ eq $repo } @{ $perm->{ 'repositories' } } );
    }
    return wantarray ? @repo_perms : \@repo_perms;
}

sub cmd_mkrep {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Repositories_IF::atfcli_mkrep_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkrep ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_title, $opt_desc, $opt_type, $opt_repo_class, $opt_prototype,  );
  GetOptions (
      'help' => \$opt_help,
      'title=s' => \$opt_title,
      'desc|d=s' => \$opt_desc,
      'type=s' => \$opt_type,
      'class=s' => \$opt_repo_class,
      'prototype|proto=s' => \$opt_prototype,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $repo_types = {
      'generic' => 'generic-default',
      'bower' => 'bower-default',
      'cocoapods' => 'cocoapods-default',
      'debian' => 'debian-default',
      'docker' => 'docker-default',
      'gems' => 'gems-default',
      'gitlfs' => 'gitlfs-default',
      'gradle' => 'gradle-default',
      'ivy' => 'ivy-default',
      'maven' => 'maven-default',
      'npm' => 'npm-default',
      'nuget' => 'nuget-default',
      'opkg' => 'opkg-default',
      'pypi' => 'pypi-default',
      'sbt' => 'sbt-default',
      'vagrant' => 'vagrant-default',
      'yum' => 'yum-default',
  };

  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing name (key) for new repository.\n";
  }
  
  my $params = {};
  if ( $opt_prototype ) {
      my $proto_repo;
      try { 
	  $proto_repo = $artifactory->rest_get_single( '/repositories/' . $opt_prototype );
      } catch {
	  die "Error: Invalid prototype repository specified: $_\n";
      };
      $params = $proto_repo;
      foreach my $k ( qw( key description ) ) {
	  delete $params->{ $k };
      }
  }
  $params->{ 'key' } = $subject;
  $params->{ 'rclass' } = 'local';
  if ( $opt_type ) {
      return "Error: Invalid repository type \"$opt_type\" requested.\n"
	  unless ( exists $repo_types->{ lc $opt_type } );
      $params->{ 'repoLayoutRef' } = $repo_types->{ $opt_type };
      $params->{ 'packageType' } =  $opt_type;
  }
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
      $params->{ 'description' } = $opt_desc;
  }

  my $endpoint = '/repositories/';

  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_put( $endpoint . $subject, $params );
  } catch {
      die "create repository failed: $_.\n";
  };
  my $result = $result_obj->{ 'body' };
  push( @results, $result );
  print join( "\n", @results ) . "\n";

  return $stat;
}


sub cmd_rmrep {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Repositories_IF::atfcli_rmrep_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmrep ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_remove_with_content,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      'with-content' => \$opt_remove_with_content,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  foreach my $subject ( @ARGV ) {
      if ( not $subject ) {
	  return "Error: Missing repository argument.\n";
      }
      
      # distinguish delete cases for repo content and the repo itself
      my $delete_repo_contents;
      my $reponame = ( $subject =~ m/\// ) ? (split( '/',  $subject ))[0] : $subject;
      my $repo;
      try {
	  $repo = $artifactory->rest_get_single( '/repositories/' . $reponame );
      } catch {
	  die "**Error: Invalid repository given. $reponame is unknown.\n";
      };
      $delete_repo_contents = $reponame ne $subject;

      my @results;
      if ( $delete_repo_contents ) {
	  try {
	      push( @results, $artifactory->rest_get_single( '/storage/' . $subject ) );
	  } catch {
	      die "Cannot delete item in repository: $subject: $_\n";
	  };
      } else {
	  push( @results, $artifactory->rest_get_single( '/repositories/' . $subject ) );
      }

      if ( $delete_repo_contents ) {
	  foreach my $artifact ( @results ) {
	      if ( exists $artifact->{ 'children' } ) {
		  if ( not ( $opt_force or $this->confirm( "Remove folder $subject and all its content?", 'no' ))) {
		      $this->print( ucfirst "folder $subject not deleted.\n" );
		      return $stat;
		  }
	      }
	      try {
		  $artifactory->rest_delete( $artifact->{ 'downloadUri' } );
	      } catch {
		  die "** Error: Could not delete $subject: $_\n";
	      }
	  }
	  next;
      }
	  
      # from here the case where the repo itself is deleted
      foreach my $repo ( @results ) {
	  if ( not $this->repository_is_empty( $repo ) ) {
	      die ucfirst "repository $subject is not empty. Either use option --with-content or delete content manually.\n"
		  if ( not $opt_remove_with_content );
	  }
      }
      
      if ( not ( $opt_force or $this->confirm( "Really remove repository $subject ?", 'no' ))) {
	  $this->print( ucfirst "repository $subject not deleted.\n" );
	  return $stat;
      }

      my $endpoint = '/repositories/';
      
      my $result_obj;
      try {
	  $result_obj = $artifactory->rest_delete( $endpoint . $subject );
      } catch {
	  die "No such repository: '$subject'\n";
      };
      
      print ucfirst "remove" . "d repository " . join( "\n    ", map { $artifactory->substitute_format( '%F:key', $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub repository_is_empty {
    my ( $this, $repo ) = @_;

    my $artifactory = $this->preference( 'atf_connector' );
    my $repo_name = ( ( ref $repo eq 'HASH' ) and exists $repo->{ 'key' } ) ?
	$repo->{ 'key' } : $repo;
    my @results = @{ $artifactory->rest_get_single( 'storage/' . $repo_name )->{ 'children' } };

    return ( scalar @results ? 0 : 1 );
}

sub cmd_editrep {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Repositories_IF::atfcli_editrep_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editrep ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_desc, $opt_visibility, $opt_branch, $opt_enable_features, $opt_dis_features,  );
  GetOptions (
      'help' => \$opt_help,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'branch|b=s' => \$opt_branch,
      'enable=s' => \$opt_enable_features,
      'disable=s' => \$opt_dis_features,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing repository argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'repository', $subject );
  } catch {
      die "Cannot determine id for repository object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/repositories/:repository-id';

  my $params = { 'help' => $opt_help,
                'desc' => $opt_desc,
                'visibility' => $opt_visibility,
                'branch' => $opt_branch,
                'enable_features' => $opt_enable_features,
                'dis_features' => $opt_dis_features,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "update repository failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "update" . "d repository " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editrep in ArtifactoryCLI::Repositories' . "\n";

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $artifactory = $this->preference( 'atf_connector' );

    my $project_id;
    try {
	$project_id = $artifactory->get_project_id( $pid );
    } catch {
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

1;
