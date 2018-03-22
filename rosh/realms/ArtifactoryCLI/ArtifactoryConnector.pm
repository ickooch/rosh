package ArtifactoryConnector;
################################################################################

=head1 package
=head2 ArtifactoryConnector

 Version: 0.0.1
 Purpose: 
    Provide interface object to manage the gory details of a REST
    Client based server 'connection' 
 Description:

 Restrictions: none
 Author: Axel Mahler

=head1 Function

=cut

################################################################################

use strict;

require RESTConnector;
use base qw( RESTConnector );

use Carp;
use Tracer;
use Globals;
use HTTP::Status qw(:constants :is status_message);

use JSON;

# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Data::Dump qw( dump );
use MIME::Base64;
use Try::Tiny;
use URL::Encode::XS qw( url_encode url_decode );

################################################################################
################################################################################

=head2 new

 Purpose: 
    Define default (fallback) new method
 Parameters: AppRegister object as application frame (needed to access
             Builtins and connection properties)
 Return value: none
 Description:
    
 Restrictions: none

=cut

################################################################################

sub new {
  my $this = bless({}, shift);
  $this->frame( shift );

  my %params = @_;
  
  $this->version('1.0.0');

  $this->prop( 'url', $this->preference( 'atf_url' ));
  $this->prop( 'token', $this->preference( 'atf_access_token' ));
  $this->prop( 'api', $this->preference( 'atf_api_version' ));
  $this->prop( 'color', $this->preference( 'atf_color' ));

  # FIXME: Default should be 1 for production environments - this should be configurable
  $this->ssl_verify_hostname( 0 ); 
  
  die "Incomplete Artifactory profile parameters - cannot establish connection.
URL = " . $this->prop( 'url' ) . "
Token = " . $this->prop( 'token' ) . "
API Vers = " . $this->prop( 'api' ) . "\n"
    unless ( $this->prop( 'url' ) && $this->prop( 'token' ) && $this->prop( 'api' ) );

  if ( exists $params{ 'interactive' } and  $params{ 'interactive' } ) {
      my $version = {};
      try {
	  my $sysdump = $this->rest_get_single( '/system' );
	  $this->set_is_admin( 1 );
	  my @vers = map{ $_ =~ s/\s+//g; $_ } 
	  grep{ m/artifactory\.(version|revision|timestamp) / } split( /\n/, $sysdump );
	  foreach my $vi ( @vers ) {
	      $vi =~ s/artifactory\.//;
	      my ( $key, $val ) = split( '\|', $vi );
	      $version->{ $key } = $val;
	  }
	  print "ARTIFACTORY " . dump( $version ) . "\n"
	      if ( $this->preference( 'debug' ) ); 
	  $this->print( 'Connected to Artifactory V-' . $version->{ 'version' } . 
			' (Build ' . $version->{ 'revision' } . ") at $this->{ 'url' }" . "\n" );
	  $this->print( '[Running with administrative privileges.]' );
	  $this->frame->builtin->set( 'artifactory_server_version', ' V-' . $version->{ 'version' } . 
				      ' (Build ' . $version->{ 'revision' } . ' ,' . $version->{ 'timestamp' } . ')' );
      } catch {
	  $this->set_is_admin( 0 );
      };
      if ( not $this->is_admin() ) {
	  try {
	      # returns a RESTClient object
	      my $sysdump = $this->rest_get_raw( '/system/ping' );
	      foreach my $vi ( qw( date server x-artifactory-id ) ) {
		  $version->{ { 'date' => 'timestamp',
				'x-artifactory-id' => 'revision',
				'server' => 'version' }->{ $vi } } = $sysdump->responseHeader( $vi );
	      }
	      $version->{ 'version' } =~ s/Artifactory\///;
	      print "ARTIFACTORY " . dump( $version ) . "\n"
		  if ( $this->preference( 'debug' ) ); 
	      $this->print( 'Connected to Artifactory V-' . $version->{ 'version' } . 
			    ' (Build ' . $version->{ 'revision' } . ") at $this->{ 'url' }" . "\n" );
	      $this->print( '[Restricted privileges - no admin commands available.]' );
	      $this->frame->builtin->set( 'artifactory_server_version', ' V-' . $version->{ 'version' } . 
					  ' (Build ' . $version->{ 'revision' } . ' ,' . $version->{ 'timestamp' } . ')' );
	  } catch {
	      chomp( $! );
	      die "*** ERROR: Connect to Artifactory failed: $_!\n";
	  };
      }
  }
  
  return $this;
}

sub set_is_admin {
    my ( $this, $is_admin ) = @_;

    $this->{ 'is_admin' } = $is_admin;
}

sub is_admin {
    my $this = shift;
    
    return ( exists $this->{ 'is_admin' } and ( $this->{ 'is_admin' } != 0 ));
}

########################### Supply Authentication Header 
#                                overriding WebServiceConnector::get_auth_header

sub get_auth_header {
    my $this = shift;
    return {
	'Authorization' => 'Basic ' . $this->prop( 'token' ),
	'Content-Type' => 'application/json', 
    }
}

########################### Artifactory Access Methods


sub substitute_format {
    my ( $this, $format, $data, %params ) = @_;

    my $result = $format;
    $result =~ s/^"//;
    $result =~ s/"$//s;
    $result =~ s/\\n/\n/g;
    
    my $check_field_maps = 0;
    if ( exists $params{ 'check_mapped' } ) {
	$check_field_maps = 1;
    }

    if ( exists $data->{ 'id' } ) {
	my $s = $data->{ 'id' };
	$result =~ s/%i/${s}/gs;
    }
    if ( exists $data->{ 'description' } ) {
	my $s = $data->{ 'description' };
	$result =~ s/%D/${s}/gs;
    }
    if ( exists $data->{ 'name' } ) {
	my $s = $data->{ 'name' };
	$result =~ s/%n/${s}/gs;
    }
    if ( exists $data->{ 'version' } ) {
	my $s = $data->{ 'version' } ;
	$result =~ s/%V/${s}/gs;
    }
    if ( exists $data->{ 'web_url' } ) {
	my $s = $data->{ 'web_url' } ;
	$result =~ s/%U/${s}/gs;
    }

    # dynamic substitution based on name of field
    # this substitution works for nested fields as well
    while ( $result =~ m/%([Ff]):([A-Za-z_\-.]+)/igm ) {
	my $fmt_letter = $1;
	my $fld = $2;
	my $list_separator = ( $fmt_letter eq 'F' ) ? "\n  " : ', ';
	#print "*** Format letter = $fmt_letter, list separator = >$list_separator<\n";
	# for referencing custom fields by their user space names
	if ( $check_field_maps ) {
	    $fld = $this->reverse_map_field( $fld );
	}
	my @flds = split(/\./, $fld );
	my $s = $data;
	my $i = 0;
	while ( $i < @flds ) {
	    my $f = $flds[ $i++ ];
	    my $lookahead = ( $i < @flds ) ? $flds[ $i ] : undef;
	    if ( ( ref $s->{ $f } eq 'ARRAY' ) and ( @{ $s->{ $f } } ) ) {
		# try to be smart: if the last subscriptor in a %F format
		# references an array of hashes (i.e. there is no subscription *into* the hashes)
		# we try if there is a 'name' field, and take that as representation of the hash.
		# Otherwise we render the entire hashes.
		if (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and not defined $lookahead ) {
		    # if this is an array of hashes, we try to map it
		    if ( exists ${ $s->{ $f }}[0]->{ 'name' } ) {
			$s = join( $list_separator, map { $_->{ 'name' } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} elsif (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and $lookahead ) {
		    if ( exists ${ $s->{ $f }}[0]->{ $lookahead } ) {
			$s = join( $list_separator, map { $_->{ $lookahead } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} else {
		    # the array appears to be scalars
		    $s = join( $list_separator, @{ $s->{ $f } } );
		}
		last;
	    } elsif ( ref $s->{ $f } eq 'ARRAY' ) {
		# there is an array, but it is empty
		$s = undef;
		last;
	    } elsif ( ( ref $s eq 'HASH' ) and exists $s->{ $f } ) {
		$s = $s->{ $f };
		next;
	    }
	    $s = undef;
	    last;
	}
	if ( $s ) {
	    # try to be smart...
	    if ( ref $s eq 'HASH' ) {
		if ( exists $s->{ 'name' } ) {
		    $s = $s->{ 'name' };
		} else {
		    $s = join(',', keys %{ $s });
		}
	    }
	    $result =~ s/%${fmt_letter}:${fld}/${s}/m;
	}
    }    # dynamic substitution based on name of field
    # this substitution works for nested fields as well
    while ( $result =~ m/%([Ff]):([A-Za-z_\-.]+)/igm ) {
	my $fmt_letter = $1;
	my $fld = $2;
	my $list_separator = ( $fmt_letter eq 'F' ) ? "\n  " : ', ';
	#print "*** Format letter = $fmt_letter, list separator = >$list_separator<\n";
	# for referencing custom fields by their user space names
	if ( $check_field_maps ) {
	    $fld = $this->reverse_map_field( $fld );
	}
	my @flds = split(/\./, $fld );
	my $s = $data;
	my $i = 0;
	while ( $i < @flds ) {
	    my $f = $flds[ $i++ ];
	    my $lookahead = ( $i < @flds ) ? $flds[ $i ] : undef;
	    if ( ( ref $s->{ $f } eq 'ARRAY' ) and ( @{ $s->{ $f } } ) ) {
		# try to be smart: if the last subscriptor in a %F format
		# references an array of hashes (i.e. there is no subscription *into* the hashes)
		# we try if there is a 'name' field, and take that as representation of the hash.
		# Otherwise we render the entire hashes.
		if (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and not defined $lookahead ) {
		    # if this is an array of hashes, we try to map it
		    if ( exists ${ $s->{ $f }}[0]->{ 'name' } ) {
			$s = join( $list_separator, map { $_->{ 'name' } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} elsif (( ref ${ $s->{ $f }}[0] eq 'HASH' ) and $lookahead ) {
		    if ( exists ${ $s->{ $f }}[0]->{ $lookahead } ) {
			$s = join( $list_separator, map { $_->{ $lookahead } } @{ $s->{ $f } });
		    } else {
			$s = join( $list_separator, map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} else {
		    # the array appears to be scalars
		    $s = join( $list_separator, @{ $s->{ $f } } );
		}
		last;
	    } elsif ( ref $s->{ $f } eq 'ARRAY' ) {
		# there is an array, but it is empty
		$s = undef;
		last;
	    } elsif ( ( ref $s eq 'HASH' ) and exists $s->{ $f } ) {
		$s = $s->{ $f };
		next;
	    }
	    $s = undef;
	    last;
	}
	if ( $s ) {
	    # try to be smart...
	    if ( ref $s eq 'HASH' ) {
		if ( exists $s->{ 'name' } ) {
		    $s = $s->{ 'name' };
		} else {
		    $s = join( $list_separator, keys %{ $s });
		}
	    }
	    $result =~ s/%${fmt_letter}:${fld}/${s}/m;
	}
    }
    return $result;
}

#     # dynamic substitution based on name of field
#     # this substitution works for nested fields as well
# 
#     while ( $result =~ m/%F:([A-Za-z_.]+)/igm ) {
# 	my $fld = $1;
# 	my @flds = split(/\./, $fld );
# 	my $s = $data;
# 	foreach my $f ( @flds ) {
# 	    if ( ref $s->{ $f } eq 'ARRAY' ) {
# 		$s = join( "\n  ", @{ $s->{ $f } } );
# 		next;
# 	    } elsif ( ( ref $s eq 'HASH' ) and exists $s->{ $f } ) {
# 		$s = $s->{ $f };
# 		next;
# 	    }
# 	    $s = undef;
# 	    last;
# 	}
# 	if ( $s ) {
# 	    if (( ref $s eq 'HASH' ) and ( exists $s->{ 'name' } )) {
# 		$s = $s->{ 'name' };
# 	    }
# 	    $result =~ s/%F:${fld}/${s}/m;
# 	}
#     }

sub format_required_fields {
    my ( $this, $format ) = @_;

    $format =~ s/\\n/\n/g;
    my %mapped = (
	'%i' => 'id',
	'%D' => 'description',
	'%n' => 'name',
	'%V' => 'version',
	'%U' => 'url'
	);
    
    my %fmt_fields;
    my @token = grep { m/^%/ } map{ $_ =~ s/^.+%/%/; $_ } split( /[\s\n]+/gm, $format );

    foreach my $t ( @token ) {
	if ( $t =~ m/%F:(\w+)/ ) {
	    $fmt_fields{ $1 } = 1;
	    next;
	}
	if ( exists $mapped{ $t } ) {
	    $fmt_fields{ $mapped{ $t } } = 1;
	}
    }
    my @rfld = sort keys %fmt_fields;

    return wantarray ? @rfld : join(',', @rfld );
}

sub build_params {
    my ( $this, $params ) = @_;

    foreach my $k ( qw ( help long short force ) ) {
	delete $params->{ $k };
    }
    my %built_params;
    foreach my $k ( keys %{ $params } ) {
	if ( defined $params->{ $k } ) {
	    $built_params{ $k } = $params->{ $k };
	}
    }
    return \%built_params;
}

# Use with Try::Tiny
sub get_user {
    my ( $this, $user_email ) = @_;

    my @user = 
    @{ $this->get_list_data( '/api/' .  $this->preference(
				 'artifactory_api_version' )
    . '/users?search=' . $user_email, 100 ) }; 
    if ( not @user ) {
	die "Unknown user(s) \"$user_email\"\n";
    }
    if ( not @user == 1 ) {
	print Dumper( \@user ) . "\n";
	die "Ambiguous user fragment \"$user_email\"\n";
    }
    my $user = shift( @user );
#    print "User Data: " . Dumper( $user ) . "\n";

    return $user;
}    

sub min {
    my ( $a, $b ) = @_;

    return ( $a > $b ) ? $b : $a;
}


1;
