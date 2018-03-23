package BuiltIn;

use strict;

use File::Basename;
use Globals;
use Cwd;
use YAML;
use Try::Tiny;
use Data::Dump qw( dump );
use Tracer;

sub new {
  my $class = shift;
  my %this = @_;

  my $this = \%this;

  $this->{'commands'} = {
                             'set' => {'desc' => "Display or set option(s) for subsequent commands.",
                                       'usage' => "set [ <name> = <string> ]",
                                       'entry' => \&do_set},
                             'unset' => {'desc' => "Unset option for subsequent commands.",
                                         'usage' => "unset <name>",
                                         'entry' => \&do_unset},
                             'alias' => {'desc' => "Display or set command aliases.",
                                       'usage' => "alias [ <name> = <command> ]",
                                       'entry' => \&do_alias},
                             'unalias' => {'desc' => "Unset command aliases.",
                                         'usage' => "unset <name>",
                                         'entry' => \&do_unalias},
                             'setenv' => {'desc' => "Display or set environment variable.",
                                          'usage' => "setenv [ <name>=<string> ]",
                                          'entry' => \&do_setenv},
                             'unsetenv' => {'desc' => "Unset environment variable.",
                                            'usage' => "unsetenv <name>",
                                            'entry' => \&do_unsetenv},
                             'version' => {'desc' => "Show version information.",
                                           'usage' => "version",
                                           'entry' => \&do_version},
                             'verbs' => {'desc' => "List known action verbs.",
                                           'usage' => "verbs [ noun ]",
                                           'entry' => \&do_verbs},
                             'verb' => {'desc' => "List known action verbs.",
                                           'usage' => "verb [ noun ]",
                                           'entry' => \&do_verbs},
                             'noun' => {'desc' => "List known resource objects.",
                                           'usage' => "noun [ noun ]",
                                           'entry' => \&do_nouns},
                             'nouns' => {'desc' => "List known resource objects.",
                                           'usage' => "noun [ noun ]",
                                           'entry' => \&do_nouns},
                             'plugins' => {'desc' => "List known plugins and their load status.",
                                           'usage' => "plugins",
                                           'entry' => \&do_plugins},
                             'realms' => {'desc' => "List known plugins and their load status.",
                                           'usage' => "realms",
                                           'entry' => \&do_plugins},
                             'prealm' => {'desc' => "Print current default realm.",
                                           'usage' => "prealm",
                                           'entry' => \&do_prealm},
                             'realm' => {'desc' => "Print current default realm.",
                                           'usage' => "realm",
                                           'entry' => \&do_prealm},
                             'chrealm' => {'desc' => "Change default realm.",
                                           'usage' => "chrealm <realm>",
                                           'entry' => \&do_chrealm},
                             'chapp' => {'desc' => "Change default application.",
                                           'usage' => "chapp <realm>",
                                           'entry' => \&do_chrealm},
                             'help' => {'desc' => "Show general usage information, and available subcommands.",
                                           'usage' => "help",
                                           'entry' => \&do_help},
                             'cd' => {'desc' => "Change directory.",
                                      'usage' => "cd <path>",
                                      'entry' => \&do_chdir},
                             'pushd' => {'desc' => "Change directory and save previous directory on internal stack.",
                                      'usage' => "pushd <path>",
                                      'entry' => \&do_pushdir},
                             'popd' => {'desc' => "Change directory to previous directory stored on internal stack.",
                                      'usage' => "popd",
                                      'entry' => \&do_popdir},
                             'pwd' => {'desc' => "Print current working directory.",
                                       'usage' => "pwd",
                                       'entry' => \&do_pwd},
                             'exit' => {'desc' => "Exit from $progname.",
                                        'usage' => "exit",
                                        'entry' => \&do_exit},
                             'quit' => {'usage' => "Alias to \"exit\"",
                                        'type' => 'alias',
                                        'entry' => \&do_exit},
                             'bye' => {'usage' => "Alias to \"exit\"",
                                       'type' => 'alias',
                                        'entry' => \&do_exit},
                             'sh' => {'desc' => "Execute a command in external shell.",
                                      'usage' => "sh <command..>",
                                      'entry' => \&do_shell},
                            };
  $this->{'variables'} = {
      'current_realm' => '',
                         };

  # note: "tracefile" is both, special, and read-only. More precisely, it is a 
  #       set-only variable (special for "set" and "ro" for unset)
  $this->{'ro_variables'} = [ qw (
                                  user
                                  tracefile
                                  current_realm
                                  version
                                  pid
                                  \?
                                  ) ];

  $this->{'special_variables'} = [ qw (
                                       debug
                                       timer
                                       tracefile
                                       trace_prefix
                                      ) ];
  $this->{'alias_variables'} = {};

  bless($this, $class);
        
  $this->load_preferences();
  $this->load_aliases();
  
  return $this;
}

