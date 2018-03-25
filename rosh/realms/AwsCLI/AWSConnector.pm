package AWSConnector;
################################################################################

=head1 package
=head2 AwsConnector

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

use JSON;

# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Data::Dump qw( dump );
use MIME::Base64 qw( decode_base64 encode_base64 );
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

  $this->prop( 'url', $this->preference( 'aws_url' ));
  $this->prop( 'token', $this->preference( 'aws_access_token' ));
  $this->prop( 'api', $this->preference( 'aws_api_version' ));
  $this->prop( 'region', $this->preference( 'aws_region' ));
  $this->prop( 'color', $this->preference( 'aws_color' ));
  
  die "Incomplete AWS profile parameters - cannot establish connection.
URL = " . $this->prop( 'url' ) . "
Token = " . $this->prop( 'token' ) . "
Region = " . $this->prop( 'region' ) . "
API Vers = " . $this->prop( 'api' ) . "\n"
    unless ( $this->prop( 'url' ) && $this->prop( 'token' ) 
	     && $this->prop( 'api' ) && $this->prop( 'region' ) );

  if ( exists $params{ 'interactive' } and  $params{ 'interactive' } ) {
      if ( not exists $ENV{ 'HTTPS_PROXY' } ) {
	  $this->print( "** Warning: No proxy defined in environment.\n");
      }
      my $awsver = `aws --version`;
      chomp $awsver;
      $this->print( 'Connected to AWS via ' . $awsver . "\n" );
  }
  
  return $this;
}

########################### Aws Access Methods


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

    while ( $result =~ m/%F:([A-Za-z_\-.]+)([({](\d+)[)}])?/igm ) {
	my $fld = $1;
	my $width;
	if ( $3 ) {
	    $width = $3;
	}
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
	    if ( $width ) {
		$s = sprintf( "%-${width}s", $s );
	    }
	    $result =~ s/%F:${fld}([({](\d+)[)}])?/${s}/m;
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

sub awscli {
    my ( $this, @args ) = @_;

    my $access_token = $this->prop( 'token' );
    my $xwhat = decode_base64( $access_token );
    ( $ENV{ 'AWS_ACCESS_KEY_ID' }, $ENV{ 'AWS_SECRET_ACCESS_KEY' } ) = split( /,/, $xwhat );
    $ENV{ 'AWS_DEFAULT_REGION' } = $this->prop( 'region' );
    $ENV{ 'AWS_DEFAULT_OUTPUT' } = 'json';

    my $cmd = 'aws ' . join( ' ', @args );
    # print "** exec cmd: $cmd\n";
    if ( $this->preference( 'show_curl' ) ) {
      print $cmd . "\n";
    }
    my $res = `$cmd 2>&1`;

    my $result;
    if ( $res ) {
	$result = from_json( $res );
    }
    # print "*** Got result $result: " . Tracer::phash( $result, qw( Reservations ) ) . "\n";
    return $result;
}

#
# fake methods for REST API access
# They are all diverted to the "aws ec2" commandline call.
# 
#
sub rest_get_list {
    my $r = awscli( @_ );
    if ( ref $r eq 'ARRAY' ) {
	return $r;
    }
    if (( ref $r eq 'HASH' ) and ( scalar( %{ $r } ) == 1 ) and
	( ref $r->{ (keys %{ $r })[ 0 ] } eq 'ARRAY' )) {
	return $r->{ (keys %{ $r })[ 0 ] };
    }
    die "** Error: Request does not yield a list object.\n";

    return;
}

sub rest_get_single {
    return awscli( @_ );
}

sub rest_post {
    return awscli( @_ );
}

sub rest_put {
    return awscli( @_ );
}

sub rest_delete {
    return awscli( @_ );
}

1;
