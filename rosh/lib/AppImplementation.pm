package AppImplementation;
################################################################################

=head1 package
=head2 AppImplementation

 Version: 0.0.1
 Purpose: 
    Virtual class to provide implementations for pluggable application modules.
 Description:
    Subclass this package to inherit capabilities for a pluggable
    modular application. This class is designed to be used together
    with class AppRegister which models complex applications that are
    extensible via plugin applications. The AppImplementation class should be
    subclassed by all the plugin application objects that extend an 
    AppRegister application (frame).
 Restrictions: none
 Author: Axel Mahler, ickooch@gmail.com

=head1 Function

=cut

################################################################################

use strict;

use base qw( CLI_Dialog );

use Carp;
use Tracer;
use Text::Wrap;

use Globals;

################################################################################
################################################################################

=head2 new

 Purpose: 
    Define default (fallback) new method
 Parameters: none
 Return value: none
 Description:
    This method should never be called because it is supposed to be overridden by the
    derived class.
 Restrictions: none

=cut

################################################################################

sub new {
  carp("\"new\" method undefined in application implementation class. Please override method " . __PACKAGE__ . "::new\n");
}

################################################################################
################################################################################

=head2 provide

 Purpose:
    Register a provided command. This defines the mapping from a logical command
    name which is externally visible (e.g. can be used on command line) to a 
    name of a subroutine that serves as entry point for the command.
 Parameters: [method] -- $mappings - ref to array of arrays: [ [ '<string:command>', '<string:sub name>' ], .. ]
 Return value: none
 Description:
 Restrictions: none

=cut

################################################################################

my %provided_entries;
sub provide {
  my ($this, $mappings) = @_;

  my $class = ref($this);
  my $subname;
  my $coderef;
  foreach my $this_mapping (@$mappings) {
    my $subname = $class . "::" . $this_mapping->[1];
    eval('$coderef = \&{$subname}');
    if ($@) {
      log_error("Registration of provided command implementation for " . $this_mapping->[0] . " failed: $@");
      next;
    }
    $provided_entries{$this_mapping->[0]} = $coderef;
    $this->{ 'provided_entries' }->{ $this_mapping->[0] } = $coderef;
  }
}

sub provided_entries {
    my $this = shift;
    
    print "** AppImplementation::provided_entries:\n  " . join( "\n  ", keys %{ $this->{ 'provided_entries' } } ) . "\n";
}

################################################################################
################################################################################

=head2 coderef

 Purpose: 
    Return reference to a command procedure entry point.
 Parameters: $command - name of the procedure subroutine 
 Return value: a perl code reference to the procedure's entry point or undef
 Description:
 Restrictions: none

=cut

################################################################################

sub coderef {
  my ($this, $command) = @_;

  return $provided_entries{$command}
    if (defined($provided_entries{$command}));

  return undef;
}

sub version {
  my $this = shift;

  return $this->prop('version', @_);
}

sub frame {
  my $this = shift;

  return $this->prop('frame', @_);
}

################################################################################
################################################################################

=head2 prop

 Purpose: 
    Set or retrieve a property of the AppImplementation object
 Parameters: property name, (optional) property value
 Return value: property value
 Description:
 Restrictions:
    Only known properties of interface objects can be accessed through this 
    interface. This method is intended to be called internally via special
    methods that bear the name of the property.

=cut

################################################################################

sub prop {
  my ($this, $prop_name, $prop_val) = @_;

  $this->{$prop_name} = $prop_val
    if (defined($prop_val));

  return $this->{$prop_name};
}

sub is_initialized {
  my $this = shift;

  return defined($this->{'frame'});
}

################################################################################
################################################################################

=head2 terminate

 Purpose: 
    Provide controlled means to bail out of a procedure.
    The terminate method shall dispatch to the appropriate command termination
    routine defined by the application frame.
 Parameters: [optional] message to send to user upon termination
 Return value: none - this command doesn't return!
 Description:
 Restrictions:

=cut

################################################################################

sub terminate {
  my ($this, $code) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->get_shell->terminate($code);
}

################################################################################
################################################################################

=head2 log, trace, dialog

 Purpose: 
    Provide access to certain output, and user interaction routines that 
    are implemented by the application frame.
 Parameters: [optional] message to send
 Return value: log, trace: this - dialog: dialog object
 Description:
 Restrictions:

=cut

################################################################################

sub log_msg {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->get_shell->log_error($msg);

  return $this;
}

sub log_error {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->get_shell->log_error($msg);

  return $this;
}

sub trace {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->get_shell->trace($msg);

  return $this;
}

sub cache {
    my ( $this, $key, $object, $category ) = @_;

    my $cache;
    if ( not exists $this->{ 'cache' } ) {
	$this->{ 'cache' } = {};
    }
    if ( $category ) {
	if ( not exists $this->{ 'cache' }->{ $category } ) {
	    $this->{ 'cache' }->{ $category } = {};
	    $this->{ 'cache' }->{ '_categories' }->{ $category } = 1;
	}
	$cache = $this->{ 'cache' }->{ $category };
    } else {
	$cache = $this->{ 'cache' };
    }
    $cache->{ $key } = $object;

    return $object;
}