sub get_default_realm {
  my $this = shift;

  my $config = $this->{ 'config' };
  if ( exists $config->{ 'default-realm' } ) {
    return $config->{ 'default-realm' };
  }
  return 'gitlab'; # legacy static default
}

sub link_application {
    my ( $this, $app ) = @_;

    $this->{ 'frame' } = $app;
    
    $this->{'frame'}->{'builtins'} = $this
	if ( exists $this->{'frame'} );

    # The plugin base-url should normally be a proper URL to a trusted server.
    # If it is a local directory, we assume development_mode, which means that
    # no licenses are checked, and plugins are loaded directly from the 
    # development location.
    #
    my $config = $this->{ 'config' };
    $this->frame->reference_installation( $config->{ 'plugin-base-url' } );
    if ( -d $config->{ 'plugin-base-url' } ) {
	$this->frame->development_mode( 1 );
	$this->frame->library_path( $config->{ 'plugin-base-url' } );
    } else {
	$this->frame->library_path( $config->{ 'plugin-cache-path' } );
    }
    
    return $this;
}

################################################################################
################ M A N A G E M E N T  C O M M A N D S ##########################
################################################################################

sub command_known {
  my ($this, $cmd) = @_;

  return exists($this->{'commands'}->{$cmd});
}

sub known_alias {
  my ($this, $cmd) = @_;

  return exists($this->{'alias_variables'}->{$cmd});
}

sub get_alias_command {
  my ($this, $cmd) = @_;

  return $this->{'alias_variables'}->{$cmd};
}

sub command_usage {
  my ($this, $cmd) = @_;

  return $this->{'commands'}->{$cmd}->{'usage'}
    if (exists($this->{'commands'}->{$cmd}));

  my @matching = sort grep { m/${cmd}/ } keys %{ $this->{'commands'} } ;
  
  scalar @matching && 
      return \@matching;

  return;
}

sub command_description {
  my ($this, $cmd) = @_;

  return $this->{'commands'}->{$cmd}->{'desc'}
    if (exists($this->{'commands'}->{$cmd}));
}

sub registered_commands {
  my $this = shift;

  return [ grep (!($this->{'commands'}->{$_}->{'type'} eq 'alias'), keys(%{$this->{'commands'}})) ];
}

sub get_command_descriptor {
  my ( $this, $command ) = @_;

  return $this->{'commands'}->{ $command };
}

sub command_run {
  my ($this, $cmd, $is_batch) = @_;

  return &{$this->{'commands'}->{$cmd}->{'entry'}}($this, $is_batch);
}

sub print {
  my $this = shift;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->frame->dialog->printout(@_);

  return $this;
}
  
sub log_error {
  my ($this, $msg) = @_;

  my $class = ref($this);
  unless (defined($this->frame)) {
    die "** FATAL: $class implementation doesn't link to the application frame.\n";
  }
  $this->frame->dialog->check("ERR:$msg");

  return $this;
}

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

sub set {
  my ($this, $var, $value) = @_;
  $this->{'variables'}->{$var} = $value
    if (defined($value));

  return $this->{'variables'}->{$var};
}

sub save_preferences {
  my $this = shift;

  my $ro_pattern = '^(' . join('|', @{$this->{'ro_variables'}}, @{$this->{'special_variables'}}) . ')$';
  my $ro_regexp = qr/$ro_pattern/;

  # Currently unimplemented - map to YML

  return $this;
}

sub get_current_realm {
    my $this = shift;

    return $this->set( 'current_realm' );
}

sub get_current_instance {
    my ( $this, $realm ) = @_;

    return $this->set( ( defined $realm ? $realm : $this->get_current_realm() ) . '_instance' );
}

sub get_current_realm_instance {
    my $this = shift;

    return $this->get_current_realm() . '.' . $this->get_current_instance();
}

