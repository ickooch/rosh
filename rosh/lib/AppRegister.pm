package AppRegister;
################################################################################

=head1 package
=head2 AppRegister

 Version: 0.0.1
 Purpose: 
    Provide an object to store entry points for actual function
    routines within a more complex application. 
 Description:     
    The idea is to have a modular application frame that provides one
    or more subcommands that may be invoked through the main
    application. "Modular" means that the subcommands are not
    statically linked with the application but are loaded at run time
    into the base application. The AppRegister object serves as the
    memory which subcommand plugins are loaded, and provides the entry
    points for calling the actual functions.

    Two-Phase Loading:
    In order to avoid a massive startup overhead caused by loading all 
    available modules into the frame, we scan the application libray for
    interface modules first, and load the application implementation only
    when it is actually needed.

 Restrictions: none
 Author: Axel Mahler, ickooch@gmail.com

=head1 Function

=cut

################################################################################

use Tracer;
use base qw(Tracer);

use strict;

# This is to enforce loading of standard modules into the executable
# plugin frame (when built with perlapp)
#

use Getopt::Long qw(:config no_pass_through);
use File::Basename;
use File::Copy;
use File::Path;

use Try::Tiny;

use XML::Simple;
use Digest::SHA1;
use Carp;
use Globals;
use Config;
if ( $Config{ 'osname' } =~ m/Win32/ ) {
    eval( "use Win32::Console::ANSI;");
}
use Term::ANSIColor;
use IO::Handle;

################################################################################
################################################################################

=head2 new

 Purpose: 
    Initialize a new application frame object.
 Parameters: (library => "<path to plugin packages>", prefix => "<optional package prefix for plugins>")
 Return value: ref to application frame object
 Description:
    The new AppRegister object will look something like
    $this = {
              'commands' => {
			     <name> => {
					'name' => <string>,
					'version' => <string>,
					'usage' => <string>,
					'description' => <string>,
					'kind' => <string: "gui"|"cli">,
                                        'implemented_in' => <string: plugin-name>,
					'entry' => <code>,
				       }, 
			     ..
			    },
              'plugins' => {
			    <name> => {
				       'version' => <string>,
                                       'commands' => [ <string>, .. ],
                                       'implementation_module' => <string>,
				      },
			    ..
			   },
              'library' => "<some path>",
              'prefix' => "<package prefix>",
            };
    The object will only be partially initialized by the "new" constructor. In order to fully
    initialize the application, the method "load_interfaces" needs to be called.
 Restrictions:

=cut

################################################################################

sub new {
  my $class = shift;
  my %this = @_;
  $this{'commands'} = {};

  my $this = \%this;

  $this->{ 'plugins' } = {};
  $this->{ 'action_verbs' } = {};
  $this->{ 'nouns' } = {};
  $this->{'sigstack'} = [];
  
  $this->{'prefix'} = ""
    unless (exists($this->{'prefix'}));

  bless($this, $class);
  
  $this->timer_reset;

  $this->set_trace_prefix("AppRegister");
  return $this;
}

################################################################################
################################################################################

sub link_shell {
    my ( $this, $shell ) = @_;

    # set up bi-directional link between application and built-ins
    $this->{'builtins'} = $shell;
    $shell->prop( 'frame', $this );
	
    # The plugin base-url should normally be a proper URL to a trusted server.
    # If it is a local directory, we assume development_mode, which means that
    # no licenses are checked, and plugins are loaded directly from the 
    # development location.
    #
    my $config = $shell->{ 'config' };
    $this->reference_installation( $config->{ 'plugin-base-url' } );
    if ( -d $config->{ 'plugin-base-url' } ) {
	$this->development_mode( 1 );
	$this->library_path( $config->{ 'plugin-base-url' } );
    } else {
	$this->library_path( $config->{ 'plugin-cache-path' } );
    }
    
    return $this;
}

# deprecated
sub builtin {
  my $this = shift;

  return $this->{'builtins'};
}

sub get_builtin {
  my $this = shift;

  return $this->{'builtins'};
}

################################################################################
################################################################################

=head2 library_path

 Purpose: 
    Set or return the path to the plugin module library
 Parameters: [method] - optional <string> path.
 Return value: <string> with current library path 
 Description:
    If a path is passed as argument, it will be associated with the AppRegister
    object as the current plugin library location.
 Restrictions: none

