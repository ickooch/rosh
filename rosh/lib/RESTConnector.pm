package RESTConnector;
################################################################################

=head1 package
=head2 RESTConnector

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

require WebServiceConnector;
use base qw( WebServiceConnector );

use Carp;
use Tracer;
use Globals;
use REST::Client;
use IO::Socket::SSL qw( SSL_VERIFY_NONE SSL_VERIFY_PEER );
use HTTP::Status qw(:constants :is status_message);

use JSON;

# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Data::Dump qw( dump );
use MIME::Base64;
use Try::Tiny;
use URL::Encode::XS qw( url_encode url_decode );
use URI::URL;

use Config;
if ( $Config{ 'osname' } =~ m/Win32/ ) {
    eval( "use Win32::Console::ANSI;");
}
use Term::ANSIColor;
use IO::Handle;

################################################################################
################################################################################

sub get_rest_client {
    my $this = shift;

    if ( not exists $this->{ 'rest_client' } ) {
	$this->{ 'rest_client' } = REST::Client->new();
	$this->{ 'rest_client' }->setHost( $this->get_url() );
    }
    return $this->{ 'rest_client' };
}

sub is_url_encoded {
    my $str = shift;

    return (url_decode( $str ) ne $str);
}

sub ssl_verify_hostname {
    my ( $this, $verify ) = @_;

    my $client = $this->get_rest_client();
    
    if ( $verify ) {
	$ENV{ 'PERL_LWP_SSL_VERIFY_HOSTNAME' } = 1;
	$client->getUseragent()->ssl_opts( 'verify_hostname' => 1 );
	$client->getUseragent()->ssl_opts( 'SSL_verify_mode' => SSL_VERIFY_PEER );
    } else {
	$ENV{ 'PERL_LWP_SSL_VERIFY_HOSTNAME' } = 0;
	$client->getUseragent()->ssl_opts( 'verify_hostname' => 0 );
	$client->getUseragent()->ssl_opts( 'SSL_verify_mode' => SSL_VERIFY_NONE );
    }

    return $this;
}

sub print {
  my ($this, $output) = @_;

  $this->set_my_color();
  $this->dialog->printout($output);
  print color( 'reset' );
  STDOUT->flush();
  
  return $this;
}
    
sub set_my_color {
    my $this = shift;

    print color( $this->{ 'color' } )
	if ( exists $this->{ 'color' } );
}

sub get_base_url {
    my $this = shift;

    my $base_url = '/api/';
    if ( $this->prop( 'api' ) !~ m/^(undef|nil|null|none)$/i ) {
	$base_url .= $this->prop( 'api' );
    }
    if ( exists $this->{ 'url_base' } ) {
	$base_url = $this->{ 'url_base' };
	delete $this->{ 'url_base' };
    }

    return $base_url;
}

sub load_base_url {
    my ( $this, $base ) = @_;

    $this->{ 'url_base' } = $base;

    return $this;
}

