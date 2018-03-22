#
# Utility package "Tracer". 
# Subclass this package to inherit basic tracing capabilities for
# an application that shall be traceable.
#


package Tracer;
################################################################################

=head1 package
=head2 Tracer

 Version: 0.0.1
 Purpose: 
    Provide modular and controllable tracing and logging facilities 
    to an application.
 Description:     
    Subclass this package to inherit basic tracing capabilities for
    an application that shall be traceable.
 Restrictions: none
 Author: Axel Mahler, ickooch@gmail.com

=head1 Function

=cut

################################################################################

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (
	      phash
	      trace
	      log_msg
	      log_error
	      set_trace_prefix
	      set_trace_controller
	      set_trace_file
	      trace_on
	      trace_off
	      debprint
	      debarray
	      debhash
	     );

@EXPORT_OK = qw(
    $debugging_enabled
    );

use strict;

use Globals; # to get hands at $progname, and $KEEP
use File::Basename;
use Time::HiRes qw( gettimeofday tv_interval );
use Data::Dump qw( dump );
use Scalar::Util qw/reftype/;

our $debugging_enabled = 0;


my $prefix = "** PLEASE SET TRACER PREFIX:";
my $trace_controller = "APP_TRACE"; # override! Name of environment variable to control tracing
my $trace_file;

use vars qw( $progname $APP );

BEGIN {
  $progname = basename($0, '.exe');
  $trace_file = "c:/temp/${progname}_${$}_log.txt"; # override! Name of file to send traces to
}

sub set_trace_prefix {
  if (scalar(@_) == 2) {
    my $this = shift;
    $this->{'trace_prefix'} = shift;
  } else {
    $prefix = shift;
  }
}

sub set_trace_controller {
  if (scalar(@_) == 2) {
    my $this = shift;
    $this->{'trace_controller'} = shift;
  } else {
    $trace_controller = shift;
  }
}

sub set_trace_file {
  if (scalar(@_) == 2) {
    my $this = shift;
    $this->{'trace_file'} = shift;
  } else {
    $trace_file = shift;
  }
}

sub trace_file {
  if (scalar(@_) == 2) {
    my $this = shift;
    return($this->{'trace_file'});
  } else {
    return($trace_file);
  }
}

sub trace_prefix {
  if (scalar(@_) == 2) {
    my $this = shift;
    return($this->{'trace_prefix'})
      unless($this->{'trace_prefix'} eq "** PLEASE SET TRACER PREFIX:");
  }
  return($prefix);
}

sub trace_on {
  my $this;
  $this = shift
    if (scalar(@_) == 1);

  my $local_controller;
  if (defined($this)) {
    $local_controller ||= $this->{'trace_controller'};
  }
  $local_controller ||= $trace_controller;

  $ENV{$local_controller} = 1;
  $this->trace("Tracing turned on at " . ctime(time));
}

sub trace_off {
  my $this;
  $this = shift
    if (scalar(@_) == 1);

  my $local_controller;
  if (defined($this)) {
    $local_controller ||= $this->{'trace_controller'};
  }
  $local_controller ||= $trace_controller;

  $this->trace("Tracing turned off at " . ctime(time));
  $ENV{$local_controller} = undef;
}

sub trace {
  my ($this, $msg);
  ($this, $msg) = @_
    if (scalar(@_) == 2);
  $msg ||= shift;

  my ($local_prefix, $local_controller);
  if (defined($this)) {
    $local_prefix ||= $this->{'trace_prefix'};
    $local_controller ||= $this->{'trace_controller'};
  }
  $local_prefix ||= $prefix;
  $local_controller ||= $trace_controller;
  return
    unless (defined($ENV{$local_controller}));

  if (defined($this)) {
    $this->log_msg("$local_prefix $msg\n");
  } else {
    log_msg("$local_prefix $msg\n");
  }
}

