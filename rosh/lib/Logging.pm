package Logging;

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
  $this->frame->log_error($msg);

  return $this;
}

sub log_error {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->frame->log_error($msg);

  return $this;
}

sub trace {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->frame->trace($msg);

  return $this;
}

sub dialog {
  my ($this) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  return $this->frame->dialog();
}

sub print {
  my ($this, $output) = @_;

  $this->dialog->printout($output);

  return $this;
}

1;