sub load_preferences {
  my $this = shift;

  my $ro_pattern = '^(' . join('|', @{$this->{'ro_variables'}}, @{$this->{'special_variables'}}) . ')$';
  my $ro_regexp = qr/$ro_pattern/;

  my $prefs_path = get_prefs_path();
  my ( $config, $prefs );
  try {
      ( $config, $prefs ) = YAML::LoadFile( $prefs_path );
  } catch {
      die "** ERROR: Failed to load preferences: $_.\n";
  };
  if ( not defined $config->{ 'config' } ) {
      die "Preferences file ($prefs_path) does not define a proper config section.\n" . dump( $config ) . "\n";
  }
  $config = $config->{ 'config' };
  if ( not defined $config->{ 'plugin-base-url' } ) {
      die "Preferences file ($prefs_path) does not define a plugin-path.\n" . dump( $config ) . "\n";
  }
  $this->{ 'config' } = $config;
  map {
      $this->{ 'variables' }->{ $_ } = $prefs->{ $_ }
      unless ( $_ =~ $ro_regexp )
  } keys( %{ $prefs } );
  
  return $this;
}

sub load_aliases {
  my $this = shift;

  # TBD - use YAML
  
  return $this;
}

sub get_applications {
    my $this = shift;

    my $vars = $this->{ 'variables' };
    my %apps;
    foreach my $v ( keys %{ $vars } ) {
	if (( ref $vars->{ $v } eq 'HASH' ) and exists $vars->{ $v }->{ 'name' } ) {
	    $apps{ $v } =  $vars->{ $v }->{ 'name' };
	    $apps{ $v } .= 'CLI'
		unless ( $apps{ $v } =~ m/CLI$/ );
	}
    }
    return \%apps;
}

sub get_home_dir {
    if ( exists $ENV{ 'ROSH_HOME' } ) {
	return $ENV{ 'ROSH_HOME' };
    } elsif ( exists $ENV{ 'HOME' } and ( -e $ENV{ 'HOME' } . '/.rosh_preferences' 
	                                  or -e $ENV{ 'HOME' } . '/.rosh_conf' ) ) {
	return $ENV{ 'HOME' };
    } elsif ( exists $ENV{ 'HOMEDRIVE' } ) {
	my $h = $ENV{ 'HOMEDRIVE' } . '\\' . $ENV{ 'HOMEPATH' };
	$h =~ s/\\/\//g;
	return $h;
    } elsif ( -d '/etc/rosh.d' ) {
	return '/etc/rosh.d';
    } elsif ( -d '/opt/rosh/data' ) {
	return '/opt/rosh/data';
    } else {
	die 'Cannot determine home directory.' . "\n";
    }
    return;
}

sub get_preferences_file_name {
    if ( exists $ENV{ 'ROSH_PREFS_FILE' } ) {
	return $ENV{ 'ROSH_PREFS_FILE' };
    } else {
	foreach my $n ( qw ( .rosh_preferences rosh_preferences rosh.conf rosh.config ) ) {
	    my $pn = get_home_dir() . '/' . $n;
	    if ( -e $pn ) {
		return $n;
	    }
	}
    }
    return '.rosh_preferences';
}

sub get_prefs_path {
    return get_home_dir() . '/' . get_preferences_file_name();
}

################################################################################
################################################################################

=head2 frame

 Purpose:
    Set or retrieve the application frame object that uses BuiltIn object
 Parameters: none
 Return value: frame object
 Description:
 Restrictions:

=cut

################################################################################

sub frame {
  my $this = shift;

  return $this->prop('frame', @_);
}

################################################################################
############### T H E  B U I L T I N  C O M M A N D S ##########################
################################################################################

