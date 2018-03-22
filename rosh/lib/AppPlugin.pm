package AppPlugin;

################################################################################

=head1 package
=head2 AppPlugin

 Version: 0.0.1
 Purpose: 
    Class to provide plugin application properties.
 Description:     

 Restrictions: none
 Author: Axel Mahler

=head1 Function

=cut

################################################################################

use strict;

use Carp;
use Globals;
use File::Basename;
use File::Copy;
use File::Path;
use Digest::SHA1;
use Data::Dump qw( dump );

use base qw( Tracer );

################################################################################
################################################################################

=head2 new

 Purpose: 

 Parameters: ( shell => AppRegister, service => 'gitlab', instance => 'default'? )
 Return value: ref AppPlugin
 Description:
 Restrictions: none

=cut

################################################################################

sub new {
  my $class = shift;
  my %this = @_;
  $this{'commands'} = {};

  my $this = \%this;

  $this->{'sigstack'} = [];
  
  $this->{'prefix'} = ""
    unless (exists($this->{'prefix'}));

  bless($this, $class);

  $this->get_shell->set_trace_prefix( 'AppPlugin' );
  my @plugins = $this->get_shell->get_plugin();
  my $my_name = $this->get_name();
  $this->debug() && print "** AppPlugin.new $my_name " . $this->get_instance() . "\n";
  if ( grep { $_ =~ m/^${ my_name }$/ } @plugins ) {
      # this application plugin was already created.
      # try to act idempotent
      $this->debug() && print "** AppPlugin.new trying to find existing $my_name plugin\n";
      return $this->get_shell->get_plugin( $my_name )
	  if ( $this->get_shell->get_plugin( $my_name )->get_instance() eq 
	       $this->get_instance() );
  }
  $this->debug() && print "** AppPlugin.new loading.\n";
  $this->load();

  return $this;
}

sub debug {
    my $this = shift;

    return $this->get_shell->get_builtin->set( 'debug' );
}

################################################################################
################################################################################

=head2 load

 Purpose: 
 Parameters: [method] - none
 Return value: ref AppPlugin
 Description:

 Restrictions: none

=cut

################################################################################

sub load {
    my $this = shift;

    $this->debug() && print "** AppPlugin.load called from " . join( ', ', caller() ) . "\n";
    my $builtin = $this->{ 'shell' }->get_builtin();
    my $service = $this->{ 'service' };
    my $app_map = $builtin->get_applications();
    $this->{ 'prefix' } = $app_map->{ $service };
    my $app = $builtin->set( $service );
    $this->{ 'app' } = $app;
    my $app_connector_class = $app->{ 'connector' };
    $this->{ 'app_connector_class' } = $app_connector_class;

    my $instances = $app->{ 'instances' };
    my $instance;
    if ( not ( exists $this->{ 'instance' } and $this->{ 'instance' }) ) {
	$instance = $instances->{ 'defaults' }->{ 'instance' }
	if ( exists $instances->{ 'defaults' }->{ 'instance' } );
    } else {
	$instance = $this->{ 'instance' };
    }

    if ( $instance ) {
	die "Unknown $service instance \"$instance\"." .
	    ( ref $instances ? "\nChoose from:\n  " . join( "\n  ", sort keys %{ $instances } ) : '' ) . "\n"
	    if ( not exists $instances->{ $instance } );
	
	my $instance_desc = $instances->{ $instance };
	$instance_desc->{ 'api' } ||= $instances->{ 'defaults' }->{ 'api' };
	$builtin->set( $service . '_instance', $instance );
	$builtin->set( $service . '_access_token', $instance_desc->{ 'access_token' } );
	$builtin->set( $service . '_url', $instance_desc->{ 'url' } );
	$builtin->set( $service . '_api_version', $instance_desc->{ 'api' } );
	$builtin->set( $service . '_color', $app->{ 'color' } )
	    if ( exists $app->{ 'color' } );
	foreach my $key ( keys %{ $instance_desc } ) {
	    next if ( $key =~ m/^(access_token|url|api)$/ );
	    $builtin->set( $service . '_' . $key, $instance_desc->{ $key } );
	}
    }
    #    eval( "use $app_connector_class;" );
    $this->load_module( $app_connector_class );
    die "** ERROR: Failed to load service connector class $app_connector_class: $@\n"
	if ( $@ );

    $builtin->set( $service . '_connector', 
		   $app_connector_class
		   ->new( $Globals::rosh, 
			  'interactive' => $builtin->set( 'interactive' ) ));
    $builtin->set_special( $service . '_connector' );
    $this->load_interfaces();

    return $this;
}

