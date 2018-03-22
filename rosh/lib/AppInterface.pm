package AppInterface;
################################################################################

=head1 package
=head2 AppInterface

 Version: 0.0.1
 Purpose: 
    Virtual class to provide common plugin application properties.
 Description:     
    Subclass this package to inherit plugin capabilities for
    a modular application. This class is designe to be used together
    with class AppRegister which models complex applications that are
    extensible via plugin applications. The AppInterface class should be
    subclassed by all the plugin application objects that extend an 
    AppRegister application (frame).
 Restrictions: none
 Author: Axel Mahler, ickooch@gmail.com

=head1 Function

=cut

################################################################################

use strict;

use Carp;

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
  carp("\"new\" method undefined in application interface class. Please override method " . __PACKAGE__ . "::new\n");
}

################################################################################
################################################################################

=head2 register

 Purpose: 
    Register the interface object and the commands it provides with the AppRegister
    application frame.
 Parameters: none
 Return value: self
 Description:
    Add the application interface, the commands provided by the plugin, usage-, 
    version-, and other applicable information with the application frame.
 Restrictions:
    The object needs to be properly initialized as result of the call to the
    derived class' "new" method. In particular, the application frame object
    containing the plugin needs to be linked to the interface object before 
    this method can be called.

=cut

################################################################################

sub register {
  my $this = shift;

  unless ($this->is_initialized) {
    carp("Attempt to register a interface without an application frame - was the interface properly initialized?\n");
    return $this;
  }

  $this->frame->register_interface($this, @_); # there might be an additional '$prefix' parameter 
                                               # that needs to be passed down

  return $this;
}

################################################################################
################################################################################

=head2 name

 Purpose: 
    Set or retrieve the plugin's name
 Parameters: (optional) name
 Return value: name
 Description: none
 Restrictions: none

=cut

################################################################################

sub name {
  my $this = shift;

  return $this->prop('name', @_);
}

sub noun {
  my $this = shift;

  return $this->prop('noun', @_);
}

sub version {
  my $this = shift;

  return $this->prop('version', @_);
}

sub frame {
  my $this = shift;

  return $this->prop('frame', @_);
}

sub commands {
  my $this = shift;

  return $this->prop('commands', @_);
}

sub implementation {
  my $this = shift;

  my $imp = $this->prop('implementation', @_);
  return $imp if (defined($imp));

  $imp = ref($this);
  $imp =~ s/.*:://; # remove perl namespace prefix
  $imp =~ s/_IF$//; # remove suffix of module interface package name

  return $imp;
}

################################################################################
################################################################################

=head2 prop

 Purpose: 
    Set or retrieve a property of the AppInterface object
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

1;