sub do_set {
  my $this = shift;
  
  my $state = 0;

  if (scalar(@ARGV)) {
    my ($var, $eq) = (shift(@ARGV), shift(@ARGV));
    if (defined($eq)) {
      # set the variable
      unless ($eq eq "=") {
        $this->log_error("Syntax error. Usage: " . $this->{'commands'}->{'set'}->{'usage'});
        return 1;
      }
      my $val = join(" ", @ARGV);
      unless ($val) {
        $this->log_error("Syntax error. Usage: " . $this->{'commands'}->{'set'}->{'usage'});
        return 1;
      }
      my $special_pattern = '^(' . join('|', @{$this->{'special_variables'}}) . ')$';
      if ($var =~ m/${special_pattern}/) {
        $this->set_special($var, $val);
        return 0;
      } 
      my $ro_pattern = '^(' . join('|', @{$this->{'ro_variables'}}) . ')$';
      if ($var =~ m/${ro_pattern}/) {
        $this->log_error("Variable \"$var\" cannot be changed.");
        return 1;
      } else {
        $this->set($var, $val);
      }
    } else {
      # read the variable
      if (scalar(@ARGV)) {
        $this->log_error("Syntax error. Usage: " . $this->{'commands'}->{'set'}->{'usage'});
        return 1;
      }
      # allow regexp to search for variables
      if ( not exists $this->{'variables'}->{$var} ) {
	  my @match_vars = grep { m/${ var }/ } keys %{ $this->{'variables'} };
	  if ( @match_vars ) {
	      $this->print( "Unknown variable $var but maybe you look for:\n  " .
			    join( "\n  ", @match_vars ) . "\n" );
	  } else {
	      $this->print( "Unknown variable $var.\n" );
	  }
      } else {
	  $this->print($this->{'variables'}->{$var} . "\n");
      }
    }
  } else {
      # show all the settings
      foreach my $var ( sort keys(%{$this->{'variables'}}) ) {
	  next
	      if ( $this->is_special_var( $var ) );
	  my $val = $this->{ 'variables' }->{ $var };
	  $this->print( "$var = " );
	  if ( ref $val ) {
	      $this->print( dump( $val ) );
	  } else {
	      $this->print( $val );
	  }
	  $this->print( "\n" );
      }
#      $this->print(join("\n", map { "$_ = " . ( (ref $this->{'variables'}->{$_}) ? 
#						dump( $this->{'variables'}->{$_} ) : 
#						$this->{'variables'}->{$_} 
#					) } sort keys(%{$this->{'variables'}})) . "\n")
#	  if (scalar(keys(%{$this->{'variables'}})));
  }
  return $state;
}

sub set_special {
  my ($this, $var, $val) = @_;
  
  if ($var eq 'debug') {
    $this->set('debug', 'on');
    $this->set('tracefile', $this->frame->trace_file());
    $this->set('trace_prefix', $this->frame->trace_prefix());
    $this->frame->trace_on();
  } elsif ($var eq 'timer') {
    $this->set('timer', 'on');
    $this->frame->timer_reset;
  } elsif ($var eq 'trace_prefix') {
    $this->set('trace_prefix', $val);
    $this->frame->set_trace_prefix($val);
  } elsif ($var eq 'tracefile') {
    if ((-w $val) or (-w dirname($val))) {
      $this->set('tracefile', $val);
      $this->frame->set_trace_file($val);
    } else {
      $this->log_error("Could not create log file $val.");
    }      
  }
  $this->{ 'special_vars' }->{ $var } = 1;
  
  return $this;
}

sub is_special_var {
  my ( $this, $var ) = @_;
    
  return exists $this->{ 'special_vars' }->{ $var };
}
      
sub do_unset {
  my $this = shift;
  
  my $state = 0;

  my $ro_pattern = '^(' . join('|', @{$this->{'ro_variables'}}) . ')$';
  my @ro = grep(m/${ro_pattern}/, @ARGV);
  if (scalar(@ro)) {
    $this->log_error("Variable " . join(", ", @ro) . " cannot be changed.");
    return 1;
  }
  my $special_pattern = '^(' . join('|', @{$this->{'special_variables'}}) . ')$';
  my @special = grep(m/${special_pattern}/, @ARGV);
  if (scalar(@special)) {
    $this->unset_special(@ARGV);
    return 0;
  }

  map { delete($this->{'variables'}->{$_}) } @ARGV;

  return $state;
}

sub unset_special {
  my ($this, $var) = @_;

  if ($var eq 'debug') {
    delete($this->{'variables'}->{$var});
    $this->frame->trace_off();
    delete($this->{'variables'}->{'tracefile'});
    delete($this->{'variables'}->{'trace_prefix'});
  } elsif ($var eq 'timer') {
    $this->{'variables'}->{$var} = 'off';
  }
}