################################################################################
################################################################################

=head2 load_interfaces

 Purpose: 
    Main (i.e. phase 1) initialization procedure for the plugin frame.
    During phase 1 of the frame initialization, all interfaces of the
    pluggable modules are loaded.
    The idea is to keep a frame application's startup overhead to a
    minimum while providing help, and usage information for all available plugin
    functions.
    The code that actually implements an application function in a pluggable
    module is only loaded when the corresponding command is first invoked.
 Parameters: none
 Return value: none
 Description:
 Restrictions: library path and perl namespace prefix must be set.

=cut

################################################################################

sub load_interfaces {
  my $this = shift;

  my $builtin = $this->get_shell->get_builtin();
  my $prefix = $this->get_prefix();
  my $module_path = $this->get_module_path();

  #print "** AppPlugin.load_interfaces - got module_path $module_path\n";
  # build a list with all module plug-ins that are currently know
  my @modlist;
  if ( $this->get_shell->development_mode() ) {
      @modlist = $this->get_plugin_modules( $prefix );
  } else {
      @modlist = map {
	  exists $this->{'licences'}->{$prefix}->{ $_ }
      }	$this->get_plugin_modules( $prefix );
      $this->bootstrap($module_path, \@modlist);
  }

  my $interface_object;
  my $appname;

  # add path to $applib to our INC path
  unshift (@INC, dirname($module_path));

  my $perl_prefix;
  $perl_prefix = $prefix . "::"
    if ($prefix);

  no strict;
  $this->get_shell->log_msg("*** Now loading the interfaces from $module_path... ***");

  my $plugin_verified;
  my $tries;
  foreach my $thisapp ( map { $_ . '_IF' } @modlist ) {
    $appname = $module_path . '/' . $thisapp . '.pm';

    $this->get_shell->log_msg("*** ... loading application interface $thisapp from $appname ***");

    ##########################################
    ########## Plugin loader here ############
    ##########################################
    if ( not $this->get_shell->development_mode() ) {
	$plugin_verified = 0;
	$tries = 0;
	do {
	    ($plugin_verified = $this->validate_plugin($appname))
		or $this->update_plugin($appname);
	    $tries += 1
		unless ($plugin_verified);
	} until ($plugin_verified or ($tries > 3));
	die "*** FATAL: Failed to licence plugin module " . basename($appname) . ". The module's license is probably out of date!\n"
	    unless ($plugin_verified);
    }
    eval ( "do '$appname'" );

    $this->get_shell->log_msg("*** ... got an error result: $@ -- dying***") if ($@);
    die "*** FATAL: $@\n" if ($@);
    
    #read modul version  
    $thisapp =~ s/\.pm$//;
    eval ('$interface_object = ' . $perl_prefix . $thisapp . '->new($this)');
    
    carp("Could not instantiate interface object for $thisapp: $@")
      if ($@);
    eval ('$interface_object->register($prefix)');
    carp("Could not register interface for $thisapp application: $@")
      if ($@);
  }
  use strict;
}

################################################################################
################################################################################

=head2 load_module

 Purpose: Load a perl module from file, given a module_path, and the module name.
          This is pretty much a self-implemented 'use', but without the otherwise 
          necessary 'use lib' comtext.
 Parameters: name of the module file, with, or without trailing '.pm' suffix.
 Return value: none
 Description:
 Restrictions: 

=cut

################################################################################

sub load_module {
  my ( $this, $modname ) = @_;

  my $builtin = $this->get_shell->get_builtin();
  my $prefix = $this->get_prefix();
  my $module_path = $this->get_module_path();

  my %paths;
  foreach my $p ( @INC ) {
      $paths{ $p } = 1;
  }
  # add path to $applib to our INC path
  unshift (@INC, dirname($module_path))
      if ( not exists $paths{ dirname($module_path) } );

  my $perl_prefix;
  $perl_prefix = $prefix . "::"
    if ($prefix);

  eval ( 'use ' . $perl_prefix . basename( $modname, '.pm' ) . ';' );

  return;
}