=cut

################################################################################

use FindBin qw( $Bin );
sub library_path {
  my ($this, $path) = @_;

  $this->{'library'} = $path
    if (defined($path));

  #  return $this->{'library'};
  return $FindBin::Bin . '/realms';
}

################################################################################
################################################################################

=head2 development_mode

 Purpose: 
    Set or return the status variable that indicates whether the plugins
    are loaded from a trusted URL, and cached locally, and verified against
    a 'licence' checksum (development_mode == 0), or whether plugins are loaded
    directly from a local development location without any cache maintenance
    or code validation.
 Description:
    If a value is passed as argument, it will be associated with the AppRegister
    object as the status variable.
 Restrictions: none

=cut

################################################################################

sub development_mode {
  my ( $this, $val ) = @_;

  return 1; # plugin module caching disabled
  
  $this->{'development_mode'} = $val
    if (defined($val));

  return $this->{'development_mode'};
}


################################################################################
################################################################################

=head2 dont_disturb

 Purpose: 
    Disable interrupts during critical operations
 Parameters: [method] - 
 Return value: void
 Description:
 Restrictions: does not work on windows

=cut

################################################################################

sub dont_disturb {
  my $this = @_;

  push(@{$this->{'sigstack'}}, $SIG{'INT'});
  $SIG{'INT'} = 'IGNORE';
}

sub allow_interrupts {
  my $this = shift;

  $SIG{'INT'} = (scalar(@{$this->{'sigstack'}}) ? pop(@{$this->{'sigstack'}}) : 'DEFAULT');
}

################################################################################
################################################################################

=head2 link_dialog

 Purpose: 
    Set application specific dialog object. This is used to abstract from CLI vs. GUI
 Parameters: [method] - dialog object
 Return value: self
 Description:
 Restrictions: none

=cut

################################################################################

sub link_dialog {
  my ($this, $dialog) = @_;

  $this->{'dialog'} = $dialog;

  return $this;
}

sub dialog {
  my $this = shift;

  die "$progname **INTERNAL: Request to uninitialized dialog object.\n"
    unless (defined($this->{'dialog'}));

  return $this->{'dialog'};
}
  

################################################################################
################################################################################

=head2 link_cmdparser

 Purpose: 
    Set application specific cmdparser object. This is used to abstract from CLI vs. GUI
 Parameters: [method] - cmdparser object
 Return value: self
 Description:
 Restrictions: none

=cut

################################################################################

sub link_cmdparser {
  my ($this, $cmdparser) = @_;

  $this->{'cmdparser'} = $cmdparser;

  return $this;
}

sub get_cmdparser {
  my $this = shift;

  return
      if ( not exists $this->{'cmdparser'} );

  return $this->{'cmdparser'};
}
  

################################################################################
################################################################################

=head2 set_terminate

 Purpose: 
    Set application specific termination handler. This is used to abstract from CLI vs. GUI
 Parameters: [method] - <code ref> termination_handler
 Return value: self
 Description:
 Restrictions: none

=cut

################################################################################

sub set_terminate {
  my ($this, $delegate) = @_;

  $this->{'terminator'} = $delegate;

  return $this;
}

sub terminate {
  my ($this, $message)= @_;

  unless (defined($this->{'terminator'})) {
    die "** FATAL: $progname has not defined a specific application terminator.\n";
  };
  &{$this->{'terminator'}}($message);
}


sub licence {
  my ($this, $file_to_check) = @_;

  $file_to_check = basename($file_to_check);
  
  my $digest = $this->{'licences'}->{$this->{'prefix'}}->{$file_to_check};
  return ($digest)
    if (defined($digest));

  return "";
}

################################################################################
################################################################################

=head2 register_plugin

 Purpose: 
    Register an application plugin object within the AppRegister object
 Parameters: [method] -- $plugin_object, [$prefix]
                         $plugin_object: ref to AppPlugin
                         $prefix: [optional] application prefix
 Return value: self
 Description:
 Restrictions: none

=cut

################################################################################

