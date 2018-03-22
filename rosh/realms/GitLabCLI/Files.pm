package GitLabCLI::Files;

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
use MIME::Base64 qw( decode_base64 );

use  GitLabCLI::Files_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsfil', 'cmd_lsfil' ],
     ['descfil', 'cmd_descfil' ],
     ['catfil', 'cmd_catfil' ], 
     ['difffil', 'cmd_difffil' ], 
		 ]);
  
  return $this;
}


sub cmd_lsfil {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Files_IF::gcli_lsfil_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsfil ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_format, $opt_in, $opt_recursive, $opt_ref  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      'recursive|r' => \$opt_recursive,
      'ref=s' => \$opt_ref,
      'branch|b=s' => \$opt_ref,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );
  my $arg;
  if ( @ARGV ) {
      $arg = shift @ARGV;
  }
  # initial option checking here
    
  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list file requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/repository/tree';
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @params;
  if ( $arg ) {
      push( @params, "path=$arg" );
  }
  if ( $opt_recursive ) {
      push( @params, "recursive=true" );
  }
  if ( $opt_ref ) {
      push( @params, "ref=$opt_ref" );
  }
  if ( @params ) {
      $endpoint .= '?' . join( '&', @params );
  }

  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 

  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $default_format = '%m %F:path';
      print join( "\n", map { $gitlab->substitute_format( $default_format, $_ ) } @results ) . "\n"; 
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descfil {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Files_IF::gcli_descfil_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descfil ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_short, $opt_format, $opt_in, $opt_ref  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'format|fmt=s' => \$opt_format,
      'in=s' => \$opt_in,
      'ref=s' => \$opt_ref,
      'branch|b=s' => \$opt_ref,
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
      return "Error: Missing file argument.\n";
  }
  $subject = url_encode( $subject );
  
  if ( $opt_long ) {
      $opt_short = '';
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe file requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/repository/files/:file_path';
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:file_path/\/$subject/;

  if ( $opt_ref ) {
      $endpoint .= "?ref=$opt_ref";
  } else {
      $endpoint .= "?ref=master";
  }
  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  $result_obj->{ 'content' } = '<use "cat file .." to get contents of file>';
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'file_name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { $_->{ 'file_name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
#      my $default_format = '%m %F:path';
#      print join( "\n", map { $gitlab->substitute_format( $default_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_catfil {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Files_IF::gcli_catfil_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_catfil ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_file, $opt_in, $opt_ref, $opt_branch,  );
  GetOptions (
      'help' => \$opt_help,
      'file|f=s' => \$opt_file,
      'in=s' => \$opt_in,
      'ref=s' => \$opt_ref,
      'branch|b=s' => \$opt_branch,
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
      return "Error: Missing file argument.\n";
  }
  $subject = url_encode( $subject );

  if ( $opt_ref and $opt_branch ) {
      die "** Error: Contradicting selection options --ref and --branch. Please use either of both.\n";
  }
  $opt_ref ||= $opt_branch;
  
  if ( $opt_file and -e $opt_file ) {
      die "Error: Output file $opt_file already exists - will not overwrite it.\n";
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe file requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/repository/files/:file_path';
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:file_path/\/$subject/;

  if ( $opt_ref ) {
      $endpoint .= "?ref=$opt_ref";
  } else {
      my @prot_branches = grep { $_->{ 'protected' } and not $_->{ 'merged' } } 
      @{ $gitlab->rest_get_list( '/projects/' . $project_id . '/repository/branches' ) };
      my $ref_br;
      if ( @prot_branches == 1 ) {
	  # sometimes there is no 'master' branch but some other protected main branch
	  $ref_br = $prot_branches[ 0 ]->{ 'name' };
      } else {
	  try {
	      my $master_br = $gitlab->rest_get_single( '/projects/' . $project_id . 
							'/repository/branches/master' );
	  } catch {
	      die "** No --branch or --ref specified, and no likely default found.
** Please specify version context for retrieving the file.\n";
	  };
	  $ref_br = 'master'
      }
      $endpoint .= "?ref=$ref_br";
  }
  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );

  if ( $opt_file ) {
      my $ofh;
      open( $ofh, '>', $opt_file )
	  or die "Could not create output file $opt_file: $!\n";      
      print $ofh decode_base64( $result_obj->{ 'content' } );
      close $ofh;
      print "Output written to $opt_file\n";
  } else  {
      print decode_base64( $result_obj->{ 'content' } ) . "\n";
  }
  
  return $stat;
}

sub cmd_difffil {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Files_IF::gcli_difffil_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_difffil ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_from_original, $opt_to_target, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'from=s' => \$opt_from_original,
      'to=s' => \$opt_to_target,
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
      return "Error: Missing file argument.\n";
  }
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
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "diff|compare|comp file requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = "/projects/:id/repository/compare?from=$opt_from_original&to=$opt_to_target";
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;

  my @results;								 

  my $result_obj = $gitlab->rest_get_single( $endpoint );
  my $diffs = $result_obj->{ 'diffs' };
  push( @results, grep { ( $_->{ 'old_path' } =~ m/${subject}/ ) or
			     ( $_->{ 'new_path' } =~ m/${subject}/ ) } @{ $result_obj->{ 'diffs' } } );
  if ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      if ( @results ) {
	  print "Changes in $subject between commits from $opt_from_original to $opt_to_target:\n";
	  print '=' x length( "Changes in $subject between commits from $opt_from_original to $opt_to_target:" ) . "\n";
	  print join( "\n", map { $_->{ 'diff' } } @results ) . "\n";
      } else {
	  print "No changes $subject between commits from $opt_from_original to $opt_to_target.\n";
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
