package ArtifactoryCLI::Groups;

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

use  ArtifactoryCLI::Groups_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsgrp', 'cmd_lsgrp' ],
     ['lsgrp_members', 'cmd_lsgrp_members' ],
     ['addgrp_members', 'cmd_addgrp_members' ],
     ['rmgrp_members', 'cmd_rmgrp_members' ],
     ['addgrp', 'cmd_addgrp' ],
     ['deletegrp', 'cmd_deletegrp' ],
     ['editgrp', 'cmd_editgrp' ], 
		 ]);
  
  return $this;
}


sub cmd_lsgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_lsgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsgrp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
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

  my $endpoint = '/security/groups';

  my @results;								 
  @results = @{ $artifactory->rest_get_list( $endpoint ) }; 
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }
  @results = sort { $a->{ 'name' } cmp $b->{ 'name' } } @results;

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:name';
      print join( "\n", map { $artifactory->substitute_format( $norm_format, $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_lsgrp_members {
  my $stat = "";

  my $this = shift;

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_lsgrp_members_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsgrp_members ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_short,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'short|s' => \$opt_short,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $artifactory = $this->preference( 'atf_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing group argument(s).\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/security/groups';

  my @results;								 
  foreach my $subject ( @ARGV ) {
      my $result_obj = $artifactory->rest_get_single( $endpoint . '/' . $subject );
      push( @results, $result_obj );
  }

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      my $norm_format = '%F:name';
      print join( "\n", map { $artifactory->substitute_format( $norm_format, $_ ) } @results ) . "\n";
  }

  # end this routine by returning a status indicator; not null means error!

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addgrp_members {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_addgrp_members_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addgrp_members ';
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
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/groups';

  my $params = { 'help' => $opt_help,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_post( $endpoint, $params );
  } catch {
      die "add member to group failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add member to" . "d group " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command addgrp_members in ArtifactoryCLI::Groups' . "\n";

  return $stat;
}

sub cmd_rmgrp_members {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_rmgrp_members_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmgrp_members ';
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
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/groups';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such group: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "remove member from" . "d group " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command rmgrp_members in ArtifactoryCLI::Groups' . "\n";

  return $stat;
}

sub cmd_addgrp {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_addgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addgrp ';
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
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/groups';

  my $params = { 'help' => $opt_help,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_post( $endpoint, $params );
  } catch {
      die "add group failed: $_.\n";
  };
  my $result = from_json( $result_obj->{ 'body' } );
  push( @results, $result );
  print ucfirst "add" . "d group " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command addgrp in ArtifactoryCLI::Groups' . "\n";

  return $stat;
}

sub cmd_deletegrp {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_deletegrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_deletegrp ';
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
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  
  if ( not ( $opt_force or $this->confirm( "Really delete group $subject ?", 'no' ))) {
      $this->print( ucfirst "group $subject not d.\n" );
      return $stat;
  }

  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/security/groups';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_delete( $endpoint );
  } catch {
      # TODO / FIXME - appropriate message here
      die "No such group: '$subject'\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "delete" . "d group " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command deletegrp in ArtifactoryCLI::Groups' . "\n";

  return $stat;
}

sub cmd_editgrp {
  my $stat = "";

  my $this = shift;

  # !! GENERATED CONTENT !!
  # This subroutine was generated as scaffolding for implementation
  # of REST API access from command line.
  # It is meant to be completed by hand.
  # Remove this comment if the subroutine is final.
  #

  my $long_usage = ArtifactoryCLI::Groups_IF::atfcli_editgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editgrp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_group, $opt_name, $opt_path, $opt_in, $opt_desc, $opt_visibility,  );
  GetOptions (
      'help' => \$opt_help,
      'group=s' => \$opt_group,
      'name|n=s' => \$opt_name,
      'path=s' => \$opt_path,
      'in=s' => \$opt_in,
      'desc|d=s' => \$opt_desc,
      'visibility=s' => \$opt_visibility,
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
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $artifactory->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  if ( $opt_group ) {
      
      if ( not $opt_in ) {
	  my $subject_id;
	  try {
	      $subject_id = $artifactory->get_object_id( 'group', $opt_group );
	  } catch {
	      die "Cannot determine id for group \"$opt_group\": $!\n";
	  };
	  $opt_in = $subject_id;
      }
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit group requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/groups/:group-id';
  $endpoint =~ s/\/projects\/:project-id/\/projects\/$project_id/;
  $endpoint =~ s/\/projects\/:id/\/projects\/$project_id/;
  $endpoint =~ s/\/:(\w+_)?id/\/$subject_id/;
  my $params = { 'help' => $opt_help,
                'group' => $opt_group,
                'name' => $opt_name,
                'path' => $opt_path,
                'in' => $opt_in,
                'desc' => $opt_desc,
                'visibility' => $opt_visibility,
               'id' => $subject_id };
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $artifactory->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "edit group failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "edit" . "d group " . join( "\n    ", map { $artifactory->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editgrp in ArtifactoryCLI::Groups' . "\n";

  return $stat;
}


1;