sub do_alias {
  my $this = shift;

  my $state = 0;
  if (($ARGV[0] =~ m/^(alias|unalias)$/i and scalar(@ARGV) > 1) or 
      $ARGV[0] =~ m/^(alias|unalias)(=.*)$/i)  {
    $this->log_error("Error. $1 command are prohibited to overwrite!");
    return 1;
  }

  my ($var, @rest) = split(/=/, shift(@ARGV));
  @rest = (join("=", @rest)) if (scalar(@rest));
  if (scalar(@ARGV)) {
    shift (@ARGV) if ($ARGV[0] =~ /^=$/);# if the user use 'alias key = val' we get the '=' as a seperate item
    $ARGV[0] =~ s/^=//;# if the user use 'alias key =val' we get '=val' as value, remove leading '='
    push (@rest, @ARGV);
  }

    
  if ($var and scalar(@rest)) {
    # set an alias
    #
    # TBD - use yaml
    #
    $this->load_aliases();#refresh actual aliases
  } elsif ($var) {
    # show specific alias
      $this->print("alias " . $var . " = '" . $this->{'alias_variables'}->{$var} . "'\n") if (defined($this->{'alias_variables'}->{$var}));
  } else {
    # show all aliases
    map {
      $this->print("alias " . $_ . " = '" . $this->{'alias_variables'}->{$_} . "'\n");
    } (sort {lc($a) cmp lc($b)} keys(%{$this->{'alias_variables'}}));
  }
  return $state;
}

sub do_unalias {
  my $this = shift;
  
  my $state = 0;
  if (scalar(@ARGV) > 1) {
    $this->log_error("Syntax error. Usage: " . $this->{'commands'}->{'unalias'}->{'usage'});
    return 1;
  } elsif (scalar(@ARGV) == 1) {
    #
    # TBD - use yaml
    $this->load_aliases();#refresh actual aliases
  } else {
    $this->log_error("No alias '$ARGV[0]' defined!");
    return 0;
  }
  
  return $state;
}
    
sub do_setenv {
  my $this = shift;
  
  my $state = 0;

  if (scalar(@ARGV)) {
    unless (scalar(@ARGV) == 1) {
      $this->log_error("Syntax error. Usage: " . $this->{'commands'}->{'setenv'}->{'usage'});
      return 1;
    }
    
    my ($var, $val) = split(/=/, shift(@ARGV));
    if (defined($val)) {
      # set the variable
      $ENV{$var} = $val;
    } else {
      $this->print($ENV{$var} . "\n");
    }
  } else {
    # show all the settings
    $this->print(join("\n", map { "$_ = " . $ENV{$_} } keys(%ENV)) . "\n");
  }

  return $state;
}

sub do_unsetenv {
  my $this = shift;
  
  my $state = 0;

  map { delete($ENV{$_}) } @ARGV;

  return $state;
}

sub do_version {
  my ($this, $get) = @_;

  my $vers = "**UNDEFINED**";

  use build_id;
  $vers = $build_id
    unless ($@);

  if ($get) {
    return $vers;
  } else {
    $this->print($vers . "\n");
  }
  return 0;
}

sub do_verbs {
    my ( $this, $verb ) = @_;

    if ( not $verb and @ARGV ) {
	$verb = shift @ARGV;
    }

    if ( $verb ) {
	$this->print( "Action verb $verb applicable to following objects:\n  " );
	$this->print( join( "\n  ", $Globals::rosh->get_action_objects( $verb ) ) . "\n" );
    } else {
	$this->print( "Known action verbs:\n  " );
	my @verbs;
	foreach my $v ( $Globals::rosh->get_action_verbs( ) ) {
	    if ( ref $v eq 'ARRAY' ) {
		push( @verbs, @{ $v } );
	    } else {
		push( @verbs, $v );
	    }
	}
	$this->print( join( "\n  ", sort @verbs ) . "\n" );
    }
    return 0;
}

sub do_nouns {
    my ( $this, $noun ) = @_;

    if ( not $noun and @ARGV ) {
	$noun = shift @ARGV;
    }

    if ( $noun ) {
	my @verbs;
	try {
	    foreach my $v ( $Globals::rosh->get_object_verbs( $noun ) ) {
		push( @verbs, $v );
	    }
	    $this->print( "Resource object $noun responds to following action verbs:\n  " );
	    $this->print( join( "\n  ", sort @verbs ) . "\n" );
	} catch {
	    $this->print( "** Error: $_\n" );
	};
    } else {
	$this->print( "Available resource objects:\n  " );
	$this->print( join( "\n  ", $Globals::rosh->get_nouns_with_realms( ) ) . "\n" );
    }
    return 0;
}

