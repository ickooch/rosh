package CrowdCLI::Users;

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
use POSIX qw( ceil );

# FIXME: XML::Simple is deprecated
use XML::Simple qw(:strict);

use  CrowdCLI::Users_IF;

sub new {
  my $this = bless({}, shift);

  $this->frame( shift );
  $this->version('1.0.0');
  $this->provide([
     ['lsusr', 'cmd_lsusr' ],
     ['descusr', 'cmd_descusr' ],
     ['mkusr', 'cmd_mkusr' ],
     ['editusr', 'cmd_editusr' ],
     ['rmusr', 'cmd_rmusr' ], 
		 ]);
  
  return $this;
}


sub cmd_lsusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Users_IF::gcli_lsusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_lsusr ';
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
      die "** Error: Could not retrieve user information!.
** Please ensure that your workstation IP is cleared for accessing Crowd API.\n";
  };
  if ( not $results->responseHeader( 'content-type' ) eq 'application/xml' ) {
      die "** Error: Received unexpected kind of data: " . $results->responseHeader( 'content-type' ) . "\n";
  }
  my $result_objects = XMLin( $results->responseContent(), 
			      'GroupTags' => { 'users' => 'user' }, 
			      'ForceArray' => [ qw( user ) ],
			      'KeyAttr' => [ qw( membership name ) ]
      );

  my @members = map { keys %{ $_->{ 'users' } } } @{ $result_objects->{ 'membership' } };
  my %users;
  foreach my $this_member ( @members ) {
      $users{ $this_member } = 1;
  }
  @results = sort keys %users;
  if ( $filter_re ) {
      @results = grep{ $_ =~ m/${filter_re}/i } @results;
  }
  print join( "\n", @results ) . "\n";
  
  # end this routine by returning a status indicator; not null means error!

  return $stat;
}

