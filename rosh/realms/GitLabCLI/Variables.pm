package GitLabCLI::Variables;

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

use  GitLabCLI::Variables_IF;

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
     ['lsvar', 'cmd_lsvar' ],
     ['descvar', 'cmd_descvar' ],
     ['addvar', 'cmd_addvar' ],
     ['rmvar', 'cmd_rmvar' ],
     ['editvar', 'cmd_editvar' ], 
		 ]);
  
  return $this;
}


sub cmd_lsvar {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Variables_IF::gcli_lsvar_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsvar ';
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
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "list var requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/variables';
  
  my @results;								 
  @results = @{ $gitlab->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'key' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $gitlab->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'key' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { "$_->{ key } = $_->{ value }" } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!
  
  return $stat;
}

sub cmd_descvar {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Variables_IF::gcli_descvar_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descvar ';
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
      print $usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing var argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  if ( $opt_long ) {
      $opt_short = '';
  }
  
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "describe var requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/variables/' . $subject;
  
  my @results;								 
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_get_single( $endpoint );
      push( @results, $result_obj );
  } catch {
      die "No such variable: '$subject'\n";
  };
  
  if ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $desc;
      my $norm_format = "%F:key = %F:value\n";
      foreach my $r ( @results ) {
	  $desc = $gitlab->substitute_format( $norm_format, $r );
	  $desc .= '  protected: ' . ( $r->{ 'protected' } ? 'yes' : 'no' ) . "\n";
	  $desc .= '  env_scope: ' . ( $r->{ 'environment_scope' } ? $r->{ 'environment_scope' } : '*' ) . "\n";
	  print $desc;
      }
  }
  
  return $stat;
}

sub cmd_addvar {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Variables_IF::gcli_addvar_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addvar ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_value, $opt_scope, $opt_protected,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'value|val=s' => \$opt_value,
      'environment|env|scope=s' => \$opt_scope,
      'protected|prot' => \$opt_protected,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing var argument.\n";
  }
  if ( not $opt_value ) {
      return "Error: No value specified for variable $subject. Please use option --value.";
  }
  $opt_value = $this->get_description( $opt_value );

  # end this routine by returning a status indicator; not null means error!

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "add var requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  $opt_protected = defined $opt_protected ? $opt_protected : 0;
  $opt_scope ||= '*';
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/variables';
  my $params = { 
      'id' => $project_id,
      'key' => $subject,
      'value' => $opt_value,
      'environment_scope' => $opt_scope,
      'protected' => $opt_protected,
  };
  my @results;								 
  
  my $result_obj = $gitlab->rest_post( $endpoint, $params );
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );

  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $desc;
      my $norm_format = "%F:key = %F:value\n";
      foreach my $r ( @results ) {
	  $desc = $gitlab->substitute_format( $norm_format, $r );
	  $desc .= '  protected: ' . ( $r->{ 'protected' } ? 'yes' : 'no' ) . "\n";
	  $desc .= '  env_scope: ' . ( $r->{ 'environment_scope' } ? $r->{ 'environment_scope' } : '*' ) . "\n";
	  print 'Added variable ' . $desc;
      }
  }
  
  return $stat;
}

sub cmd_rmvar {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Variables_IF::gcli_rmvar_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmvar ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help, $opt_in,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing var argument.\n";
  }
  # end this routine by returning a status indicator; not null means error!

  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "remove var requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  my $endpoint = '/projects/' . $project_id . '/variables/' . $subject;
  
  my @results;								 
  
  
  my $result_obj;
  try {
      $result_obj = $gitlab->rest_delete( $endpoint );
  } catch {
      die "No such variable: '$subject'\n";
  };
      
  print "Deleted variable $subject\n";

  return $stat;
}

sub cmd_editvar {
  my $stat = "";

  my $this = shift;

  my $usage = GitLabCLI::Variables_IF::gcli_editvar_usage();
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editvar ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_in, $opt_value, $opt_scope, $opt_protected,  );
  GetOptions (
      'help' => \$opt_help,
      'in=s' => \$opt_in,
      'value|val=s' => \$opt_value,
      'environment|env|scope=s' => \$opt_scope,
      'protected|prot' => \$opt_protected,
      );

  my $json = JSON->new->allow_nonref;

  my $gitlab = $this->preference( 'gitlab_connector' );

  # intial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing var argument.\n";
  }
  $opt_value = $this->get_description( $opt_value )
      if ( $opt_value );

  # end this routine by returning a status indicator; not null means error!
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit var requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  $opt_protected = defined $opt_protected ? $opt_protected : 0;
  $opt_scope ||= '*';
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );

  # re-use existing value if none is passed as argument.
  if ( not ( $opt_value && $opt_protected && $opt_scope ) ) {
      my $var;
      try {
	  $var = $gitlab->rest_get_single( '/projects/' . $project_id . '/variables/' . $subject );
      } catch {
	  die "No such variable: '$subject'\n";
      };
      if ( not $opt_value ) {
	  $opt_value = $var->{ 'value' };
      }
      if ( not $opt_protected and $var->{ 'protected' } ) {
	  if ( not $this->confirm( "Variable '$subject' is currently protected. Really unprotect?", 'no')) {
	      $opt_protected = 1;
	  }
      }
  }

  my $endpoint = '/projects/' . $project_id . '/variables/' . $subject;
  my $params = { 
      'id' => $project_id,
      'key' => $subject,
      'value' => $opt_value,
      'environment_scope' => $opt_scope,
      'protected' => $opt_protected,
  };
  my @results;								 

  my $result_obj = $gitlab->rest_put( $endpoint, $params );

  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );

  if ( $this->preference( 'verbose' ) ) {
      print $json->pretty->encode( from_json( $result_obj->{ 'body' } ) ) . "\n";
  } else {
      my $desc;
      my $norm_format = "%F:key = %F:value\n";
      foreach my $r ( @results ) {
	  $desc = $gitlab->substitute_format( $norm_format, $r );
	  $desc .= '  protected: ' . ( $r->{ 'protected' } ? 'yes' : 'no' ) . "\n";
	  $desc .= '  env_scope: ' . ( $r->{ 'environment_scope' } ? $r->{ 'environment_scope' } : '*' ) . "\n";
	  print 'Updated variable ' . $desc;
      }
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