sub do_plugins {
    my $this = shift;

    my @loaded_plugins = $this->frame->get_plugin();
    my $known_realms = $this->get_applications();
    my %realms = %{ $known_realms };
    
    foreach my $k ( keys %{ $known_realms } ) {
	$known_realms->{ $k } = 0;
    }
    foreach my $p ( @loaded_plugins ) {
	my $realm =  $this->frame->get_plugin( $p );
	my $connector = $this->set( $p . '_connector' );
	$known_realms->{ $p } = $realm->get_application_name() . '@' . $connector->{ 'url' };
    }
    my $current_realm = $this->set( 'current_realm' );
    $this->print( "Known application realms:\n" );
    foreach ( sort keys %{ $known_realms } ) {
	if ( $_ eq $current_realm ) {
	    print '* ';
	} else {
	    print '  ';
	}
	print $_ . ( $known_realms->{ $_ } ? ' [loaded, ' . $known_realms->{ $_ } . ']' : '') . "\n";
    }
    return 0;
}

sub do_help {
  my ($this, $is_batch) = @_;

  my $about_command = shift(@ARGV);
  my $about_object;
  if ( @ARGV ) {
      $about_object = shift(@ARGV);
  }
  chomp $about_command;
  chomp $about_object;
  my ( $usage, $usage1, $usage_filter_re );
  $usage_filter_re = '.*'; # possibly replaced with a real filter, below
  if (defined($about_command)) {
    $usage = $this->command_usage($about_command);
    if ($usage and not ref $usage ) {
      $this->print($usage . "\n");
      return 0;
    }
    
    $usage1 = $Globals::rosh->command_usage($about_command);
    if ( ref $usage1 ) {
	if ( ref $usage ) {
	    push( @{ $usage }, @{ $usage1 } ); # concat both ref'ed arrays
	} else {
	    $usage = $usage1;
	}
    } elsif ( $usage1 ) {
	if ( ref $usage ) {
	    push( @{ $usage }, $about_command ); # matches in builtin + exact match in app
	} else {
	    $usage = $usage1; # $usage should be undefined because otherwise there were 2 conflicting exact matches
	}
    }
    if ( ref $usage eq 'ARRAY' ) {
	$usage_filter_re = '(' . join( '|', @{ $usage } ) . ')';
    } else {
	$usage && $this->print("USAGE: perl $progname " . $usage . "\n");
	$usage || $this->print('** ERROR: Unknwon command: ' . $about_command . "\n");
	return 0;
    }
  }
  my $commands = $Globals::rosh->registered_commands;
  my $builtin_commands = $this->registered_commands;
  my @all_cmd = sort @$commands, @$builtin_commands;
  if ($is_batch) {
      $this->print("Usage: " . $this->usage('get') . "\nSUBCOMMANDS:\n");
  } else {
      $this->print("$progname: " . ( ref $usage ? 'matching' : 'available' ) . " subcommands:\n");
  }
  #
  # sectionize the overview list by categories
  #
  my %all_commands;
  foreach my $this_cmd ( grep { $_ =~ m/${usage_filter_re}/ } @{ $commands } ) {
      my $cmdesc = $Globals::rosh->get_command_descriptor( $this_cmd );
      $all_commands{ $cmdesc->{ 'category' } } ||= [];
      push( @{ $all_commands{ $cmdesc->{ 'category' } } }, $this_cmd );
  }
  foreach my $this_cmd ( grep { $_ =~ m/${usage_filter_re}/ } @{ $builtin_commands } ) {
      $all_commands{ 'Builtin commands' } ||= [];
      push( @{ $all_commands{ 'Builtin commands' } }, $this_cmd );
  }
  my $desc;

  foreach my $this_category ( sort keys %all_commands ) {
      $this->print("\n           $this_category\n\n");
      foreach my $this_cmd (sort @{ $all_commands{ $this_category } } ) {
	  if ($Globals::rosh->command_known($this_cmd)) {
	      $usage = $Globals::rosh->command_usage( $this_cmd );
	      $usage = ( split( "\n", $usage ) )[0]; # consider only first line
	      if ( length( $usage ) > 29 ) {
		  $usage = substr( $usage, 0, 25 ) . ' ...';
	      }
	      $desc = $Globals::rosh->command_description( $this_cmd );
	      $usage .= (" " x (29 - length($usage)));
	      $this->print("  $usage - $desc\n");
	  }
	  if ($this->command_known($this_cmd)) {
	      $usage = $this->command_usage($this_cmd);
	      $desc = $this->command_description($this_cmd);
	      $usage .= (" " x (29 - length($usage)));
	      $this->print("  $usage - $desc\n");
	  }
      }
  }
  
  return 0;
}

