package ArtifactoryCLI::Permissions;

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

use  ArtifactoryCLI::Permissions_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsperm', 'cmd_lsperm' ],
     ['descperm', 'cmd_descperm' ],
     ['mkperm', 'cmd_mkperm' ],
     ['rmperm', 'cmd_rmperm' ],
     ['editperm', 'cmd_editperm' ], 
     ['applyperm', 'cmd_applyperm' ], 
		 ]);
  
  return $this;
}


sub cmd_lsperm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_lsperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsperm ';
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
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '^(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/security/permissions';

  my @results;								 
  @results = @{ $artifactory->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $_->{ 'name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { $_->{ 'name' } } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_descperm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_descperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descperm ';
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
      return "Error: Missing permission argument.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/security/permissions/';


  my @results;								 

  my $result_obj = $artifactory->rest_get_single( $endpoint . $subject );
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $artifactory->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      # TODO / FIXME - define custom normal format
      my $norm_format = "Permission target %n\nApplies to repositories:\n  %F:repositories\n"
	  . "Groups:\n  %F:principals.groups\n\nUsers:\n  %F:principals.users";
      print join( "\n", map { $artifactory->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mkperm {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_mkperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkperm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_title,  );
  GetOptions (
      'help' => \$opt_help,
      'title=s' => \$opt_title,
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
      return "Error: Missing permission argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'permission', $subject );
  } catch {
      die "Cannot determine id for permission object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/permissions/{permission}';

  my $params = { 'help' => $opt_help,
                'title' => $opt_title,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_post( $endpoint, $params );
  } catch {
      die "create permission failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "create" . "d permission " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command mkperm in ArtifactoryCLI::Permissions' . "\n";

  return $stat;
}

sub cmd_rmperm {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_rmperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmperm ';
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

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing permission argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'permission', $subject );
  } catch {
      die "Cannot determine id for permission object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really remove permission $subject ?", 'no' ))) {
      $this->print( ucfirst "permission $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/permissions/{permission}';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such permission: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove" . "d permission " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command rmperm in ArtifactoryCLI::Permissions' . "\n";

  return $stat;
}

sub cmd_editperm {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_editperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editperm ';
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
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing permission argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'permission', $subject );
  } catch {
      die "Cannot determine id for permission object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/permissions/{permission}';

  my $params = { 'help' => $opt_help,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "update permission failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "update" . "d permission " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editperm in ArtifactoryCLI::Permissions' . "\n";

  return $stat;
}

sub cmd_applyperm {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Permissions_IF::atfcli_applyperm_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_applyperm ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_to_target, $opt_from_original,  );
  GetOptions (
      'help' => \$opt_help,
      'to=s' => \$opt_to_target,
      'from=s' => \$opt_from_original,
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
      return "Error: Missing permission argument.\n";
  }
  if ( $opt_from_original and $opt_to_target ) {
      die "** Error: Contraditing options --from and --to detected. Use only either of the options.\n";
  }
  my $command_is = ( $this->set( 'verb' ) =~ m/^(un|rev).*/ ) ? 'unapply' : 'apply';
  my $reponame;
  if ( $command_is eq 'apply' ) {
      die "** Error: Missing --to <repository> argument.\n"
	  if ( not $opt_to_target );
      $reponame = $opt_to_target;
  } else { 
      die "** Error: Missing --from <repository> argument.\n"
	  if ( not $opt_from_original );
      $reponame = $opt_from_original;
  }

  my $repo;
  try {
      $repo = $artifactory->rest_get_single( '/repositories/' . $reponame );
  } catch {
      die "**Error: Invalid repository given. $reponame is unknown.\n";
  };

  my $endpoint = '/security/permissions/' . $subject;
  my $perms;
  try {
      $perms = $artifactory->rest_get_single( $endpoint );
  } catch {
      chomp $_;
      die "** Error: Cannot find permission object \"$subject\": $_.\n";
  };

  if ( $opt_to_target ) {
      if ( grep { $_ eq $opt_to_target } @{ $perms->{ 'repositories' } } ) {
	  return "Repository $opt_to_target already subject to permission \"$subject\".\n";
      }
      push( @{ $perms->{ 'repositories' } }, $opt_to_target );
  } else {
      if ( not grep { $_ eq $opt_from_original } @{ $perms->{ 'repositories' } } ) {
	  return "Repository $opt_from_original not subject to permission \"$subject\".\n";
      }
      @{ $perms->{ 'repositories' } } = grep { $_ ne $opt_from_original } @{ $perms->{ 'repositories' } };
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_put( $endpoint, $perms );
  } catch {
      chomp $_;
      die ucfirst "apply permission failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "applied permission \"$subject\" to repository $subject.\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

1;
