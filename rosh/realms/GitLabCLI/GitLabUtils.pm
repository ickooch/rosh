package GitLabUtils;

use Exporter;

use base qw( Exporter );

use File::Basename;

@EXPORT = qw( 
   get_path_head
   get_path_tail
   is_sha
);

sub get_path_head { # for path '/foo/bar/foom/file' return 'foo'
    my $path = shift;

    return $path
	unless ( $path );
    my $rev_path = join( '/', reverse ( split( '/', $path ) ) );
    return basename( $rev_path );
}

sub get_path_tail { # for path '/foo/bar/foom/file' return 'bar/foom/file'
    my $path = shift;

    # if path is just a name, then tail and name shall be identical
    if ( $path !~ m/\// ) {
	return $path;
    }
    
    my $rev_path = dirname ( join( '/', reverse ( split( '/', $path )
    ) ) );
    return join( '/', reverse ( split( '/', $rev_path ) ) )
}

# resolve_path( 'foo/bar/flum/../blur/./goo/../../tada' ) . "\n"; # => 'foo/bar/tada'
# resolve_path( 'foo/bar/flum/../../../tada' ) . "\n"; # => 'tada'
# resolve_path( 'foo/bar/flum/../../..' ) . "\n"; # => ''
# resolve_path( 'foo/bar/flum/../../../../..' ) . "\n"; # => ''
# resolve_path( 'foo/bar/flum/../../../../../tada' ) . "\n"; # => 'tada'
# 
sub resolve_path {
    my $path = shift;

    my @path = split( '/', $path );
    my ( $this, $prev )  = ( 0, undef );
    my $curlength = scalar( @path );
    while ( $this < $curlength ) {
	if ( $path[ $this ] eq '.' ) {
	    splice( @path, $this, 1 );
	    $curlength = scalar( @path );
	    next;
	}
	if ( $path[ $this ] eq '..' ) {
	    if ( $this > 0 ) {
		splice( @path, $this - 1, 2 );
		$this -= 1;
	    } else {
		splice( @path, $this, 1 );
	    }
	    $curlength = scalar( @path );
	    next;
	}
	$this += 1;
    }

    return join( '/', @path );
}

sub is_sha {
    my $str = shift;

    # a git sha is either 40 or 7 characters long, and consist of hex digits
    return ( ( $str =~ m/^[0-9a-f]{40}$/ ) or
	     ( $str =~ m/^[0-9a-f]{7}$/ ) );
}

1;