sub usage {
  my ($this, $get) = @_;

  my $usage =  "$progname [SUBCOMMAND] [COMMAND-OPTIONS]

Modus Operandi 

This is \"TheTool\", a command line interface to TheApp.
TheTool can be used in batch- or interactive mode. In batch mode, the tool
executes a single subcommand, and exits. In interactive mode, it continues
to read commands from standard input until the user types the \"exit\" command.

TheTool provides numerous subcommands that are described separately. To find
out which subcommands are available run the \"help\" subcommand.
Run \"help <subcommand>\" to find out more about the specifics of the 
particular subcommand.

COMMAND-OPTIONS:
    -h, --help      display this help and exit.
    -v, --version   print version identification for $progname.

";
  if ($get) {
    return $usage;
  } else {
    $this->print($usage . "\n");
  }
  return 0;
}

sub do_chdir {
  my $this = shift;
  
  my $state = 0;

  my $dir = shift(@ARGV);
  unless ( -d $dir ) {
    $this->log_error("cd: $dir: No such file or directory\n");
    return 1;
  }
  chdir($dir);

  return $state;
}

sub do_chrealm {
  my ( $this, $realm ) = @_;
  
  my $state = 0;

  #print '** Called chrealm . ' . join( ', ', caller() ) . "\n";
  my $die_on_error = 0;
  if ( $realm ) {
      # if realm comes in as parameter, do_chrealm is called as a regular
      # subroutine.
      # if realm comes via @ARGV, do_chrealm is called as a command
      $die_on_error = 1;
  } else {
      $realm = shift @ARGV;
  }
  my ( $service, $instance ) = split( /\./, $realm );
  my $curr_realm = $this->get_current_realm();

  my @loaded_plugins = $this->frame->get_plugin();
  my $known_realms = $this->get_applications();
  
  unless ( exists $known_realms->{ $service } ) {
      my $err_msg = "chrealm: $realm: No such realm or application.\n";
      $die_on_error && die $err_msg;

      $this->log_error( $err_msg );
      return 1;
  }
  my $realm_vars = $this->set( $service );
  if ( $instance ) {
      if ( not exists $realm_vars->{ 'instances' }->{ $instance } ) {
	  my $err_msg = "chrealm: $realm: No such $service instance: $instance.\n";
	  $die_on_error && die $err_msg;

	  $this->log_error( $err_msg );
	  return 1;
      }
  }
  try {
      $Globals::rosh->register_plugin( 
	  AppPlugin->new(
	      'shell' => $Globals::rosh,
	      'service' => $service,
	      'instance' => $instance,
	  )
	  );
      $this->set( 'current_realm', $service );
  } catch {
      chomp $_;
      $this->log_error( "Cannot change realm to $realm: $_\n" );
  };
  
  return $state;
}

sub do_pushdir {
  my $this = shift;
  
  my $state = 0;

  my $dir = shift(@ARGV);
  unless ( -d $dir ) {
    $this->log_error("cd: $dir: No such file or directory\n");
    return 1;
  }
  push(@{$this->{'dirstack'}}, cwd());
  chdir($dir);

  return $state;
}

sub do_popdir {
  my $this = shift;
  
  my $state = 0;

  my $dir = pop(@{$this->{'dirstack'}});
  return 1
    unless (defined($dir));
    
  unless ( -d $dir ) {
    $this->log_error("cd: $dir: No such file or directory\n");
    return 1;
  }
  chdir($dir);

  return $state;
}

sub do_prealm {
  my $this = shift;
  
  my $state = 0;

  $this->print( $this->get_current_realm_instance() . "\n");

  return $state;
}

sub do_pwd {
  my $this = shift;
  
  my $state = 0;

  $this->print(cwd() . "\n");

  return $state;
}

sub do_exit {
  my $this = shift;
  
  my $state = 0;

  $this->save_preferences();

  exit($state);
}

sub do_shell {
  my $this = shift;
  
  my $state = 0;

  $state = int(system(join(' ', @ARGV))/256);

  return $state;
}

1;