sub cmd_descusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Users_IF::gcli_descusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_descusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_long, $opt_format, $opt_short,  );
  GetOptions (
      'help' => \$opt_help,
      'long|l' => \$opt_long,
      'format|fmt=s' => \$opt_format,
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
      return "Error: Missing user argument.\n";
  }
  if ( $opt_long ) {
      $opt_short = '';
  }
  my $norm_format = "%n ( %F:display-name, %F:email )\n  %F:groups";

  my $endpoint = '/1/user?username=';

  my @results;								 

  my $result_obj = $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $subject );
  if ( $opt_long or
       grep { m/groups/ } $crowd->format_required_fields( $norm_format ) or
       $opt_format and grep { m/groups/ } $crowd->format_required_fields( $opt_format )) {
      $endpoint = '1/user/group/direct?username=';
      my $groupinfo = $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $subject );
      $result_obj->{ 'groups' } = [ map { $_->{ 'name' } } @{ $groupinfo->{ 'groups' } } ];
  }
  push( @results, $result_obj );
  if ( $opt_format ) {
      print join( "\n", map { $crowd->substitute_format( $opt_format, $_ ) } @results ) . "\n"; 
  } elsif ( $opt_long ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  } else {
      print join( "\n", map { $crowd->substitute_format( $norm_format, $_ ) } @results ) . "\n"; 
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_mkusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Users_IF::gcli_mkusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;

  # FIXME: should not be in source code but in preferences
  my $key = 'WoS-2016-Security';
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_mkusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_prototype, $opt_name, $opt_user_email, $opt_surname, $opt_givenname, $opt_groups,  );
  GetOptions (
      'help' => \$opt_help,
      'proto=s' => \$opt_prototype,
      'name|n=s' => \$opt_name,
      'email=s' => \$opt_user_email,
      'surname|sn=s' => \$opt_surname,
      'givenname|gn=s' => \$opt_givenname,
      'groups=s' => \$opt_groups,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $crowd = $this->preference( 'crowd_connector' );

  my $params = {
      'name' => '',
      'active' => 1,
      'first-name' => '',
      'last-name' => '',
      'display-name' => '',
      'email' => '',
  };
  # initial option checking here
  if ( $opt_name and @ARGV ) {
      die "** Error: Explicit user name (--name) and command line arguments cannot be used together.\n";
  }
  $opt_name ||= shift @ARGV;
  if ( not $opt_name ) {
      die "** Error: Missing user argument.\n";
  }

  if ( $opt_prototype ) {
      die "** Error: Add user by prototype ( --proto ) cannot be used together with --groups.\n"
	  if ( $opt_groups );
      my $endpoint = '1/user/group/direct?username=';
      my $groupinfo;
      try {
	  $groupinfo = $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $opt_prototype );
      } catch {
	  chomp $_;
	  die "** Error: Could not get protoype user: $_.\n";
      };
      $opt_groups = join( ',', map { $_->{ 'name' } } @{ $groupinfo->{ 'groups' } } );
  }
  $params->{ 'name' } = $opt_name;
  $params->{ 'first-name' } = $opt_givenname;
  $params->{ 'last-name' } = $opt_surname;
  $params->{ 'display-name' } = "$opt_givenname $opt_surname";
  $params->{ 'email' } = $opt_user_email;

  my @results;								 
  foreach my $this_user ( $opt_name, @ARGV ) {
      # If we have an ldap service, we can reduce admin's work to a minimum -
      #    try to obtain missing user attributes from ldap
      my $user_data;
      my $service_error;
      if ( not ( $params->{ 'name' } and $params->{ 'email' } and $params->{ 'first-name' }
		 and $params->{ 'last-name' } ) ) {
	  try {
	      $user_data = $this->get_shell->request_service( 'ldap', 'get_userinfo', $this_user );
	  } catch {
	      chomp $_;
	      $service_error = $_;
	  };
	  if ( $user_data ) {
	      $params->{ 'name' } = $this_user;
	      $params->{ 'first-name' } ||= $user_data->{ 'givenName' },
	      $params->{ 'last-name' } ||= $user_data->{ 'sn' },
	      $params->{ 'display-name' } ||= $user_data->{ 'displayName' },
	      $params->{ 'email' } ||= $user_data->{ 'mail' },
	  }
      }
      $params->{ 'password' } = {
	  'value' => scramble( $this_user ),
      };
      if ( not $params->{ 'email' } ) {
	  print "** Error: Incomplete user details for $this_user - mail address required!\n";
	  next;
      }
      my $endpoint = '/1/user';
      my $result_obj;
      try {
	  $result_obj = $crowd->load_base_url( '/' )->rest_post( $endpoint, $params );
      } catch {
	  chomp $_;
	  die "Create user failed: $_.\n";
      };
      my $result = from_json( $result_obj->{ 'body' } );
      # preserve generated password so that we can use it in acknowledgement
      $result->{ 'password' } = $params->{ 'password' }->{ 'value' };
      if ( $opt_groups ) {
	  foreach my $this_group ( split( ',', $opt_groups ) ) {
	      $this->add_user_to_group( $this_user, $this_group );
	  }
      }
      push( @results, $result );
      $params = {};
  }
  if ( @results ) {
      print ucfirst "Adde" . "d user " . join( "\n    ", map { $crowd->substitute_format( '%n with initial password %F:password' , $_ ) } @results ) . "\n";
  } else {
      print "* No user account was created.\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub cmd_editusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Users_IF::gcli_editusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_editusr ';
      print join(', ', @ARGV ); print "\n";
  }
  my ( $opt_help, $opt_user_email, $opt_surname, $opt_givenname, 
       $opt_groups, $opt_prototype, $opt_force, $opt_resetpw,  );
  GetOptions (
      'help' => \$opt_help,
      'email=s' => \$opt_user_email,
      'surname|sn=s' => \$opt_surname,
      'givenname|gn=s' => \$opt_givenname,
      'groups=s' => \$opt_groups,
      'proto=s' => \$opt_prototype,
      'force|f' => \$opt_force,
      'reset-password|resetpw' => \$opt_resetpw,
      );

  if ( $opt_help ) {
      print $long_usage;
      return 0;
  }
  my $json = JSON->new->allow_nonref;

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      die "** Error: Missing user argument.\n";
  }

  if ( $opt_prototype ) {
      die "** Error: Change user by prototype ( --proto ) cannot be used together with --groups.\n"
	  if ( $opt_groups );
      my $endpoint = '1/user/group/direct?username=';
      my $groupinfo;
      try {
	  $groupinfo = $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $opt_prototype );
      } catch {
	  chomp $_;
	  die "** Error: Could not get protoype user: $_.\n";
      };
      $opt_groups = join( ',', map { $_->{ 'name' } } @{ $groupinfo->{ 'groups' } } );
  }

  if ( $opt_resetpw and ( $opt_givenname + $opt_surname + $opt_user_email ) ) {
      die "** Error: Changing user properties, and resetting password cannot be done together.\n";
  }
  my $params = {};
  $params->{ 'first-name' } = $opt_givenname
      if ( $opt_givenname );
  $params->{ 'last-name' } = $opt_surname
      if ( $opt_surname );
  $params->{ 'email' } = $opt_user_email
      if ( $opt_user_email );

  my %new_passwords;
  my @results;								 
  foreach my $subject ( @ARGV ) {
      my $result_obj;
      if ( $opt_groups ) {
	  $this->clear_group_memberships( $subject );
	  foreach my $this_group ( split( ',', $opt_groups ) ) {
	      $this->add_user_to_group( $subject, $this_group );
	  }
	  $result_obj = $subject;
      }
      if ( $opt_resetpw ) {
	  if ( $opt_force or $this->confirm( "Reset password for $subject ?", 'no' )) {
	      $params->{ 'password' } = { 'value' => scramble( $subject ) },
	  } else {
	      print "Password for $subject is unchanged.\n";
	  }
	  $result_obj ||= $subject;
      }
      my $endpoint = '/usermanagement/1/user?username=';
      
      if ( %{ $params } ) {
	  try {
	      $result_obj = $crowd->load_base_url( '/' )->rest_put( $endpoint . $subject, $params );
	      $new_passwords{ $subject } = $params->{ 'password' }->{ 'value' };
	  } catch {
	      chomp $_;
	      print ucfirst "** Error: Edit user $subject failed: $_.\n";
	  };
	  next
	      if ( not defined $result_obj );
      }

      push( @results, $result_obj );
  };
  if ( @results ) {
      print ucfirst "Updated user " . join( "\n    ", map { ref $_ ? dump( $_ ) : $_ } @results ) . "\n";
      if ( $opt_resetpw ) {
	  print "New passwords:\n  " . join( "\n  ", map { $_ . ": $new_passwords{ $_ }" } 
					     sort keys %new_passwords ) . "\n";
      }
  } else {
      print "No user entries modified.\n";
  }
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