sub cache_lookup {
    my ( $this, $key, $category ) = @_;

    my $cache;
    if ( not exists $this->{ 'cache' } ) {
	die "Cache not initialized.\n";
    }
    if ( $category ) {
	if ( not exists $this->{ 'cache' }->{ $category } ) {
	    die "Category $category not initialized in cache.\n";
	}
	$cache = $this->{ 'cache' }->{ $category };
    } else {
	$cache = $this->{ 'cache' };
    }
    if ( not exists $cache->{ $key } ) {
	die "No object cached for key $key.\n";
    }
    return $cache->{ $key };
}

sub uncache {
    my ( $this, $key, $category ) = @_;

    my $cache;
    if ( $category ) {
	$cache = $this->{ 'cache' }->{ $category };
    } else {
	$cache = $this->{ 'cache' };
    }
    if ( exists $cache->{ $key } ) {
	$cache->{ $key }->{ 'cancelled' };
	return $key;
    }
    return;
}

sub dialog {
  my ($this) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  return $this->get_shell->dialog();
}

sub print {
  my ($this, $output) = @_;

  $this->dialog->printout($output);

  return $this;
}

sub get_description {
    my ( $this, $hint ) = @_;

    $hint =~ s/^"//;
    $hint =~ s/"$//;
    return $hint
	unless ( $hint =~ m/^@/ );

    $hint =~ s/^@//;
    die "Input file '$hint' does not exist.\n"
	unless ( -f $hint );

    my ( $cont, $cont_fh );
    open( $cont_fh, '<', $hint )
	or die "Cannot open input file '$hint': $!\n";

    $cont = join( '', <$cont_fh> );
    close $cont_fh;

    return $cont;
}

sub get_content {
    my $this = shift;

    return $this->get_description( @_ );
}

sub short_date {
    my ( $this, $dstring ) = @_;

    # truncate jira timestrings "2017-07-19T18:39:07.087+0200" =>
    #               "2017-07-19 18:39"
    $dstring =~ s/:\d\d\..*//;
    $dstring =~ s/T/ /;

    return $dstring;
}

sub wrap_text {
    my ( $this, $text, $indent ) = @_;

    $indent ||= '  ';
    
    my @text = map { $_ =~ s/[^[:print:]]+//g; $_ } split( "\n", $text );
    # remove the occasional non-printable junk
    local $Text::Wrap::columns = 80;
    $text = join( "\n", map { wrap( $indent, $indent, $_ ) } @text );

    return $text;
}
    
sub max_strlen {
    my ( $this, $strings ) = @_;

    my $max = 1;
    foreach my $s ( @{ $strings } ) {
	my $l = length( $s );
	$max = $l
	    if ( $l > $max );
    }
    return $max;
}

# Decode request strings of the form "comments,-desc,+actions,attachment"
# This is used to answer questions "with[out]( 'Description', $requests )?"
# where '+' (or nothing) in front of an attribute means 'positively with'
# and a '-' means 'positively without. If an attribute is not mentioned
# in the $requests argument, the answer to 'with' or 'without' will be "no".
#
sub match_request {
    my ( $this, $norm, $request ) = @_;

    my @requests = split( ',', $request );
    my ( $want, $shun );
    foreach my $req ( @requests ) {
	$req =~ m/([+\-])?(\S+)/;
	my ( $ind, $pat ) = ( $1, $2 );
	next unless ( $norm =~ m/^${pat}/i );
	if ( $ind ) {
	    if ( $ind eq '+' ) {
		$want = 1;
		last;
	    } else {
		$shun = 1;
		last;
	    }
	} else {
	    $want = 1;
	    last;
	}
    }
    return $want ? 1 : ( $shun ? -1 : 0 );
}

sub with {
    return match_request( @_ ) > 0;
}

sub without {
    return match_request( @_ ) < 0;
}

# sub preference: access process variables (set variables) from builtin 
#                 feature
#
sub preference {
  my ($this, $varname) = @_;

  return $this->frame->get_shell->get_builtin()->set($varname);
}

sub get_shell {
    my $this = shift;

    return $this->frame->get_shell;
}

sub get_app_data_path {
    my $this = shift;

#    my $appname = $this->frame->get_application_name();
    my $appname = $this->preference( 'current_realm' );

    my $p = $ENV{ 'HOME' } . '/.rosh.d/var/' . $appname;
    $p =~ s/\\/\//g;

    return $p;
}

# sub: access process variables (set variables) from builtin 
#                 feature
#
sub set {
  my ( $this, $varname, $value ) = @_;

  return $this->frame->get_shell->get_builtin()->set( $varname, $value );
}

1;