sub provided_entries {
    my $this = shift;
    
    print "** AppImplementation::provided_entries:\n  " . join( "\n  ", keys %{ $this->{ 'provided_entries' } } ) . "\n";
}

################################################################################
################################################################################

=head2 load_implementation

 Purpose: 
    Load the implementation part of a plug-in application module.
    All commands implemented by the plugin are loaded.
 Parameters: [method] - $plugin - name of the application plugin that is needed.
 Return value: empty <string> upon success; if <string> is non-empty, it is an 
               error message.
 Description:
    The logic works as follows:
    1. build implementation module file name and load it with 'eval("do")'
    2. instantiate the module implementation object
    3. for all commands defined in the plugin's interface, ask the implementation
       object for the appropriate code reference, and register the code ref in the
       command's "entry" key.
 Restrictions: the plugin's interface must be loaded. It is a fatal error if
    the interface is not loaded, i.e. if the plugin is not known.

=cut

################################################################################

sub load_implementation {
  my ( $this, $cmd_descriptor ) = @_;

  my $builtin = $this->get_shell->get_builtin();
  my $prefix = $this->get_prefix();
  my $module_path = $this->get_module_path();

  # get list of all command entry points implemented in the module
  # that is requested to be loaded
  my $plugin_commands = $this->{ 'modules' }->{ $cmd_descriptor->{ 'implemented_in' } }->{ 'commands' };

  my $interface_object;
  my $appname;

  my $perl_prefix;
  $perl_prefix = $prefix . "::"
    if ($prefix);

  my $imp_module = $cmd_descriptor->{ 'implemented_in' };

  no strict;
  $Globals::rosh->log_msg("*** Now loading implementation module $imp_module ***");

  my $appname = $module_path . '/' . $imp_module . ".pm";

  ##########################################
  ########## Plugin loader here ############
  ##########################################
  my $plugin_verified;
  my $tries;

  $Globals::rosh->log_msg("*** ... validating application implementation from $appname ***");

  if ( not $Globals::rosh->development_mode() ) {
      $plugin_verified = 0;
      $tries = 0;
      do {
	  ($plugin_verified = $this->validate_plugin($appname))
	      or $this->update_plugin($appname);
	  $tries += 1
	      unless ($plugin_verified);
      } until ($plugin_verified or ($tries > 3));
      die "*** FATAL: Failed to licence plugin module " . basename($appname) . ". The module's license is probably out of date!\n"
	  unless ($plugin_verified);
  }
  eval ( "do '$appname'" );

  $Globals::rosh->log_msg("*** ... got an error result when loading module implementation: $@") if ($@);
  return "$@" if ($@);
    
  my $imp_object;
  eval ('$imp_object = new ' . $perl_prefix . $imp_module . '($this)');

  return "Could not instantiate implementation object: $@"
    if ($@);

  foreach my $this_cmd ( @{ $plugin_commands } ) {
      $cmd_descriptor = $this->{ 'commands' }->{ $this_cmd };
      $cmd_descriptor->{'entry'} = $imp_object->coderef($this_cmd);
      $cmd_descriptor->{'version'} = $imp_object->version;
      $cmd_descriptor->{'implementation'} = $imp_object;
  }
  use strict;

  return "";
}

sub get_module_path {
    my $this = shift;

    my @applibs;
    push ( @applibs, $ENV{ 'ROSH_LIBREALM' } )
	if ( exists $ENV{ 'ROSH_LIBREALM' } and -d $ENV{ 'ROSH_LIBREALM' } );
    push ( @applibs, $this->get_shell->library_path() );

    my $prefix = $this->get_prefix();
    
    foreach my $applib ( @applibs ) {
	my $module_path = $applib;
	$module_path .= '/' . $prefix
	    if ($prefix);
	return $module_path
	    if ( -e $module_path );
    }

    return;
}

