package GitLabCLI::Snippets;

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

use  GitLabCLI::Snippets_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['listsnp', 'cmd_listsnp' ],
     ['descsnp', 'cmd_descsnp' ],
     ['addsnp', 'cmd_addsnp' ],
     ['editsnp', 'cmd_editsnp' ],
     ['delsnp', 'cmd_delsnp' ],
     ['getsnp', 'cmd_getsnp' ], 
		 ]);
  
  return $this;
}


sub cmd_listsnp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Snippets_IF::gcli_listsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_listsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_format, $opt_short, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
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
      die "list snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'title' } =~ m/${filter_re}/ } @results;
  }
  if ( @results ) {
      if ( $opt_format ) {
	  print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
      } elsif ( $opt_long ) {
	  print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
      } else {
	  print join( "\n", map { $gitlab->substitute_format( "%F:title (%i)", $_ ) } @results ) . "\n"; 
      }
  } else {
      print "No snippets found.\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descsnp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Snippets_IF::gcli_descsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_format, $opt_short, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
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
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing snippet argument.\n";
  }
  my $subject_id;
  $subject_id = $subject;

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets/:snippet_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%F:title (%i)";
      print join( "\n", map { $gitlab->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addsnp {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Snippets_IF::gcli_addsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_title, $opt_file, $opt_desc, $opt_visibility, $opt_code,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'title=s' => \$opt_title,
      'file|f=s' => \$opt_file,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'code=s' => \$opt_code,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # initial option checking here
  
  if ( not $opt_title ) {
    die "Error: Missing snippet title. A title is required - use option --title.\n$usage\n";
  }
  if ( not $opt_file ) {
    die "Error: Missing filename/-type for snippet. Use option --file.\n$usage\n";
  }
  if ( not $opt_code ) {
    die "Error: Missing snippet content. Use option --code.\n$usage\n";
  } else {
      $opt_code = $this->get_content( $opt_code );
  }
  if ( not $opt_visibility ) {
    die "Error: Missing snippet visibility. Use option --visibility.\n$usage\n";
  } else {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid snippet visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "create snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  my $params = { 
      'title' => $opt_title,
      'file_name' => $opt_file,
      'visibility' => $opt_visibility,
      'code' => $opt_code,
      'id' => $project_id };

  if ( $opt_desc ) {
      $params->{ 'description' } = $opt_desc;
  }

  my @results;								 
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_post( $endpoint, $params );
  } catch {
      die "create snippet failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "create" . "d snippet " . join( "\n    ", map { $gitlab->substitute_format( '"%F:title" as %i', $_ ) } @results ) . "\n";
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_editsnp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Snippets_IF::gcli_editsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_title, $opt_file, $opt_desc, $opt_visibility, $opt_code,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'title=s' => \$opt_title,
      'file|f=s' => \$opt_file,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
      'code=s' => \$opt_code,
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
      return "Error: Missing snippet argument (id).\n";
  }
  my $subject_id;
  $subject_id = $subject;
  
  if ( $opt_visibility ) {
      $opt_visibility =~ m/^(private|internal|public)$/i
	  or die "Invalid project visibility $opt_visibility specified.
Please choose: 'private', 'internal', or 'public'.\n";
      $opt_visibility = lc $opt_visibility;
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "update snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets/:snippet_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  my $params = { 'id' => $project_id };
  if ( $opt_desc ) {
      $params->{ 'description' } = $this->get_description( $opt_desc );
  }
  if ( $opt_title ) {
      $params->{ 'title' } = $opt_title;
  }
  if ( $opt_file ) {
      $params->{ 'file_name' } = $opt_file;
  }
  if ( $opt_visibility ) {
      $params->{ 'visibility' } = $opt_visibility;
  }
  if ( $opt_code ) {
      $params->{ 'code' } = $this->get_content( $opt_code );
  }
  my @results;								 
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "delete snippet failed: $_.\n";      
  };
  push( @results, $result_obj );
  
  print ucfirst "update" . "d snippet " . join( "\n    ", map { $gitlab->substitute_format( '%i (%F:title)', $_ ) } @results ) . "\n";
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_delsnp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Snippets_IF::gcli_delsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_delsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_force, $opt_in,  );
  GetOptions (
      'help' => \$opt_help,
      'force|f' => \$opt_force,
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
      return "Error: Missing snippet argument.\n";
  }
  my $subject_id;
  $subject_id = $subject;
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets/:snippet_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;

  my @results;								 

  my $snip_obj;
  try {
      $snip_obj = $gitlab->rest_get_single( $endpoint );
  } catch {
      die "No snippet found under id $subject.\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really remove snippet $subject ($snip_obj->{ 'title'})?", 'no' ))) {
      $this->print( ucfirst "snippet $subject not d.\n" );
      return $stat;
  }

  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such snippet: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d snippet $subject ($snip_obj->{ 'title' })\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub xxx_cmd_delsnp {
  my $stat = "";

  my $this = shift;

  my $long_usage = GitLabCLI::Snippets_IF::gcli_delsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_delsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in,  );
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
      return "Error: Missing snippet argument.\n";
  }
  my $subject_id;
  $subject_id = $subject;

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/:id/snippets/:snippet_id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  
  my $snip_obj;
  try {
      $snip_obj = $gitlab->rest_get_single( $endpoint );
  } catch {
      die "No snippet found under id $subject.\n";
  };
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such object: '$subject'\n";
  };
      
  print ucfirst "remove" . "d snippet $subject ($snip_obj->{ 'title' })\n";
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print $json->pretty->encode( $result_obj ) . "\n";
  }

  return $stat;
}

sub cmd_getsnp {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = GitLabCLI::Snippets_IF::gcli_getsnp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_getsnp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_to_target,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'to=s' => \$opt_to_target,
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
      return "Error: Missing snippet argument.\n";
  }
  my $subject_id;
  $subject_id = $subject;
  


  
  
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "get snippet requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/projects/:id/snippets/:snippet_id/raw';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  
  my @results;								 
  
  my $result_obj = $gitlab->rest_get_single( $endpoint );
  push( @results, $result_obj );
  
  
  
  
  print ucfirst "get" . "d snippet " . join( "\n    ", map { $gitlab->substitute_format( '%n as %i', $_ ) } @results ) . "\n";
  
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command getsnp in GitLabCLI::Snippets' . "\n";

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