sub register_plugin {
  my ( $this, $plugin_obj ) = @_;

  my $plugin_name = $plugin_obj->get_name();

  # this operation is idempotent
  if ( exists $this->{ 'plugins' }->{ $plugin_name } ) {
      if ( $this->{ 'plugins' }->{ $plugin_name } eq $plugin_obj ) {
	  return $this;
      }
  }
  
  $this->{ 'plugins' }->{ $plugin_name } = $plugin_obj;
  foreach my $this_verb ( @{ $plugin_obj->get_verbs() } ) {
      if ( exists $this->{ 'action_verbs' }->{ $this_verb } ) {
	  push( @{ $this->{ 'action_verbs' }->{ $this_verb } }, $plugin_name )
	      unless ( grep { m/^${ plugin_name }$/ } @{ $this->{ 'action_verbs' }->{ $this_verb } } );;
      } else {
	  $this->{ 'action_verbs' }->{ $this_verb } = [ $plugin_name ];
      }
  }
  foreach my $this_noun ( @{ $plugin_obj->get_nouns() } ) {
      if ( exists $this->{ 'nouns' }->{ $this_noun } ) {
	  push( @{ $this->{ 'nouns' }->{ $this_noun } }, $plugin_name )
	      unless ( grep { m/^${ plugin_name }$/ } @{ $this->{ 'nouns' }->{ $this_noun } } );
      } else {
	  $this->{ 'nouns' }->{ $this_noun } = [ $plugin_name ];
      }
  }
  my $cmd_parser = $this->get_cmdparser();
  if ( $cmd_parser ) {
      $cmd_parser->add_verbs( $plugin_obj->get_verbs() );
      $cmd_parser->add_nouns( $plugin_obj->get_nouns() );
  }
  return $this;
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
  $this->{'plugins'}->{$interface_obj->name} = {
						'version' => $interface_obj->version,
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
      }
  }

  return $this;
}