sub get_list_data {
    my ( $this, $base_url, $chunk_size ) = @_;

    $chunk_size ||= 100;
    
    my $headers = $this->get_auth_header();
    if ( $this->preference( 'verbose' ) ) {
	print __PACKAGE__ . '::get_list_data - ' . $base_url . "\n";
    }
    my $client = $this->get_rest_client();
    $client->GET(
	$base_url,
	$headers
	);
    my @response_headers = $client->responseHeaders();
    my $item_count = $client->responseHeader( 'X-Total' );
    my $original_item_count = $item_count;
    my @items; 
    if ( $item_count ) {
	if ( $this->preference( 'verbose' ) ) {
	    	print __PACKAGE__ . "::get_list_data - Got $item_count items: " . $client->responseContent() . "\n";
	}
	my $response = from_json( $client->responseContent() );
	my $next_link_url = decode_link( $client->responseHeader( 'Link' ) )->{ 'next' };
	$this->preference( 'debug' ) && print '** ' . $next_link_url . "\n";
	my $url_tmpl = $next_link_url ? $next_link_url : $base_url;
	$url_tmpl =~ s/page=(\d+)/page=%s/;
	$url_tmpl =~ s/&per_page=(\d+)/&per_page=%s/;
	$this->preference( 'debug' ) && print "Got link_url_template = $url_tmpl\n";
	
	my $i = 1;
	$next_link_url = sprintf( $url_tmpl, $i, $chunk_size );
	while( $i ) {
	    $this->preference( 'debug' ) && print "Fetch data with URI: $base_url\n";
	    $this->preference( 'debug' ) && print "Fetch data with URI: $next_link_url\n";
	    $client->GET(
		$next_link_url,
		$headers
		);
	    $next_link_url =  decode_link( $client->responseHeader( 'Link' ) )->{ 'next' };
	    $this->preference( 'debug' ) && print $next_link_url . "\n";
	    my $response = from_json( $client->responseContent() );
	    push( @items, @{$response} );
	    $item_count -= scalar( @{$response} );
	    #	print "Item count: $item_count\n";
	    last
		if ( $item_count <= 0 );
	    $i += 1;
	}
    } else {
	my $resp = from_json( $client->responseContent() );
	if ( ref( $resp ) eq 'ARRAY' ) {
	    @items = @{ $resp };
	} else {
	    push( @items, $resp );
	}
    }
    $this->preference( 'debug' ) && print "Got " . scalar( @items ) . " items, original item count was $original_item_count\n";
    return \@items;
}

