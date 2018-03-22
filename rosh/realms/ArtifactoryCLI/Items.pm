package ArtifactoryCLI::Items;

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
use File::Basename;

use  ArtifactoryCLI::Items_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsitm', 'cmd_lsitm' ],
     ['descitm', 'cmd_descitm' ],
     ['mkitm', 'cmd_mkitm' ],
     ['mkdiritm', 'cmd_mkdiritm' ],
     ['cpitm', 'cmd_cpitm' ],
     ['mvitm', 'cmd_mvitm' ],
     ['rmitm', 'cmd_rmitm' ], 
		 ]);
  
  return $this;
}

# we need these globals to convey control information to
# subroutines that are called recursively.
#
my $get_file_details;
my $time_ordered;
my $size_ordered;
my $reverse_order;

sub cmd_lsitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_lsitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsitm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_recursive, 
       $opt_format );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'recursive|rec|R' => \$opt_recursive,
      't' => \$time_ordered,
      's' => \$size_ordered,
      'r' => \$reverse_order,
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
      return "Error: Missing repository, folder or item argument.\n";
  }
   
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long or $opt_format ) {
      $opt_short = '';
      $get_file_details = 1;
  }

  my $endpoint = '/repositories';

  my @results;								 
  my @list_repo_contents;

  @results = @{ $artifactory->rest_get_list( $endpoint ) };

  my $repo_key = $subject;
  @results = @{ $artifactory->rest_get_single( '/storage/' . $repo_key )->{ 'children' } };
  my $num_results;
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
      $num_results = scalar @results;
      print "* $num_results items.\n";
      if ( $opt_recursive ) {
	  foreach my $entry ( @results ) {
	      next
		  if ( not $entry->{ 'folder' } );
	      print "\n";
	      $num_results += $this->print_folder_tree( $repo_key, $entry );
	  }
      }
  }
  if ( $num_results > scalar @results ) {
      print "\nTotal: $num_results items.\n";
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'key' } =~ m/${filter_re}/ } @results;
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
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
    my $num_results = scalar @results;
    print "* " . scalar @results . " items.\n";
    foreach my $entry ( @results ) {
	next
	    if ( not $entry->{ 'folder' } );
	print "\n";
	$num_results += $this->print_folder_tree( "$root" . $node->{ 'uri' } , $entry );
    }
    return $num_results;
}