sub get_command_descriptor {
  my ( $this, $command ) = @_;

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

################################################################################
################################################################################

=head2 call_application_command

 Purpose: 
    Make a safe call to an application command. The code for the application command is 
    loaded if necessary.
 Parameters: $command - name of the application subroutine that shall be invoked.
 Return value: a string; <string> will be empty if command completes okay; 
               <string> contains an error message if anything goes wrong.
 Description:
 Restrictions: none

=cut

################################################################################

sub call_application_command {
  my ($this, $cli_parser) = @_;

  my $debug = $this->get_builtin->set( 'debug' );

  my $command_status = ""; # return empty string if okay; error message otherwise

  my $verb = $cli_parser->verb();
  my $noun = $cli_parser->noun();
  my $realm = $cli_parser->get_realm();

  $realm ||= $this->get_current_realm(); # if realm wasn't explicitly requested, use current
  
  my ( $realm_name, $instance ) = split( /\./, $realm );
  $debug && print "** cli_parse got realm $realm\n";
  $debug && print "** trying to get value of variable " . $this->get_current_realm() . '_instance' . "\n";
  
  $instance ||= $this->get_current_instance(); # if instance wasn't explicitly requested 
                                               # use current applicable to current realm
  $debug && print "**   => got $instance\n";
  $realm_name &&= [ $realm_name ];
  $realm_name ||= $this->get_noun_realm( $noun );
  
  my $args = $cli_parser->arguments();

  if ( @{ $realm_name } > 1 ) {
      die "Noun \"$noun\" is non-unique (it is defined in realms " .
	  join( ', ', sort @{ $realm_name } ) . ").
The noun needs to be prefixed with a realm like \"" . 
join( ".$noun, ", sort @{ $realm_name } ) . ".$noun.\n";
  }
  $realm_name = $realm_name->[ 0 ];
  $realm ||= $realm_name;

  $cli_parser->set_realm( $realm );
  my $command = $verb . ' ' . $realm . '.' . $noun;
  $this->builtin->set( 'debug' ) && print "** AppRegister::call_application_command $command " . join(', ', @{ $args } ) . "\n";

  # get command descriptor
  $this->builtin->set( 'debug' ) && print "** AppRegister::call_application_command getting plugin for realm $realm\n";
  my $plugin = $this->get_plugin( $realm );
  my $save_instance;
  $debug && print "** applicable instance is $instance.\n";
  if ( $instance and # $plugin->get_instance() and 
       ( $plugin->get_instance() ne $instance ) ) {
      $save_instance = $plugin->get_instance();
      $plugin->set_instance( $instance )->load();
  }
  my $cmd_desc = $plugin->get_cli_command_descriptor( $noun, $verb );

  # check command syntax
  my @save_argv = @ARGV;
  @ARGV = @{ $args };
  my $options = {};
  my $cmdopts = $cmd_desc->{'options'};
  if ($cmdopts and (ref($cmdopts) eq "ARRAY") and scalar(@$cmdopts)) {
    Getopt::Long::Configure("no_passthrough");
    my $oldwarn = $SIG{__WARN__};
    $SIG{__WARN__} = sub {return};
    unless(eval('Getopt::Long::GetOptions( @$cmdopts )')) {
      my $usage =  $cmd_desc->{'usage'};
      if (ref($usage) eq "CODE") {
	$usage = &{$usage}();
      }
      $SIG{__WARN__} = $oldwarn;
      $usage =~ s/\n(DESCRIPTION|COMMAND_OPTIONS):.*//s;
      $save_instance && $plugin->set_instance( $save_instance )->load();
      return "Invalid arguments to $command.\nUsage: " . ( $this->builtin->set( 'interactive' ) ? '' : "$Globals::progname ") . "$usage";
    }
    $SIG{__WARN__} = $oldwarn;
    Getopt::Long::Configure( 'default' );
  }
  
  @ARGV = @{ $args };
  unless ( defined( $cmd_desc->{ 'entry' } ) and 
      ( ref( $cmd_desc->{ 'entry' } ) eq "CODE" ) ) {
    $command_status = $this->get_plugin( $realm )->load_implementation( $cmd_desc );
  }
  if ($command_status) {
      $save_instance && $plugin->set_instance( $save_instance )->load();
      return $command_status;
  }

  print color('reset');
  my $code;
  if ( $this->builtin->set( $realm_name )->{ 'color' } ) {
      print color(  $this->builtin->set( $realm_name )->{ 'color' } );
  }
  try {
      $code = &{ $cmd_desc->{ "entry" } }( $cmd_desc->{ "implementation" } );
  } catch {
      print "$_\n";
      $code = 1;
  };
  print color('reset');
  STDOUT->flush();
  $save_instance && $plugin->set_instance( $save_instance )->load();

  return $code;
}

sub get_current_realm {
    my $this = shift;

    return $this->get_builtin->get_current_realm();
}

sub get_current_instance {
    my $this = shift;

    $this->get_builtin()->set( 'debug' ) && print "** AppRegister.get_current_instance " . join( ', ', @_ ) . "\n";
    return $this->get_builtin->get_current_instance( @_ );
}

sub get_current_realm_instance {
    my $this = shift;

    return $this->get_builtin->get_current_realm_instance();
}

# Parameters: $name - a search string
# Return: undef if no ldap available or user not found
#         a userdefs hash if a user is found.
#
sub request_service {
    my ( $this, $service, $request, @params ) = @_;

    my $known_realms = $this->get_builtin->get_applications();
    
    if ( not exists $known_realms->{ $service } ) {
	die "** Error: No such service available: $service.\n";
    }

    # make sure the service provider plugin is loaded, if its available
    try {
	$this->register_plugin( 
	    AppPlugin->new(
		'shell' => $this,
		'service' => $service,
		'instance' => '',
	    )
	    );
    } catch {
	chomp $_;
	die "** Error: Could not instantiate service $service: $_.\n";
    };

    my $service_provider = $this->get_plugin( $service );
    my $cmd_desc = $service_provider->get_service_handle( $request );
    my $code;
    try {
	$code = &{ $cmd_desc->{ 'entry' } }( $cmd_desc->{ 'implementation' }, @params );
    } catch {
	chomp $_;
	die "** Error: Service request $request( " . join( ', ', @params ) . " ) failed: $_.";
    };

    return $code;
}

################################################################################
################################################################################

=head2 registered_commands

 Purpose: 
    Return a list of all commands that are currently registered with the AppRegister
 Parameters: [method] - none
 Return value: [ <string> ] - reference to array of (command names) <string>
 Description:
 Restrictions: none

=cut

################################################################################

sub registered_commands {
  my $this = shift;

  return [ sort grep(($this->{'commands'}->{$_}->{'kind'} eq 'cli'), keys(%{$this->{'commands'}})) ];
}

################################################################################
################################################################################

=head2 plugins

 Purpose: 
    Return a list of all available plugins whose interfaces are currently loaded
 Parameters: [method] - none
 Return value: [ <string> ] - reference to array of plugin names <string>
 Description:
 Restrictions: none

=cut

################################################################################

sub plugins {
  my $this = shift;

  return [ sort keys(%{$this->{'plugins'}}) ];
}

sub plugin_version {
  my ($this, $plugin) = @_;

  return $this->{'plugins'}->{$plugin}->{'version'};
}

################################################################################
################################################################################

=head2 command_usage

 Purpose: 
    Return the usage information for the specified command
 Parameters: [method] - command (<string>)
 Return value: <string> - command usage instructions
 Description:
 Restrictions: none

=cut

################################################################################

sub command_usage {
  my ($this, $command) = @_;

  my $matching = [ sort grep { m/${command}/ } keys %{ $this->{'commands'} } ];

  if ( scalar @{ $matching } == 0 ) {
      return undef;
  } elsif ( ( scalar @{ $matching } > 1 ) and not exists $this->{'commands'}->{ $command } ) {
      # return matching list only if $command is no exact match
      return $matching;
  }

  if (ref($this->{'commands'}->{$command}->{'usage'}) eq "CODE") {
    return &{$this->{'commands'}->{$command}->{'usage'}}();
  } else {
    return $this->{'commands'}->{$command}->{'usage'};
  }
}

################################################################################
################################################################################

=head2 command_description

 Purpose: 
    Return the short description for the specified command
 Parameters: [method] - command (<string>)
 Return value: <string> - command description
 Description:
 Restrictions: none

=cut

################################################################################

sub command_description {
  my ($this, $command) = @_;

  return "** ERROR: Undefined command: $command"
    unless (exists($this->{'commands'}->{$command}));

    return $this->{'commands'}->{$command}->{'description'};
}

################################################################################
################################################################################

=head2 command_known

 Purpose: 
    Return boolean indicating whether the given command is known
 Parameters: [method] - command (<string>)
 Return value: <boolean> - command exists
 Description:
 Restrictions: none

=cut

################################################################################

sub command_known {
  my ($this, $command) = @_;

  return  (exists($this->{'commands'}->{$command}));
}

sub action_verb_known {
  my ($this, $verb) = @_;

  return  (exists($this->{'action_verbs'}->{$verb}));
}

sub get_action_verbs { # used for dynamic command help
  my $this = shift;

  return sort keys %{ $this->{'action_verbs'} };
}

sub get_nouns_with_realms { # used for dynamic command help
  my ( $this ) = @_;

  my @plugins = $this->get_plugin();
  if ( @plugins > 1 ) {
      return map { $_ . ' [' . join( ', ', @{ $this->{ 'nouns' }->{ $_ } } ) . ']' } 
         sort keys %{ $this->{'nouns'} };
  }
  return $this->get_nouns();
}

sub get_nouns { # used for dynamic command help
  my ( $this, $noun ) = @_;

  if ( not $noun ) {
      return sort keys %{ $this->{'nouns'} };
  }
  # nouns may be prefixed by an optional realm (application) qualifier to which they apply.
  my @fq_noun = split( /\./, $noun, 2 );
  my ( $realm, $word );
  $word = pop( @fq_noun );
  $realm = shift @fq_noun
      if ( @fq_noun );

  # 'current_realm' is a process variable. If set, it may define
  # a preferred realm in case of noun ambiguities.
  my $current_realm = $this->get_builtin->set( 'current_realm' );
  die "** Error: No such noun, \"$noun\" is unknown.\n"
      if ( not exists $this->{ 'nouns' }->{ $word } );

  my $noun_realms = $this->{ 'nouns' }->{ $word };
  if ( $realm ) {
      if ( not grep { m/^${ realm }$/ } @{ $noun_realms } ) {
	  die "Noun \"$word\" is not recognized in $realm realm 
(but in " . join( ", ", sort @{ $noun_realms } ) . ").\n";
      }
  } elsif ( @{ $noun_realms } == 1 ) {
      $realm = $noun_realms->[ 0 ];
  } elsif ( ( @{ $noun_realms } > 1 ) and $current_realm and
                 grep { $_ eq $current_realm } @{ $noun_realms } ) {
      $realm = $current_realm;
  } else {
      die "Noun \"$noun\" is ambiguous (defined in realms " .
	  join( ', ', sort @{ $noun_realms } ) . ").
The noun needs to be prefixed with a realm like \"" . 
join( ".$noun, ", sort @{ $noun_realms } ) . ".$noun.\n";
  }
  # $noun and $realm properly defined here
  # get applicable plugin
  my $plugin = $this->get_plugin( $realm );

  return $plugin->get_nouns( $word );
}

sub get_noun_realm {
  my ( $this, $noun ) = @_;

  die "** Error: No such noun, \"$noun\" is unknown.\n"
      if ( not exists $this->{ 'nouns' }->{ $noun } );

  # 'current_realm' is a process variable. If set, it may define
  # a preferred realm in case of noun ambiguities.
  my $current_realm = $this->builtin->set( 'current_realm' );
  my $noun_realms = $this->{ 'nouns' }->{ $noun };
  if ( ( @{ $noun_realms } > 1 ) and $current_realm and
       grep { $_ eq $current_realm } @{ $noun_realms } ) {
      return [ $current_realm ];
  }
  return $this->{ 'nouns' }->{ $noun };
}

sub get_plugin {
    my ( $this, $realm ) = @_;

    my $debug = $this->get_builtin->set( 'debug' );

    $debug && print "** AppRegister.get_plugin( $realm ) called from " . join( ', ', caller() ) . "\n";
    return sort keys %{ $this->{ 'plugins' } }
        if ( not defined $realm );

    my ( $plugin_name, $instance ) = split( /\./, $realm );
    $instance ||= $this->get_current_instance( $realm );
    
    if ( not exists $this->{ 'plugins' }->{ $plugin_name } ) { 
	# assert the realm plugin is available and activated
	my $current_realm = $this->get_current_realm(); # save current global setting
	try {
	    $this->builtin->do_chrealm( $plugin_name . '.' . $instance );
	} catch {
	    chomp $_;
	    die "*** FATAL: $_\n";
	};
	$this->builtin->set( 'current_realm', $current_realm ); # restore current global setting
	die "*** FATAL: No such plugin registered: \"$plugin_name\".\n"
	    if ( not exists $this->{ 'plugins' }->{ $plugin_name } );
    } elsif ( $this->{ 'plugins' }->{ $plugin_name }->{ 'instance' } ne $instance ) {
	$this->{ 'plugins' }->{ $plugin_name }->{ 'instance' } = $instance;
    }

    return $this->{ 'plugins' }->{ $plugin_name };
}

sub get_action_objects { # used for dynamic command help
  my ($this, $verb) = @_;

  if ( $this->action_verb_known( $verb ) ) {
      return sort keys %{ $this->{'action_verbs'}->{$verb} };
  }
  return;
}

sub get_object_verbs { # used for dynamic command help
  my ($this, $noun) = @_;

  my $noun_object = $this->get_nouns( $noun );

  return sort keys %{ $noun_object };
}

sub get_resource_objects {
    my $this = shift;

    my $object_map = $this->invert_action_index();

    return sort keys %{ $object_map };
}

sub invert_action_index {
    my $this = shift;

    my $actions_root = $this->{'action_verbs'};
    my %objects;
    foreach my $verb ( $this->get_action_verbs() ) {
	foreach my $object ( keys %{ $actions_root->{ $verb } } ) {
	    $objects{ $object }->{ $verb } = 1;
	}
    }
    foreach my $object ( keys %objects ) {
	$objects{ $object } = [ sort keys %{ $objects{ $object } } ];
    }
    return \%objects;
}

################################################################################
################################################################################

=head2 reference_installation

 Purpose: 
    Return the network location of TheApp reference installation which is
    by definition maintained, safe, and trustworthy.
 Parameters: [method] - [optional] network_path (a <string> containing a UNC pathname)
 Return value: <string> - network_path
 Description:
 Restrictions: none

=cut

################################################################################

sub reference_installation {
  my ($this, $ref_inst) = @_;

  $this->{'reference_installation'} = $ref_inst
    if (defined($ref_inst) and -d $ref_inst);

  return $this->{'reference_installation'};
}

sub reference_installation_base {
  my $this = shift;

  my $base = $this->{'reference_installation'};
  my $tail = '/lib/' . $this->prefix;
  $base =~ s/${tail}$//;

  return $base;
}



1;