sub get_data {
    my ( $this, $base_url ) = @_;
    
    my $headers = $this->get_auth_header();
    
    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };

    if ( $this->preference( 'verbose' ) ) {
	$this->print( __PACKAGE__ . '::get_data - GET ' . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X GET' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }
    $client->GET(
	$base_url,
	$headers
	);
    my @response_headers = $client->responseHeaders();
    
    return from_json( $client->responseContent() );
}

sub rest_get_single {
    my ( $this, $endpoint ) = @_;
    
    my $headers = $this->get_auth_header();
    
    my $client = $this->get_rest_client();
    my $base_url = $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' ) . $endpoint;
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'
    my $webhost = $client->{ '_config' }->{ 'host' };

    if ( $this->preference( 'verbose' ) ) {
	if ( $this->preference( 'debug' ) ) {
	    $this->print( 'Headers: ' . Dumper( $headers ) . "\n" );
	}
	$this->print( __PACKAGE__ . '::rest_get_single - GET ' . $webhost . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X GET' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }
    $client->GET(
	$base_url,
	$headers
	);
    
    if ( is_error( $client->responseCode() )) {
	my $details = $client->responseContent();
	chomp $details;
	die status_message( $client->responseCode() ) . 
	    ( $details ? " ($details)" : '') . "\n";
    }
	 
    my $response;
    try {
	$response = from_json( $client->responseContent() );
    } catch {
	if ( $this->preference( 'verbose' ) ) {
	    my @r_headers = $client->responseHeaders();
	    foreach my $h ( @r_headers ) {
		print "Header $h: " . $client->responseHeader( $h ) . "\n";
	    }
	}
	$response = $client->responseContent();
    };
    
    return $response;
}

sub rest_get_raw {
    my ( $this, $endpoint ) = @_;
    
    my $headers = $this->get_auth_header();
    
    my $client = $this->get_rest_client();
    my $delim = ( $endpoint =~ m/^\// ? '' : '/' );
    my $base_url = $this->get_base_url() . $delim . $endpoint;
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'
    my $webhost = $client->{ '_config' }->{ 'host' };

    if ( $this->preference( 'verbose' ) ) {
	if ( $this->preference( 'debug' ) ) {
	    $this->print( 'Headers: ' . Dumper( $headers ) . "\n" );
	}
	$this->print( __PACKAGE__ . '::rest_get_single - GET ' . $webhost . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X GET' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }
    $client->GET(
	$base_url,
	$headers
	);
#    print "** Got response $client: " . Tracer::phash( $client, qw( _res._headers ) ) . "\n";
    if ( is_error( $client->responseCode() )) {
	my $error_info = $client->responseContent();
	$error_info && $this->print( "** ERROR: $error_info\n" );
	die status_message( $client->responseCode() ) . "\n" . 
	    $client->responseContent() . "\n";
    }

    return $client;
}

sub rest_get_list {
    my ( $this, $endpoint, $chunk_size ) = @_;

    $chunk_size ||= 100;
    
    my $headers = $this->get_auth_header();
    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };

    my $base_url = $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' ) . $endpoint;
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'

    if ( $this->preference( 'verbose' ) ) {
	if ( $this->preference( 'debug' ) ) {
	    $this->print( 'Headers: ' . Dumper( $headers ) . "\n" );
	}
	$this->print( __PACKAGE__ . '::rest_get_list - GET ' . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X GET' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }

    $client->GET(
	$base_url,
	$headers
	);
    if ( is_error( $client->responseCode() )) {
	die status_message( $client->responseCode() ) . "\n";
    }
    my @response_headers = $client->responseHeaders();
    my $item_count = $client->responseHeader( 'X-Total' );
    # print "** got $item_count entries\n";
    my $original_item_count = $item_count;
    my @items; 
    if ( $item_count ) {
	my $response = from_json( $client->responseContent() );
	my $next_link_url = decode_link( $client->responseHeader( 'Link' ) )->{ 'next' };
	# print '** ' . $next_link_url . "\n";
	my $url_tmpl = $next_link_url ? $next_link_url : $base_url;
	$url_tmpl =~ s/page=(\d+)/page=%s/;
	$url_tmpl =~ s/&per_page=(\d+)/&per_page=%s/;
	#    print "Got link_url_template = $url_tmpl\n";
	
	my $i = 1;
	$next_link_url = sprintf( $url_tmpl, $i, $chunk_size );
	while( $i ) {
	    $client->GET(
		$next_link_url,
		$headers
		);
	    if ( is_error( $client->responseCode() )) {
		die status_message( $client->responseCode() ) . "\n";
	    }
	    $next_link_url =  decode_link( $client->responseHeader( 'Link' ) )->{ 'next' };
	    $this->preference( 'verbose' ) && $this->print(
		$next_link_url . "\n" );
	    my $response = from_json( $client->responseContent() );
	    if ( ref ( $response ) eq 'ARRAY' ) {
		push( @items, @{$response} );
		$item_count -= scalar( @{$response} );
	    } else {
		print "[ ** warning ** - got ' " . $response->{ 'message'} . "' as reply from server after $item_count items were received. ]\n";
		last;
	    }
	    last
		if ( ( $item_count <= 0 ) or not $next_link_url );
	    $i += 1;
	}
    } else {
	my $resp = from_json( $client->responseContent() );
	if ( ref( $resp ) eq 'ARRAY' ) {
	    @items = @{ $resp };
	} else {
	    push( @items, $resp );
	}
    }
#    print "Got " . scalar( @items ) . " items, original item count was $original_item_count\n";
    return \@items;
}

sub rest_post {
    my ( $this, $endpoint, $params ) = @_;

    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };
    my $json_headers = ref $params ? to_json( $params ) : $params;
    my $headers = $this->get_auth_header();

    my $base_url = $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' ) . $endpoint;
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'

    if ( $this->preference( 'verbose' ) ) {
	$this->print( __PACKAGE__ . '::rest_post - POST ' . $base_url . "\n" . "  $json_headers\n" );
	my $json = JSON->new->allow_nonref;
	$this->print( __PACKAGE__ . '::rest_post - POST Body:' . "\n" . $json->pretty->encode( $params ) . "\n" );
    }
    my $curl_command =  '-k -D- -X POST';

    if ( ref $params ) {
	$curl_command .= " -d '$json_headers'";
    } else {
	if ( -f $params ) {
	    $curl_command .= " -F 'file=\@$params'";
	    #		$this->print ( " -F 'file=\@$params'" );
	} else {
	    $curl_command .=  " -d '$params'";
	    #		$this->print ( " -d '$params'" );
	}
    }
    while ( my ( $k, $v ) = each %{ $headers } ) {
	$curl_command .= " -H '$k: $v'";
	#	    $this->print( " -H '$k: $v'" );
    }
    $curl_command .=  ' ' . $webhost . $base_url;
    #	$this->print( ' ' . $webhost . $base_url . "\n" );
    
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl ' . $curl_command . "\n" );
    }
    if ( ref $params ) {
	$client->POST(
	    $base_url,
	    $json_headers,
	    $headers,
	    );
    } else {
	# CHEAT: delegate requests that REST::Client cannot do, such as multi-part
	# form-data posts etc. to curl
	my $response = `curl -s $curl_command`;
	return { 'body' => $response };
    }
    if ( is_error( $client->responseCode() )) {
	# print "** rest_post failed. Client $client: " . Tracer::phash( $client, qw ( _res ) ) . "\n";
	my $err_msg = $client->responseContent();
	try {
	    $err_msg = from_json( $err_msg );
	    # print "    ** decoded err_msg $err_msg: " . Tracer::phash( $err_msg, qw( messages ) ) . "\n";
	    if ( exists $err_msg->{ 'errorMessages' } ) {
		$err_msg = ': ' . join( "\n", @{ $err_msg->{ 'errorMessages' } } );
	    } elsif ( exists $err_msg->{ 'message' } ) {
		# some complex put operations throw error responses with a deep
		# details structure. This should be decoded by the calling conmtext.
		$err_msg = $err_msg->{ 'message' };
	    } elsif ( exists $err_msg->{ 'messages' } ) {
		# some complex put operations throw error responses with a deep
		# details structure. This should be decoded by the calling conmtext.
		# print "*** err_msg $err_msg: " . dump( $err_msg ) . "\n";
		$err_msg = $err_msg->{ 'messages' };
	    }
	};
	if ( ref $err_msg ) {
	    # if we have complex error data, return it and let calling
	    # context doing the decoding.
	    die $err_msg;
	}
	# if its plain scalar, return that presumed message along with the status as text
	die status_message( $client->responseCode() ) . "$err_msg\n";
    }

    my @response_headers = $client->responseHeaders();
    my $response_code = $client->responseCode();
    my $response_body = $client->responseContent();

    if ( $response_code >= 400 ) {
	if ( $this->preference( 'verbose' ) ) {
	    print "Response code: $response_code -- Got reponse headers:\n  " . join( "\n  ", @response_headers) . "\n";
	    foreach my $h ( @response_headers ) {
		print "Header $h: " . $client->responseHeader( $h ) . "\n";
	    }
	}
	my $error_message = '';
	my $m = from_json( $response_body )->{ 'message' };
	$error_message .= $m
	    if ( $m );
	$m = from_json( $response_body )->{ 'errorMessages' };
	$error_message .= ref $m ? join( "\n", @{ $m } ) : $m
	    if ( $m );
	die  "$error_message\n" ;
    } 
    return {
	'headers' => \@response_headers,
	'code' => $response_code,
	'body' => $response_body
    };
}

sub rest_put {
    my ( $this, $endpoint, $params ) = @_;

    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };
    my $payload;
    if ( ref $params ) {
	$payload = to_json( $params );
    } else {
	$payload = $params;
    }

    my $headers = $this->get_auth_header();

    my $base_url = $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' )  . $endpoint;
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'

    if ( $this->preference( 'verbose' ) ) {
	my $json = JSON->new->allow_nonref;
	$this->print( __PACKAGE__ . '::rest_put - PUT ' . $base_url . "\n" . " $payload\n" );
	$this->print( __PACKAGE__ . '::rest_put - PUT Body:' . "\n" . $json->pretty->encode( $params ) . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X PUT' );
	$this->print ( " -d '$payload'" );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }

    $client->PUT(
	$base_url,
	$payload,
	$headers,
	);

    if ( is_error( $client->responseCode() )) {
	#print "** rest_post failed. Client $client: " . Tracer::phash( $client, qw ( _res ) ) . "\n";
	my $err_msg = $client->responseContent();
	try {
	    $err_msg = from_json( $err_msg );
	    #print "    ** decoded err_msg $err_msg: " . Tracer::phash( $err_msg, qw( messages ) ) . "\n";
	    if ( exists $err_msg->{ 'errorMessages' } ) {
		$err_msg = ': ' . join( "\n", @{ $err_msg->{ 'errorMessages' } } );
	    } elsif ( exists $err_msg->{ 'message' } ) {
		# some complex put operations throw error responses with a deep
		# details structure. This should be decoded by the calling conmtext.
		$err_msg = $err_msg->{ 'message' };
	    } elsif ( exists $err_msg->{ 'messages' } ) {
		# some complex put operations throw error responses with a deep
		# details structure. This should be decoded by the calling conmtext.
		# print "*** err_msg $err_msg: " . dump( $err_msg ) . "\n";
		$err_msg = $err_msg->{ 'messages' };
	    }
	};
	if ( ref $err_msg ) {
	    # if we have complex error data, return it and let calling
	    # context doing the decoding.
	    die $err_msg;
	}
	# if its plain scalar, return that presumed message along with the status as text
	die status_message( $client->responseCode() ) . "$err_msg\n";
    }
    my @response_headers = $client->responseHeaders();
    my $response_code = $client->responseCode();
    my $response_body = $client->responseContent();

    if ( $response_code >= 400 ) {
	die "$response_body\n";
    } 
    return {
	'headers' => \@response_headers,
	'code' => $response_code,
	'body' => $response_body
    };
}

sub rest_delete {
    my ( $this, $endpoint ) = @_;
    
    my $headers = $this->get_auth_header();
    
    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };
    my $base_url = $this->validate_endpoint( $endpoint );
    $base_url =~ s/\/+/\//g; # turn multiple subsequent '////' into a single '/'

    if ( $this->preference( 'verbose' ) ) {
	$this->print( __PACKAGE__ . '::rest_delete - DELETE ' . $base_url . "\n" );
    }
    if ( $this->preference( 'show_curl' ) ) {
	$this->print( 'curl -k -D- -X DELETE' );
	while ( my ( $k, $v ) = each %{ $headers } ) {
	    $this->print( " -H '$k: $v'" );
	}
	$this->print( ' ' . $webhost . $base_url . "\n" );
    }

    $client->DELETE(
	$base_url,
	$headers
	);
    if ( is_error( $client->responseCode() )) {
	die status_message( $client->responseCode() ) . "\n";
    }
    my @response_headers = $client->responseHeaders();
    my $response_code = $client->responseCode();
    if ( $response_code >= 400 ) {
	my $response_body = $client->responseContent();
	die "$response_body\n";
    } 
    
    return;
}

sub validate_endpoint {
    my ( $this, $endpoint ) = @_;

    # regular endpoints are valid
    return $this->get_base_url() . ( $endpoint =~ m/^\// ? '' : '/' )  . $endpoint
	if ( not $endpoint =~ m/https?:\/\// );

    # if the endpoint is a fully qualified URL, we don't need 
    # - a service base url, and 
    # - we don't need the host part in the supplied endpoint since
    #   this will be automatically prepended by the REST::Client method.
    #
    my $client = $this->get_rest_client();
    my $webhost = $client->{ '_config' }->{ 'host' };

    # we need to remove from the endpoint the leading part that resembles
    # the webhost which is configured in the rest client.

    my $ep_path = URI::URL->new( $endpoint )->path();
    my $webhost_path = URI::URL->new( $webhost )->path();

    if ( $webhost_path eq '/' ) {
	return $ep_path;
    }
    $ep_path =~ s/^${ webhost_path }//;

    return $ep_path;
}

sub decode_link {
    my $raw_link = shift;

    my %linkdat;
    my @linkdat = split( /\s*,\s*/, $raw_link );
    my ( $url, $rel );
    foreach my $linkdat ( @linkdat ) {
	( $url, $rel ) = split( /\s*;\s*/, $linkdat );
	$url =~ s/<//; $url =~ s/>//;
	$url =~ s|^.*/api/v3|/api/v3|;
	$url =~ s|^.*/api/v4|/api/v4|;
	$rel =~ m/rel="(\w+)"/;
	$linkdat{ $1 } = $url;
    }
    return \%linkdat;
}

# FIXME / TODO
# CAVEAT: preference is only used to access global controls, such as "debug" or "verbose"
#         This should possibly be controlled within the applicable logging methods, and the
#         traceing calls should be made unconditionally.
#
# sub preference: access process variables (set variables) from builtin 
#                 feature
#
sub preference {
  my ($this, $varname) = @_;

  return $this->frame->builtin->set($varname);
}

1;