sub cmd_descitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_descitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descitm ';
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
      return "Error: Missing item argument.\n";
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

  $acc_repo_contents = $reponame ne $subject;

  my @results;								 
  if ( $acc_repo_contents ) {
      try {
	  push( @results, $artifactory->rest_get_single( '/storage/' . $subject ) );
      } catch {
	  die "Cannot access item in repository: $subject: $_\n";
      };
  } else {
      die "Error: $subject is no suitable item argument (it is a repository).\n";
  }
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      foreach my $result_obj ( @results ) {
	  foreach my $k ( keys %{ $result_obj } ) {
	      delete $result_obj->{ $k }
	      if ( not $result_obj->{ $k } or ( $result_obj->{ $k } eq 'false' ) );
	  }
	  print $json->pretty->encode( $result_obj ) . "\n";
      }
  }
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mkitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_mkitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkitm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_file, $opt_to_target, $opt_force,  );
  GetOptions (
      'help' => \$opt_help,
      'file|f' => \$opt_file,
      'to=s' => \$opt_to_target,
      'force|f' => \$opt_force,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );
  
  # initial option checking here
  if ( not $opt_to_target ) { 
      $opt_to_target = pop @ARGV;
      if ( not $opt_to_target ) {
	  return "Error: Missing destination folder for upload.\n";
      }
  }
  my @files_to_upload;
  if ( $opt_file ) {
      if ( @ARGV ) {
	  return "Error: Excess argument(s) " . join( ", ", @ARGV ) . "\n";
      } else {
	  push( @files_to_upload, $opt_file );
      }
  } else {
      @files_to_upload = @ARGV;
  }
  if ( not @files_to_upload ) {
      die "Error: No file(s) to upload specified.\n";
  }
  if ( not $opt_to_target ) {
      die "Error: No destination repository and folder specified to which to upload.\n";
  }

  # verify target folder
  my $folder;
  if ( $folder = $this->itm_exists( $opt_to_target ) ) {
      if ( not $this->itm_is_directory( $folder ) ) {
	  die "Error: Item at path $opt_to_target exists but is no folder.\n";
      }
  } else {
      try {
	  $artifactory->load_base_url( '/' );
	  $folder = $artifactory->rest_put( $opt_to_target . '/', {} );
	  print "Created target folder $opt_to_target.\n";
      } catch { 
	  die "Error: $opt_to_target is an invalid folder/location that cannot be used for uploads: $_\n";
      };
  }


  my @results;								 

  foreach my $this_file ( @files_to_upload ) {
      if ( not -e $this_file ) {
	  print "Error: Upload file $this_file does not exist.\n";
	  next;
      }
      my $result_obj;
      my ( $contents, $cont_fh );
      open( $cont_fh, '<', $this_file ) or die "Cannot open file $this_file to upload: $!\n";
      $contents = join( '', <$cont_fh> );
      close $cont_fh;
      try {
	  $artifactory->load_base_url( '/' );
	  $result_obj = $artifactory->rest_put( $opt_to_target . '/' . basename( $this_file ), $contents );
      } catch {
	  die "Upload file $this_file failed: $_.\n";
      };
      
      my $result = from_json( $result_obj->{ 'body' } );
      push( @results, $result );
  }
  print ucfirst "uploade" . "d item(s) " . join( "\n    ", map{ basename( $_->{ 'path' }) } @results ) . 
      ( @results > 1 ? "\n" : ' ' ) . "to $opt_to_target\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub assert_target_folder {
    my ( $this, $path, $create ) = @_;

    my $json = JSON->new->allow_nonref;
    
    my $artifactory = $this->preference( 'atf_connector' );
    my $repo_key = ( split( '/', $path ) )[0];
    my $item;
    try {
	$item = $artifactory->rest_get_single( '/storage/' . $repo_key );
    } catch {
	die "Non exisiting repository specified - $!: " . $repo_key . "\n";
    };
    try {
	$item = $artifactory->rest_get_single( '/storage/' . $path );
    } catch {
	die "Non exisiting target folder specified - $!: " . $path . "\n"
	    unless ( $create );
    };
    if ( ref $item ) {
	if ( exists $item->{ 'children' } ) {
	    return $item;
	}
	die "Invalid target location $path - not a folder.\n";
    } 

    # $path does not exist - attempt to create it
    return $artifactory->rest_put( $path, {} );
}

sub cmd_mkdiritm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_mkdiritm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkdiritm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_force,  );
  GetOptions (
      'help' => \$opt_help,
      'force|f' => \$opt_force,
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
      return "Error: Missing item argument.\n";
  }

  my $item;
  if ( $item = $this->itm_exists( $subject ) ) {
      if ( $this->itm_is_directory( $item ) ) {
	  print "Folder $subject already exists.\n";
	  return $stat;
      } else {
	  die "Error: Item at path $subject exists but is no folder.\n";
      }
  }
  my $folder;
  try {
      $artifactory->load_base_url( '/' );
      $folder = $artifactory->rest_put( $subject . '/', {} );
      print "Created new folder $subject.\n";
  } catch { 
      die "Error: $subject is an invalid folder/location that cannot be created: $_\n";
  };

  return $stat;
}

sub itm_exists {
    my ( $this, $item ) = @_;

    return $item
	if ( ref $item );
    
    my $artifactory = $this->preference( 'atf_connector' );
    try {
	$item = $artifactory->rest_get_single( '/storage/' . $item );
    };
    return $item
	if ( ref $item );
    
    return 0;
}

sub itm_is_directory {
    my ( $this, $item ) = @_;

    $item = $this->itm_exists( $item );

    return ( $item && exists $item->{ 'children' } );
}