sub clear_group_memberships {
    my ( $this, $user ) = @_;

    my $crowd = $this->preference( 'crowd_connector' );
    my $endpoint = '1/user/group/direct?username=';
    my $groupinfo;
    try {
	$groupinfo = $crowd->load_base_url( '/' )->rest_get_single( $endpoint . $user );
    } catch {
	chomp $_;
	die "** Error: Could not get current groups for user $user: $_.\n";
    };

    $endpoint = '1/group/user/direct?username=';
    my @grps = map { $_->{ 'name' } } @{ $groupinfo->{ 'groups' } };
    foreach my $this_group ( @grps ) {
	try {
	    $crowd->load_base_url( '/' )
		->rest_delete( $endpoint . $user . '&groupname=' . $this_group );
	} catch {
	    chomp $_;
	    die "** Error: Remove user $user as direct member from group $this_group failed: $_.\n";
	};    
    }
}

sub add_user_to_group {
    my ( $this, $user, $group ) = @_;

    my $crowd = $this->preference( 'crowd_connector' );
    my $endpoint = '/1/group/user/direct?groupname=';
    try {
	$crowd->load_base_url( '/' )
	    ->rest_post( $endpoint . $group, { 'name' => $user } );
    } catch {
	chomp $_;
	die "** Error: Add usr $user to group $group failed: $_.\n";
    };
    return $this;
}

sub scramble {
    my $string = shift;

    my $key = 'WoS-2016-Security';
    my $len = 14;
    
    my @target_map = ( '!', '#', '$', '%', '&', '+', '-', 0..9, '@', 'A'..'Z', '_', 'a'..'z' );
    my $targ_range = @target_map;
    # target_map = list of (typable) characters we want to see in the scrambled text
    
    # CAVEAT: this length-supplementing was not implemented when the user-import file
    #         was generated. If passwords need to be re-generated, it might be necessary
    #         to disable this sequence (for user-Ids < 14 characters).
    if ( length( $string ) < $len ) {
	my $gap_l = $len - length( $string );
	my $supplement = $string x POSIX::ceil( $gap_l / length( $string ) );
	$string .= substr( $supplement, 0, $gap_l );
    }
    my @string_old = split( //, $string );
    my @key = split( //, $key );
    my ( $key_x, $key_len, $str_len ) = ( 0, length( $key ), length( $string ) );
    my $string_new = '';

    my $pos;
    for ( my $pos = 0; $pos < $str_len; $pos++ ) {
	my $c = $string_old[ $pos ];
	my $kc = $key[ $pos % $key_len ];
	my $nc = ( ord( $c ) + ord( $kc ) ) % $targ_range; # limit to 'typable' chars
	$string_new .= $target_map[ $nc ];
    }

    return substr( $string_new, 0, $len );
}    

sub cmd_rmusr {
  my $stat = "";

  my $this = shift;

  my $long_usage = CrowdCLI::Users_IF::gcli_rmusr_usage();
  my $usage = 'Usage: ' . $long_usage;
  $usage =~ s/\nDESCRIPTION:.*//s;
  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print 'Called: cmd_rmusr ';
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

  my $crowd = $this->preference( 'crowd_connector' );

  # initial option checking here
  if ( not @ARGV ) {
      return "Error: Missing user argument(s).\n";
  }

  if ( not ( $opt_force or $this->confirm( "Really remove user" .
					   ( @ARGV > 1 ? 's ' : ' ' ) . join( ', ', @ARGV ) . " ?", 'no' ))) {
      $this->print( ucfirst "User(s) not deleted.\n" );
      return $stat;
  }

  my $endpoint = '/1/user?username=';
  my @results;								 

  foreach my $this_user ( @ARGV ) {
      try {
	  $crowd->load_base_url( '/' )->rest_delete( $endpoint . $this_user );
	  push( @results, $this_user );
      } catch {
	  chomp $_;
	  $this->print( "Delete user $this_user failed: $_.\n" );
      };
  }
  if ( @results ) {
      print ucfirst "remove" . "d user " . join( "\n    ", @results ) . "\n";
  } else {
      print "Nothing happened.\n";
  }

  if ( $this->preference( 'verbose' ) or $this->preference( 'debug' ) ) {
      print join( "\n", map { $json->pretty->encode( $_ ) } @results ) . "\n";
  }

  return $stat;
}

1;
