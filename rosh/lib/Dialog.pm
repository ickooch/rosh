package Dialog;

use strict;

sub new {
  return bless({}, shift);
}

sub check {
  print STDERR "** ERROR: Virtual method \"check\" in package " . __PACKAGE__ . " not overridden.\n";
}

sub prompt_logon {
  print STDERR "** ERROR: Virtual method \"prompt_logon\" in package " . __PACKAGE__ . " not overridden.\n";
}

sub ask_confirm {
  print STDERR "** ERROR: Virtual method \"ask_confirm\" in package " . __PACKAGE__ . " not overridden.\n";
}

sub printout {
  print STDERR "** ERROR: Virtual method \"printout\" in package " . __PACKAGE__ . " not overridden.\n";
}

1;
