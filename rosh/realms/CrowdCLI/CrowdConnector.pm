package CrowdConnector;
################################################################################

=head1 package
=head2 CrowdConnector

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

  $this->prop( 'url', $this->preference( 'crowd_url' ));
  $this->prop( 'token', $this->preference( 'crowd_access_token' ));
  $this->prop( 'api', $this->preference( 'crowd_api_version' ));
  $this->prop( 'color', $this->preference( 'crowd_color' ));
  
  # FIXME: Default should be 1 for production environments - this should be configurable
  $this->ssl_verify_hostname( 0 ); 

  die "Incomplete Crowd profile parameters - cannot establish connection.
URL = " . $this->prop( 'url' ) . "
Token = " . $this->prop( 'token' ) . "
API Vers = " . $this->prop( 'api' ) . "\n"
    unless ( $this->prop( 'url' ) && $this->prop( 'token' ) && $this->prop( 'api' ) );

  if ( exists $params{ 'interactive' } and  $params{ 'interactive' } ) {
      my $version;
      try {
	  # to validate Crowd connection, make a simple call to the API
	  my $endpoint = '/1/group/membership';

	  my $results;
	  # the 'memberships' request is going to throw XML data at us, no JSON
	  $results = $this->load_base_url( '/' )->rest_get_raw( $endpoint );
      } catch {
	      die "** ERROR: Could not connect to Crowd!
** Check in Crowd Web IF that your workstation IP is cleared for accessing Crowd API.\n";
      };

      $this->print( 'Connected to Crowd V-3' .
		    ' (Build xyz ) at ' . $this->{ 'url' } . "\n" );
      $this->frame->builtin->set( 'crowd_server_version', ' V-3' );
  }
  
  return $this;
}

########################### Supply Authentication Header 
#                                overriding WebServiceConnector::get_auth_header

sub get_auth_header {
    my $this = shift;
    return {
	'Authorization' => 'Basic ' . $this->prop( 'token' ),
	'Content-Type' => 'application/json', 
	'Accept' => 'application/json,application/xml', 
    }
}

########################### Crowd Access Methods


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

    while ( $result =~ m/%F:([A-Za-z_\-.]+)/igm ) {
	my $fld = $1;
	# for referencing custom fields by their user space names
	if ( $check_field_maps ) {
	    $fld = $this->reverse_map_field( $fld );
	}
	my @flds = split(/\./, $fld );
	my $s = $data;
	foreach my $f ( @flds ) {
	    if ( ref $s->{ $f } eq 'ARRAY' ) {
		# try to be smart...
		if ( ref ${ $s->{ $f }}[0] eq 'HASH' ) {
		    # if this is an array of hashes, we try to map it
		    if ( exists ${ $s->{ $f }}[0]->{ 'name' } ) {
			$s = join( "\n  ", map { $_->{ 'name' } } @{ $s->{ $f } });
		    } else {
			$s = join( "\n  ", map { printhash( $_ ) } @{ $s->{ $f } });
		    }
		} else {
		    # the array appears to be scalars
		    $s = join( "\n  ", @{ $s->{ $f } } );
		}
		next;
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
	    $result =~ s/%F:${fld}/${s}/m;
	}
    }
    return $result;
}

sub printhash {
    my $hash = shift;

    my @res;
    while ( my ( $k, $v ) = each %{ $hash } ) {
	push( @res, "$k: $v" );
    }
    return join( '; ', @res );
}

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

sub map_field {
    my ( $this, $field ) = @_;

    $this->init_fmap();
    if ( exists $this->{ 'issue_field_map' }->{ $field } ) {
	return $this->{ 'issue_field_map' }->{ $field };
    }
    return $field;
}
       
sub reverse_map_field {
    my ( $this, $field ) = @_;

    $this->init_fmap();
    if ( exists $this->{ 'inverse_issue_field_map' }->{ $field } ) {
	return $this->{ 'inverse_issue_field_map' }->{ $field };
    }
    return $field;
}

# Use with Try::Tiny
sub get_user {
    my ( $this, $user_email ) = @_;

    my @user = 
    @{ $this->get_list_data( '/api/' .  $this->preference(
				 'crowd_api_version' )
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

1;
