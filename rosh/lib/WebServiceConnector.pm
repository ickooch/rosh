package WebServiceConnector;
################################################################################

=head1 package
=head2 WebServiceConnector

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

require Logging;
use base qw( Logging );

use Carp qw( croak confess );

################################################################################
################################################################################

sub version {
  my $this = shift;

  return $this->prop('version', @_);
}

sub api_version {
  my $this = shift;

  return $this->{ 'api' };
}

sub frame {
  my $this = shift;

  return $this->prop('frame', @_);
}

sub get_url {
    my $this = shift;

    return $this->prop( 'url', @_ );
}

sub get_auth_header {
    confess 'Virtual method "get_auth_header" called. Override method in derived class.';
}

################################################################################
################################################################################

=head2 prop

 Purpose: 
    Set or retrieve a property of the WebServiceConnector object
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

# sub preference: access process variables (set variables) from builtin 
#                 feature
#
sub preference {
  my ($this, $varname) = @_;

  return $this->frame->builtin->set($varname);
}

1;