use Time::localtime;
sub log_msg {
  my ($this, $msg);
  ($this, $msg) = @_
    if (scalar(@_) == 2);
  $msg ||= shift;

  my $logfn;
  if (defined($this)) {
    $logfn ||= $this->{'trace_file'};
  }
  $logfn ||= $trace_file;

  my $timestamp = ctime();
  chomp($timestamp);
  open (LOG, ">>$logfn") or return;
  chomp($msg);
  print LOG "$timestamp: $msg\n";
  close (LOG);

  print "$timestamp: $msg\n"
    if ($ENV{'APP_LOG_CONS'});
}
  
sub log_error {
  my ($this, $msg);
  ($this, $msg) = @_
    if (scalar(@_) == 2);
  $msg ||= shift;

  my $logfn;
  if (defined($this)) {
    $logfn ||= $this->{'trace_file'};
  }
  $logfn ||= $trace_file;

  my $timestamp = ctime();
  chomp($timestamp);
  open (LOG, ">>$logfn") or return;
  chomp($msg);
  print LOG "$timestamp: **ERROR: $msg\n";
  close (LOG);

  print "$timestamp: **ERROR: $msg\n"
    if ($ENV{'APP_LOG_CONS'});
}
  
sub timer_start {
  my $this = shift;

  if (defined($this->{'time_caller'})) {
    my @caller_dat = caller 1;
    my $caller = join('+', @caller_dat[3,4]); # subroutine, params
    $this->log_error ("Recursive call to timer start from $caller_dat[3] line $caller_dat[2]", 'warning')
      if ($caller eq $this->{'time_caller'});
    return;
  }

  $this->{'time_last'} = 0.0;
  $this->{'time_t0'} = [gettimeofday];
  $this->{'time_caller'} = join('+', (caller 1)[3,4]); # take this as "fingerprint" of calling context
}

sub timer_stop {
  my $this = shift;

  my $caller = join('+', (caller 1)[3,4]); # subroutine, params
  return 
    unless ($caller eq $this->{'time_caller'});

  $this->{'time_last'} = tv_interval($this->{'time_t0'});
  $this->{'time_total'} += $this->{'time_last'};
  $this->{'time_caller'} = undef;
}

sub timer_get {
  my $this = shift;

  return [ $this->{'time_last'}, $this->{'time_total'} ];
}

sub timer_reset {
  my $this = shift;

  $this->{'time_total'} = 0.0;
  $this->{'time_last'} = 0.0;
  $this->{'time_caller'} = undef;
}

sub phash {
    my $href = shift;
    my $prefix = pop;
    my @expand = @_;

    if ( defined $prefix and ( $prefix =~ m/\S+/ ) ) {
	# out prefix is not a prefix
	push( @expand, $prefix );
	$prefix = undef;
    }
    $prefix = '  '
	if ( not defined $prefix );
    my $expand = {};
    foreach my $k ( @expand ) {
	next
	    if ( not defined $k );
	my @flds = split( /\./, $k, 2 );
	my $kx = shift( @flds );
	$expand->{ $kx } = @flds ? [ split( /,/, $flds[ 0 ] ) ] : undef;
    }
    my $res = "";

    while (my ($k, $v) = each ( %{ $href } )) {
	if ( ref $v and exists $expand->{ $k } ) {
	    $res .= "$prefix$k =>\n";
	    if ( ref $v eq 'HASH' ) {
		$res .= phash( $v, ref $expand->{ $k } ? @{ $expand->{ $k } } : $expand->{ $k }, $prefix . '  ' );
	    } elsif ( ref $v eq 'ARRAY' ) {
		$res .= "[\n$prefix" . join( "\n$prefix", @{ $v } ) . "\n]\n";
	    } elsif ( ref $v eq 'CODE' ) {
		$res .= $v . "\n";
	    } elsif ( reftype $v eq 'HASH' ) {
		$res .= phash( $v, ref $expand->{ $k } ? @{ $expand->{ $k } } : $expand->{ $k }, $prefix . '  ' );
	    } else {
		$res .= join( "\n$prefix", $v ) . "\n";
	    }
	} else {
	    $res .= "$prefix$k => $v\n";
	}
    }
    return $res;
}

1;