sub cmd_cpitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_cpitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_cpitm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help,  );
  GetOptions (
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $target = pop @ARGV;
  if ( not ( @ARGV and $target )) {
      return "Error: Missing argument - copy needs at least a source and a destination.\n";
  }

  my $target_is_path = (scalar split( '/', $target )) > 1; 

  my $endpoint = '/copy/';

  my @results;								 

  if ( not $target_is_path and @ARGV == 1 ) {
      # special case for convenience, allow this:
      # mv long/and/deep/path/to/file renamed_file =>
      $target = dirname( $ARGV[ 0 ] ) . '/' . $target;
  }

  foreach my $subject ( @ARGV ) {
      my $result_obj;
      try {
	  $result_obj = $artifactory->rest_post( $endpoint . $subject . '?to=' . $target, {} );
      } catch {
	  die "copy item $subject failed: $_.\n";
      };
      my $result = $result_obj->{ 'body' };
      push( @results, map { ( $_->{ 'level' } eq 'INFO' ) ? $_->{ 'message' } : $_->{ 'level' } . ': ' . $_->{ 'message' } } 
	    @{ from_json( $result_obj->{ 'body' } )->{ 'messages' } } );
  }
  print ucfirst join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mvitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_mvitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mvitm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help,  );
  GetOptions (
      'help' => \$opt_help,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $target = pop @ARGV;
  if ( not ( @ARGV and $target )) {
      return "Error: Missing argument - copy needs at least a source and a destination.\n";
  }
  my $target_is_path = (scalar split( '/', $target )) > 1; 
      
  my $endpoint = '/move/';

  my @results;								 
  if ( not $target_is_path and @ARGV == 1 ) {
      # special case for convenience, allow this:
      # mv long/and/deep/path/to/file renamed_file =>
      $target = dirname( $ARGV[ 0 ] ) . '/' . $target;
  }
  my @source_names;
  foreach my $subject ( @ARGV ) {
      try {
	  if ( is_pattern( $subject ) ) {
	      push( @source_names, $this->expand_pattern( $subject ) );
	  } else {
	      push( @source_names, $subject );
	  }
      } catch {
	  chomp $_;
	  die "** Error: Could determine objects to be moved: $_\n";
      };
  }
  # die "** About to move the following items: \n  " . join( "\n  ", @source_names ) . "\n";
  foreach my $subject ( @source_names ) {
      my $result_obj;
	  
      try {
	  $result_obj = $artifactory->rest_post( $endpoint . $subject . '?to=' . $target, {} );
      } catch {
	  chomp $_;
	  die "copy item $subject failed:\n  " . 
	      join( "\n  ", map { $_->{ 'level' } . ': ' . $_->{ 'message' } } @{ $_ } ) . ".\n";
      };
      my $result = $result_obj->{ 'body' };
      push( @results, map { ( $_->{ 'level' } eq 'INFO' ) ? $_->{ 'message' } : $_->{ 'level' } . ': ' . $_->{ 'message' } } 
	    @{ from_json( $result_obj->{ 'body' } )->{ 'messages' } } );
  }
  print ucfirst join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub is_pattern {
    my $name = shift;

    return $name =~ m/[*{}\[\]+\$\\]/;
}

sub expand_pattern {
    my ( $this, $pattern ) = @_;

    my ( $basepath, $pat ) = ( dirname( $pattern ), basename( $pattern ) );
    die "Cannot expand pattern without basepath. \"$pattern\" has no folder in which to look.\n"
	if ( not $basepath or ( $basepath eq '.' ) );

    my $json = JSON->new->allow_nonref;

    my $artifactory = $this->preference( 'atf_connector' );
    my $endpoint = '/storage/' . $basepath . '?list&listFolders=1';

    my $folder_contents;
    try {
	$folder_contents = $artifactory->rest_get_single( $endpoint )->{ 'files' };
    } catch {
	chomp $_;
	die "** Error: Could not get content list of folder $basepath: $_.\n";
    };
    # print "*** expand: got " . scalar(  @{ $folder_contents } ) . " files in $basepath\n";
    # print "*** expand: now matching names against pattern $pat\n";
    my @results = grep { $_ =~ m/${ pat }/ } map { $basepath . $_->{ 'uri' } } @{ $folder_contents };

    return @results;
}

sub cmd_rmitm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Items_IF::atfcli_rmitm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmitm ';
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
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing item argument.\n";
  }
  my $item;
  try {
      $item = $artifactory->rest_get_single( '/storage/' . $subject );
  } catch {
      die "Error: Delete item failed: $_\n";
  };
  if ( not ( $opt_force or $this->confirm( "Really remove item $subject ?", 'no' ))) {
      $this->print( ucfirst "item $subject not deleted.\n" );
      return $stat;
  }
  my @results;								 
  my $delete_path =  $item->{ 'downloadUri' };  # file items
  if ( not $delete_path ) {
      # directory items
      $delete_path = $item->{ 'uri' }; 
      $delete_path =~ s/\/api\/storage\///;
  }
  my $result_obj;
  try {
      $result_obj = $artifactory->rest_delete( $delete_path );
  } catch {
      die "No such item: '$subject'\n";
  };
      
  push( @results, $subject );
  print ucfirst "remove" . "d item " . join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $artifactory = $this->preference( 'artifactory_connector' );

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
