package CrowdCLI::Groups;

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

# FIXME: XML::Simple is deprecated
use XML::Simple qw(:strict);

use  CrowdCLI::Groups_IF;

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

  my $long_usage = CrowdCLI::Groups_IF::gcli_lsgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsgrp ';
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
    
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/1/group/membership';

  my ( $results, @results );
  # the 'memberships' request is going to throw XML data at us, no JSON
  try {
      $results = $crowd->load_base_url( '/' )->rest_get_raw( $endpoint );
      # returns a valid REST::Client object.
  } catch {
      die "** Error: Could not retrieve user information: $!.\n";
  };
  if ( not $results->responseHeader( 'content-type' ) eq 'application/xml' ) {
      die "** Error: Received unexpected kind of data: " . $results->responseHeader( 'content-type' ) . "\n";
  }
  my $result_objects = XMLin( $results->responseContent(),
			      'ForceArray' => [ qw( group ) ],
			      'KeyAttr' => [ qw( membership group ) ]
      );

  my @results = sort keys %{ $result_objects->{ 'membership' } };
  if ( $filter_re ) {
      @results = grep{ $_ =~ m/${filter_re}/ } @results;
  }
  print join( "\n", @results ) . "\n";
  
  # end this routine by returning a status indicator; not null means error!

  return $stat;
}

sub cmd_lsgrp_members {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Groups_IF::gcli_lsgrp_members_usage();
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  my $groupdesc = $crowd->load_base_url( '/' )->rest_get_single( '/1/group?groupname=' . $subject );
  my $endpoint = '/1/group/user/direct?groupname=';

  my @results;								 
  @results = map { $_->{ 'name' } } @{ $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $subject )->{ 'users' } }; 

  print "Group: $subject\n";
  if ( $groupdesc->{ 'description' } ) {
      print $groupdesc->{ 'description' } . "\n";
  }
  if ( @results ) {
      print 'The group has ' . scalar @results . " members:\n";
      print join( "\n", @results ) . "\n";
  } else {
      print "The group has no members.\n";
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

  my $long_usage = CrowdCLI::Groups_IF::gcli_addgrp_members_usage();
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  if ( not @ARGV ) {
      return "Error: Missing user name argument(s).\n";
  }
  my $endpoint = '/1/group/user/direct?groupname=';

  my @results;								 

  foreach my $this_user ( @ARGV ) {
      my $result_obj;
      try {
	  $result_obj = $crowd->load_base_url( '/' )
	      ->rest_post( $endpoint . $subject, { 'name' => $this_user } );
      } catch {
	  chomp $_;
	  die "add member to group failed: $_.\n";
      };
      push( @results, $this_user );
  }
  print ucfirst "added member to" . " group $subject " . join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_rmgrp_members {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Groups_IF::gcli_rmgrp_members_usage();
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  if ( not @ARGV ) {
      return "Error: Missing user name argument(s).\n";
  }

  my $endpoint = '/1/group/user/direct?groupname=';

  my @results;								 

  foreach my $this_user ( @ARGV ) {
      my $result_obj;
      try {
	  $result_obj = $crowd->load_base_url( '/' )
	      ->rest_delete( $endpoint . $subject . '&username=' . $this_user );
      } catch {
	  chomp $_;
	  die "Removal of user $this_user from group $subject failed: $_\n";
      };
      print "** Result for delete $result_obj: " . dump( $result_obj ) . "\n";
      push( @results, $this_user );
  }
  print ucfirst "Removed member from" . " group $subject " . 
      join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Groups_IF::gcli_addgrp_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_addgrp ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_desc,  );
  GetOptions (
      'help' => \$opt_help,
      'desc|d=s' => \$opt_desc,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  
  my $json = JSON->new->allow_nonref;

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }

  my $endpoint = '/1/group';

  my $params = {
      'name' => $subject,
      'type' => 'GROUP',
  };
  if ( $opt_desc ) {
      $params->{ 'description' } = $opt_desc;
  }
  my @results;								 

  my $result_obj;
  try {
      $result_obj = $crowd->load_base_url( '/' )->rest_post( $endpoint, $params );
  } catch {
      die "add group failed: $_.\n";
  };
  push( @results, $subject );
  print ucfirst "add" . "ed group " . join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_deletegrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Groups_IF::gcli_deletegrp_usage();
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  
  if ( not ( $opt_force or $this->confirm( "Really delete group $subject ?", 'no' ))) {
      $this->print( ucfirst "group $subject not d.\n" );
      return $stat;
  }

  my $endpoint = '/1/group?groupname=';


  my @results;								 

  my $result_obj;
  try {
      $result_obj = $crowd->load_base_url( '/' )->rest_delete( $endpoint . $subject );
  } catch {
      chomp $_;
      die "Delete groupü $subject failed: $_.\n";
  };
      
  push( @results, $subject );
  print ucfirst "delete" . "d group " . join( "\n    ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

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

  my $long_usage = CrowdCLI::Groups_IF::gcli_editgrp_usage();
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $crowd->assert_object_id( 'group', $subject );
  } catch {
      die "Cannot determine id for group object \"$subject\".\n";
  };
  
  if ( $opt_desc ) {
      $opt_desc = $this->get_description( $opt_desc );
  }
  $opt_in ||= $this->preference( 'current_project' );
  if ( not $opt_in ) {
      die "edit group requires a defined project context. Use option --in <project>.\n

$usage\n";
  } 
  # verify project id
  my $project_id = $this->assert_project_id( $opt_in );


  # TODO / FIXME - verify / fill in the correct endpoint format after substitutions
  my $endpoint = '/usermanagement/1/group';
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
      $result_obj = $crowd->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "edit group failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "edit" . "d group " . join( "\n    ", map { $crowd->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editgrp in CrowdCLI::Groups' . "\n";

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $crowd = $this->preference( 'crowd_connector' );

    my $project_id;
    try {
	$project_id = $crowd->get_project_id( $pid );
    } catch {
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

1;
