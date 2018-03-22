package JiraCLI::Filters;

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

use  JiraCLI::Filters_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsflt', 'cmd_lsflt' ],
     ['descflt', 'cmd_descflt' ],
     ['addflt', 'cmd_addflt' ],
     ['deleteflt', 'cmd_deleteflt' ],
     ['editflt', 'cmd_editflt' ], 
		 ]);
  
  return $this;
}


sub cmd_lsflt {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Filters_IF::gcli_lsflt_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsflt ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      'favorite|fave' => \$opt_fave,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  my @favourites = @{ $jira->rest_get_list( '/filter/favourite' ) };
  my $endpoint = '/pickers/filters';
  my @results;
  try {
      @results = @{ $jira->load_base_url( '/gadget/1.0' )->rest_get_single( $endpoint )->{ 'filters' } };
  } catch {
      die "Failed to retrieve list of filters: $_\n";
  };
  my %filtermap;
  foreach my $f ( @favourites ) {
      $filtermap{ $f->{ 'id' } } = $f;
  }
  foreach my $f ( @results ) {
      next
	  if ( exists  $filtermap{ $f->{ 'id' } } );
      $filtermap{ $f->{ 'id' } } = $f;
  }
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'id' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      foreach my $f ( sort { $a->{ 'name' } cmp $b->{ 'name' } } values %filtermap ) {
	  my $out = '';
	  if ( exists $f->{ 'favourite' } and $f->{ 'favourite' } ) {
	      $out = '* ';
	  } else {
	      $out = '  ';
	  }
	  print $out . $jira->substitute_format( "%n\t(%i)", $f ) . "\n";
      }
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descflt {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Filters_IF::gcli_descflt_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descflt ';
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing filter argument.\n";
  }
  if ( not $subject =~ m/^\d+$/ ) {
      return "Error: Invalid filter \"$subject\" - please use all numeric filter id.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/filter/';
  my @results;								 

  my $result_obj = $jira->rest_get_single( $endpoint . $subject );
  try {
      $result_obj->{ 'columns' } = $jira->rest_get_single( '/filter/' . $subject . '/columns' );
  };
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $jira->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = "%n (%i)\nowner: %F:owner.name\njql: %F:jql";
      print join( "\n", map { $jira->substitute_format( $norm_format, $_ ) } @results ) . "\n";
      if ( exists $result_obj->{ 'columns' } ) {
	  print $jira->substitute_format( "  cols: %F:columns" ) . "\n";
      }
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addflt {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Filters_IF::gcli_addflt_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addflt ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_prototype, $opt_jql, $opt_desc, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'proto=s' => \$opt_prototype,
      'jql=s' => \$opt_jql,
      'desc|d=s' => \$opt_desc,
      'favorite|fave' => \$opt_fave,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = join( ' ', @ARGV );
  if ( $opt_name ) {
      $subject = $opt_name;
      $subject =~ s/^"//;
      $subject =~ s/"$//;
  }
  if ( not $subject ) {
      return "Error: Missing filter name argument.\n";
  }
  if ( $opt_prototype and $opt_jql ) {
      return "Error: Cannot use option --proto and --jql together.\n";
  }
  if ( not ( $opt_jql or $opt_prototype ) ) {
      return "Error: Missing filter query definition (either --proto or --jql ...).\n";
  }
  if ( $opt_jql ) {
      $opt_jql = $this->get_description( $opt_jql );
  }
  if ( $opt_prototype and  ( $opt_prototype =~ m/^\d+$/ )) {
      my $proto_flt;
      try { 
	  $proto_flt = $jira->rest_get_single( '/filter/' . $opt_prototype );
	  $opt_jql = $proto_flt->{ 'jql' };
      } catch {
	  die "Error: Invalid prototype filter specified: $_\n";
      };
  }
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  
  my $endpoint = '/filter';
  
  my $params = { 
      'name' => $subject,
      'jql' => $opt_jql,
  };
  if ( $opt_desc ) {
      $params->{ 'description' } = $opt_desc;
  }
  if ( $opt_fave ) {
      $params->{ 'favourite' } = 1;
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_post( $endpoint, $params );
  } catch {
      die "add filter failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d filter " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_deleteflt {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Filters_IF::gcli_deleteflt_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deleteflt ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_force, $opt_help,  );
  GetOptions (
      'force|f' => \$opt_force,
      'help' => \$opt_help,
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
      return "Error: Missing filter id argument.\n";
  }
  if ( not $subject =~ m/^\d+$/ ) {
      return "Error: Invalid filter \"$subject\" - please use all numeric filter id.\n";
  }
  my $del_flt;
  try { 
      $del_flt = $jira->rest_get_single( '/filter/' . $subject );
  } catch {
      die "Error: Cannot delete filter $subject: $_\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really delete filter $subject (\"$del_flt->{ 'name' }\")?", 'no' ))) {
      $this->print( ucfirst "filter $subject not deleted.\n" );
      return $stat;
  }

  my $endpoint = '/filter';
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_delete( $endpoint . '/' . $subject );
  } catch {
      die "No such filter: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "delete" . "d filter $subject (\"$del_flt->{ 'name' }\")\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_editflt {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Filters_IF::gcli_editflt_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editflt ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_name, $opt_desc, $opt_jql, $opt_fave,  );
  GetOptions (
      'help' => \$opt_help,
      'name|n=s' => \$opt_name,
      'desc|d=s' => \$opt_desc,
      'jql=s' => \$opt_jql,
      'favorite|fave' => \$opt_fave,
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
      return "Error: Missing filter argument.\n";
  }
  if ( not $subject =~ m/^\d+$/ ) {
      return "Error: Invalid filter \"$subject\" - please use all numeric filter id.\n";
  }

  if ( $opt_name ) {
      $opt_name =~ s/^"//;
      $opt_name =~ s/"$//;
  }

  if ( $opt_jql ) {
      $opt_jql = $this->get_description( $opt_jql );
  }
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  
  my $endpoint = '/filter';
  
  my $params = {};
  if ( $opt_name ) {
      $params->{ 'name' } = $opt_name;
  }
  if ( $opt_jql ) {
      $params->{ 'jql' } = $opt_jql;
  }
  if ( $opt_desc ) {
      $params->{ 'description' } = $opt_desc;
  }
  if ( $opt_fave ) {
      $params->{ 'favourite' } = 1;
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $jira->rest_put( $endpoint . "/$subject", $params );
  } catch {
      die "edit filter failed: $_";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "updated" . "d filter " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

1;