sub get_plugin_modules {
    my $this = shift;

    my @plugins;
    
    my $module_path = $this->get_module_path();
    #print "** AppPlugin.get_plugin_modules: check module_path = $module_path\n";
    opendir(APPS, $module_path) or
	die "Cannot open application library $module_path: $! \n";
    @plugins = map { $_ =~ s/_IF\.pm//; $_ } 
    grep(m/.+\_IF.pm$/, readdir(APPS));
    closedir(APPS);

    return @plugins;
}
    

sub bootstrap {
  my ($this, $local_libpath, $modules) = @_;

  my $builtin = $this->get_shell->get_builtin();
  my $reference = $this->get_shell->reference_installation();
  if (fs_location_identical($reference, $local_libpath)) {
    $this->{'direct_library'} = 1;
    $this->get_shell->log_msg("*** Skipping bootstrap of plugin library - reference and lib are identical.");
    return;
  }
  $this->{'direct_library'} = 0;
  
  $this->get_shell->log_msg("*** Bootstrapping the plugin library from $reference.");

  unless (-d $local_libpath) {
    $this->get_shell->trace("Creating lib directory $local_libpath");
    unless (mkpath($local_libpath, 0, 0755)) {
      log_error("*** FATAL: Could not create local application libray $local_libpath: $!");
      die "*** FATAL: Could not create local application libray $local_libpath: $!";
    }
  }

  opendir(LIB, $local_libpath)
    or die "** FATAL ERROR: Could not open local plugin library.\n";
  my @installed_perl_files = grep(m/.+\.pm$/, readdir(LIB));
  closedir(LIB);

  $this->get_shell->trace("Checking for cleanlyness of application library..");
  # prepare removal of modules that are no longer licenced
  my (%kill_list, %inst_list);
  map { $kill_list{$_} = 1 } @installed_perl_files;
  map { delete($kill_list{$_}) } @$modules; # these modules are allowed
  my @kill_list = keys(%kill_list);
  if (scalar(@kill_list)) {
    $this->trace("Removing obsolete modules: " . join(", ", @kill_list));
    unlink(map { $local_libpath . '/' . $_ } keys(%kill_list));
  }

  foreach my $this_mod (@$modules) {
    next if ( -e "$local_libpath/$this_mod" );
    next unless ($this->validate_plugin("$reference/$this_mod"));
    $this->get_shell->log_msg("***   $reference/$this_mod -> $local_libpath");
    copy("$reference/$this_mod", "$local_libpath/$this_mod");
  }
  $this->get_shell->log_msg("*** Bootstrap of plugin library complete.");
}


################################################################################
################################################################################

=head2 validate_plugin

 Purpose: 
    Check whether the local copy of the plugin module is up-to-date and pristine
    (i.e. has not been tampered with).
 Parameters: [method] -- $plugin_file
 Return value: boolean - 1 if plugin is valid; 0 otherwise
 Description:
    Take a SHA1 digest checksum of the locally installed plugin file, and 
    compare it against the corresponding checksum that is stored in a manifest
    file on a central server.
 Restrictions: none

=cut

################################################################################

sub validate_plugin {
  my ($this, $plugin_file) = @_;
  
  return 1
    if ( $this->get_shell->development_mode() ); # used for development environment

  my $is_valid = 0;

  my $sha = Digest::SHA1->new;
  
  local *MOD;
  unless (open(MOD, "$plugin_file")) {
    $this->log_error ("** ERROR: Could not read application module $plugin_file");
    return $is_valid;
  }
  binmode(MOD);
  $sha->addfile(*MOD);
  close(MOD);
  my $this_checksum = $sha->b64digest;
  $is_valid = ($this_checksum eq $this->licence($plugin_file));

  return $is_valid;
}

################################################################################
################################################################################

=head2 update_plugin

 Purpose: 
    Copy a plugin module from the remote reference location to the local 
    install directory.
 Parameters: [method] -- $plugin_file
 Return value: void
 Description:
    Copy the named plugin file from the reference location (usually
    //hooks.thekeep.design.ti.com/thekeep/lib/<prefix>) to the local 
    install directory (dirname($plugin_file)).
 Restrictions: none

=cut

################################################################################

sub update_plugin {
  my ($this, $plugin_file) = @_;

  my $ref_install = $this->get_shell->reference_installation();
  my $plugin_leaf = basename($plugin_file);

  $this->get_shell->log_msg("*** Updating plugin $plugin_leaf");

  chmod(0755, $plugin_file);
  copy("$ref_install/$plugin_leaf", $plugin_file);
  chmod(0644, $plugin_file);
}

sub fs_location_identical {
  my ($f1, $f2) = @_;

  return 1
    if ($f1 eq $f2);

  my @st1 = stat($f1);
  my @st2 = stat($f2);

  # check for identity of inode numbers (works only on unix)
  return 1
    if (($st1[1] == $st2[1]) and $st1[1]);

  # make a qualified guess whether both files are identical
  return (($st1[0] == $st2[0]) and
          ($st1[2] == $st2[2]) and
          ($st1[6] == $st2[6]) and
          ($st1[8] == $st2[8]) and
          ($st1[9] == $st2[9]) and
          ($st1[10] == $st2[10]));
}

################################################################################
################################################################################

=head2 register_interface

 Purpose: 
    Register an application interface object within the AppRegister object
 Parameters: [method] -- $interface_object, [$prefix]
                         $interface_object: ref to AppInterface
                         $prefix: [optional] application prefix
 Return value: self
 Description:
 Restrictions: none

=cut

################################################################################

sub register_interface {
  my ($this, $interface_obj, $prefix) = @_;

  my $interface_provided_commands = $interface_obj->commands;
  $this->{ 'modules' }->{ $interface_obj->name() } = {
						'version' => $interface_obj->version(),
						'commands' => [ map {$_->{'name'}} @$interface_provided_commands],
						'plugin_module' => $interface_obj->implementation,
						'prefix' => ($prefix ? $prefix : $this->prefix),
					       };
  map { $this->register_command($_, $interface_obj->name) } @$interface_provided_commands;

  return $this;
}

################################################################################
################################################################################

=head2 register_command

 Purpose: 
    Return reference to a command procedure entry point.
 Parameters: [method] - $cmd_descriptor, $appname,
             $cmd_descriptor as defined in the application interface module.
             The cmd_descriptor is a hash reference that looks as follows.
                   {
		    'name' => "echo",
                    'action_verb' => 'describe', # or [ 'describe', 'desc', <further aliases>.. ] - just sample here
		    'usage' => "echo some arguments to echo...",
		    'description' => "This is a trivial function.",
		    'version' => "1.0.0",
		    'kind' => "cli",
		    'entry' => , # this will be code ref to the actual
                                 # function -- loded in phase2
		   }
             $appname is the logical name of the Application
 Return value: a perl code reference to the procedure's entry point or undef
 Description:
   Add the command defined by $cmd_descriptor to global register of command
   entry points.
   For the new commandline syntax: add the action_verb to the list of 
   known verbs applicable to the current noun (e.g. 'desc branch foobranch'
   where 'branch' is the noun. (This requires that the noun is available in 
   this context!!)
 Restrictions: self

=cut

################################################################################

sub register_command {
  my ($this, $cmd_descriptor, $appname) = @_;
  
  eval('$this->check_command_descriptor($cmd_descriptor)');
  if ($@) {
    carp "Could not install command in application frame: $@\n";
    return $this;
  }

  $this->{'commands'}->{$cmd_descriptor->{'name'}} = 
    {
     'version' => $cmd_descriptor->{'version'},
     'options' => $cmd_descriptor->{'options'},
     'usage' => $cmd_descriptor->{'usage'},
     'description' => $cmd_descriptor->{'description'},
     'category' => ucfirst $cmd_descriptor->{'category'},
     'kind' => $cmd_descriptor->{'kind'},
     'entry' => $cmd_descriptor->{'entry'},
     'implemented_in' => $appname,
    };
  
  # provide alternative lookup path for command descriptor
  if ( $cmd_descriptor->{'verb'} ) {
      my @verbs;
      if ( ref  $cmd_descriptor->{'verb'} eq 'ARRAY' ) {
	  push( @verbs, @{ $cmd_descriptor->{'verb'} } );
      } else {
	  push( @verbs, $cmd_descriptor->{'verb'} );
      }
      foreach my $verb ( @verbs ) {
 	  $this->{'action_verbs'}
	  ->{ $verb }
	  ->{$cmd_descriptor->{'category'}} = 
	      $this->{'commands'}->{$cmd_descriptor->{'name'}};
 	  $this->{'nouns'}
	  ->{ $cmd_descriptor->{ 'category' } }->{ $verb } = $cmd_descriptor;
      }
  }

  return $this;
}

sub get_cli_command_descriptor {
  my ( $this, $noun, $verb ) = @_;

  if ( not ( exists  $this->{'action_verbs'}->{ $verb } and
	     $this->{'action_verbs'}->{ $verb }->{ $noun } ) ) {
      die "* FATAL: Cannot find cli command descriptor for \"$verb $noun\".\n";
  }
  
  return $this->{'action_verbs'}->{ $verb }->{ $noun };
}

sub get_service_command_descriptor {
  my ( $this, $command ) = @_;

  if ( not exists  $this->{'commands'}->{ $command } ) {
      die "* FATAL: Cannot find service command descriptor for \"$command\".\n";
  }
  
  return $this->{'commands'}->{ $command };
}

sub check_command_descriptor {
  my ($this, $cmdesc) = @_;

  foreach my $key ( qw(name) ) {
    defined($cmdesc->{$key}) or
      croak "Invalid command descriptor - required field $key is missing.";
  }
  foreach my $key ( qw(usage description) ) {
    $cmdesc->{$key} ||= "Undocumented command";
  }
  return;
}

sub get_service_handle {
  my ($this, $command) = @_;

  # get command descriptor
  my $cmd_desc = $this->get_service_command_descriptor( $command );
  my $command_status;
  unless (defined($cmd_desc->{'entry'}) and 
      (ref($cmd_desc->{'entry'}) eq "CODE")) {
    $command_status = $this->load_implementation( $cmd_desc );
  }
  return $command_status
    if ($command_status);

  return $cmd_desc;
}

################################################################################
################################################################################

=head2 prefix

 Purpose: 
    Set or return the perl namespace prefix for the plugin modules.
 Parameters: [method] - optional <string>
 Return value: the string to be used as namespace prefix for modules: "package <prefix>::Module".
 Description:
 Restrictions: none

=cut

################################################################################

# deprecated for getting
sub prefix {
  my ($this, $prefix) = @_;

  $this->{'prefix'} = $prefix
    if (defined($prefix));

  return $this->{'prefix'};
}

sub set_prefix {
  my ($this, $prefix) = @_;

  $this->{'prefix'} = $prefix
    if (defined($prefix));

  return $this->{'prefix'};
}

sub get_prefix {
  my $this = shift;

  return $this->{'prefix'};
}

sub get_application_name {
    my $this = shift;

    return $this->{ 'app' }->{ 'name' };
}

################################################################################

=head2 shell

 Purpose: 
    Set or return the central application (singelton) shell 
 Parameters: 
 Return value: 
 Description:
 Restrictions: none

=cut

################################################################################

sub set_shell {
  my ($this, $shell) = @_;

  $this->{'shell'} = $shell
    if (defined($shell));

  return $this->{'shell'};
}

sub get_shell {
  my $this = shift;

  return $this->{'shell'};
}


################################################################################
################################################################################

sub get_name {
  my $this = shift;

  return $this->{'service'};
}

sub get_instance {
  my $this = shift;

  return $this->{'instance'};
}

sub set_instance {
  my ( $this, $instance ) = @_;

  $this->{ 'instance' } = $instance;

  return $this;
}

sub get_commands {
  my $this = shift;

  my $name = $this->get_name();
  
  return [ keys %{ $this->{'commands'} } ];
}

sub get_verbs {
  my $this = shift;

  return [ keys %{ $this->{'action_verbs'} } ];
}

sub get_nouns {
  my ( $this, $noun ) = @_;

  return [ keys %{ $this->{'nouns'} } ]
      if ( not defined $noun );

  return $this->{ 'nouns' }->{ $noun }
      if ( exists $this->{ 'nouns' }->{ $noun } );
  
  die "Noun $noun is not recognized in plugin " . $this->get_name() . ".\n";
}

################################################################################
################################################################################

=head2 load_licences

 Purpose: 
    Load a centrally maintained file with module checksums for all "licensed" (i.e. legal)
    plugin files. These checksums will later be used to verify the validity of plug-in
    modules.
 Parameters: [method] - none
 Return value: <boolean> - 1 if manifest was successfully loaded; 0 otherwise. 
 Description:
    The manifest file is maintained in the reference installation directory.
    A missing manifest file is a fatal error.
 Restrictions: none

=cut

################################################################################

sub load_licences {
  my $this = shift;

  return
      if ( $this->development_mode() );
  
  $this->{'licences'} = XMLin($this->reference_installation . "/licence.xml", NoAttr => 1);
  croak("** FATAL: Could not load plugin licenses from reference location " . $this->reference_installation . "/licence.xml")
    unless (defined($this->{'licences'}->{'__Magic'}));
}

sub is_initialized {
  my $this = shift;

  return defined($this->{'shell'});
}

1;
