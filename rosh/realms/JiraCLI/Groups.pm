package JiraCLI::Groups;

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

use  JiraCLI::Groups_IF;

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

  my $long_usage = JiraCLI::Groups_IF::gcli_lsgrp_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  
  
  my $filter_re;
  if ( @ARGV ) {
      $filter_re = '(' . join( '|', @ARGV ) . ')';
  }
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/groups/picker?maxResults=10000';
  my $result_obj = $jira->rest_get_single( $endpoint );
  my @results = @{ $result_obj->{ 'groups' } };
  if ( $filter_re ) {
      @results = grep{ $_->{ 'name' } =~ m/${filter_re}/ } @results;
  }

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'name' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print 'Got ' . scalar @results . ' matching groups:' . "\n";
      print '=' x length( 'Got ' . scalar @results . ' matching groups:' ) . "\n";
      print join( "\n", map { $_->{ 'name' } } @results ) . "\n";
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

  my $long_usage = JiraCLI::Groups_IF::gcli_lsgrp_members_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  
  if ( $opt_long ) {
      $opt_short = '';
  }

  my $endpoint = '/group/member?groupname=' . $subject . '&includeInactiveUsers=true&maxResults=10000';

  my $result_obj = $jira->rest_get_single( $endpoint );
  my @results = @{ $result_obj->{ 'values' } };
#  @results = @{ $jira->rest_get_list( $endpoint ) }; 

  if ( $opt_long ) { 
      print join( "\n", map { $_->{ 'key' } . ': ' . $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print 'Got ' . scalar @results . " Members in group $subject:\n";
      print '=' x length( 'Got ' . scalar @results . " Members in group $subject:" ) . "\n";
      print join( "\n", map { exists $_->{ 'name' } ? "$_->{ 'name' }\t ($_->{ 'key' })" : "($_->{ 'key' })" } @results ) . "\n";
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

  my $long_usage = JiraCLI::Groups_IF::gcli_addgrp_members_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }

  my @results;								 
  my @users = @ARGV;
  my $endpoint = '/group/user?groupname=' . $subject;
  foreach my $user ( @users ) {
      
      my $params = {
	  'name' => $user
      };

      my $result_obj;
      try {
	  $result_obj = $jira->rest_post( $endpoint, $params );
      } catch {
	  chomp $_;
	  die "add member to group failed: $_.\n";
      };
      my $result = from_json( $result_obj->{ 'body' } );
      push( @results, $user );
  }
  print ucfirst "added member to" . " group $subject:\n  " . join( "\n  ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_rmgrp_members {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Groups_IF::gcli_rmgrp_members_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  if ( not @ARGV ) {
      return "Error: No user name(s) given that were to be removed from group $subject.\n";
  }
  
  my $endpoint = '/group/user?groupname=' . $subject;
  my @results;								 
  foreach my $user ( @ARGV ) {
      my $result_obj;
      try {
	  $result_obj = $jira->rest_delete( $endpoint . '&username=' . $user );
      } catch {
	  die "No such group: '$subject'\n";
      };
      
      push( @results, $user );
  }
  print ucfirst "removed member(s) from" . " group $subject:\n  " . join( "\n  ", @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_addgrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Groups_IF::gcli_addgrp_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing group argument(s).\n";
  }

  my $endpoint = '/group';

  my @results;								 
  foreach my $subject ( @ARGV ) {
      my $params = { 
	  'name' => $subject,
      };
      
      my $result_obj;
      try {
	  $result_obj = $jira->rest_post( $endpoint, $params );
      } catch {
	  die "add group failed: $_.\n";
      };
      my $result = from_json( $result_obj->{ 'body' } );
      push( @results, $result );
  }
  print "*** Results: " . dump( @results ) . "\n";
  print ucfirst "add" . "d group(s) " . join( "\n    ", map { $jira->substitute_format( '%n', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_deletegrp {
  my $stat = "";

  my $this = shift;

  my $long_usage = JiraCLI::Groups_IF::gcli_deletegrp_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  
  if ( not ( $opt_force or $this->confirm( "Really delete group $subject ?", 'no' ))) {
      $this->print( ucfirst "group $subject not d.\n" );
      return $stat;
  }

  my $endpoint = '/group';

  my @results;								 
  my $result_obj;
  try {
      $result_obj = $jira->rest_delete( $endpoint . '?groupname=' . $subject );
  } catch {
      die "Error for '$subject': $_\n";
  };
      
  push( @results, $result_obj );
  print ucfirst "delete" . "d group $subject\n";

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

  my $long_usage = JiraCLI::Groups_IF::gcli_editgrp_usage();
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

  my $jira = $this->preference( 'jira_connector' );

  # initial option checking here
  my $subject = shift @ARGV;
  if ( not $subject ) {
      return "Error: Missing group argument.\n";
  }
  my $subject_id;
  # TODO / FIXME - Make sure $subject_id asserts!
  try {
      $subject_id = $jira->assert_object_id( 'group', $subject );
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
	      $subject_id = $jira->get_object_id( 'group', $opt_group );
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
      $result_obj = $jira->rest_put( $endpoint, $params );
  } catch {
      die ucfirst "edit group failed: $_.\n";      
  };
  push( @results, $result_obj );
  print ucfirst "edit" . "d group " . join( "\n    ", map { $jira->substitute_format( '%n as %i', $_ ) } @results ) . "\n";

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }
  print "**** UNIMPLEMENTED: " . 'command editgrp in JiraCLI::Groups' . "\n";

  return $stat;
}


sub assert_project_id {
    my ($this, $pid ) = @_;

    my $jira = $this->preference( 'jira_connector' );

    my $project_id;
    try {
	$project_id = $jira->get_project_id( $pid );
    } catch {
	die "Cannot determine id for project object \"$pid\" ($_).\n";
    };
    $this->set( 'current_project', $pid );
    $this->set( 'current_project_id', $project_id );
    $this->set( 'prompt', "($pid)" . '@csc>' );

    return $project_id;
}

1;
