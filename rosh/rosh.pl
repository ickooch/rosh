#!perl
#
# Application main program for plugin-extensible Web Server API CLI
#

use strict;

use lib qw( lib );

use AppRegister;
use AppPlugin;
use BuiltIn;
use CLI_Dialog;
use File::Basename;
use File::Copy;
use File::Path;
use Text::ParseWords;
use Getopt::Long qw(:config pass_through require_order);

use CmdParser;
use Try::Tiny;
use Globals;
use Tracer;

my $tracer;

my $home = dirname($0);
$home ||= '.'; 
 
my @args = @ARGV; # keep that for possible later use

# generic $opt_ variables used in this GetOptions call are defined in Globals!
my ( $opt_verbose, $opt_debug, $opt_curl, $opt_lib, $opt_with, $opt_conf );
GetOptions (
    'time|t'       => \$opt_timer,
    'version|vers' => \$opt_vers,
    'help|h|?'     => \$opt_help,
    'conf|c=s'       => \$opt_conf,
    'verbose|v'    => \$opt_verbose,
    'debug|d'      => \$opt_debug,
    'curl'         => \$opt_curl,
    'lib|l=s'        => \$opt_lib,
    'with=s'       => \$opt_with,   # --with jira.stage,gitlab; override/extend setting in yml config file.
           );

if ( $opt_conf && -e $opt_conf ) {
    $ENV{ 'ROSH_HOME' } = dirname( $opt_conf );
    $ENV{ 'ROSH_PREFS_FILE' } = basename( $opt_conf );
} elsif ( $opt_conf ) {
    die "** ERROR: No rosh config file found at \"$opt_conf\".\n";
}

if ( $opt_lib ) {
    die "** Cannot access realm plugin library $opt_lib.\n"
	if ( not -d $opt_lib );
}

if ( exists $ENV{ 'ROSH_LIBREALM' } ) {
    $opt_lib ||= $ENV{ 'ROSH_LIBREALM' };
}

if ( $opt_lib ) {
    $ENV{ 'ROSH_LIBREALM' } = $opt_lib;
    eval( 'use lib ( ' . $opt_lib . ')' );
}

##############

my $builtin = BuiltIn->new();

##############

if ( $opt_verbose ) {
    $builtin->set( 'verbose', 1);
}
if ( $opt_debug ) {
    $builtin->set( 'debug', 1);
}
if ( $opt_curl ) {
    $builtin->set( 'show_curl', 1);
}
my $app_map = $builtin->get_applications();

my $default_app = 'gitlab'; # backwards compatible default

if ( not exists $app_map->{ $default_app } ) {
    $default_app = (keys %{ $app_map })[ 0 ];
}

$opt_with ||= $default_app;

my @required_plugins = split( /,/, $opt_with );

my ( $service, $instance );

# check all required plugins before loading the first one..
foreach my $this_application ( @required_plugins ) {
    ( $service, $instance ) = split( /\./, $this_application ); # selector for the tool service instance

    my $plugin_application;
    if ( exists $app_map->{ $service } ) {
	$plugin_application = $app_map->{ $service };
	$builtin->set( 'current_realm' ) or
	    $builtin->set( 'current_realm', $service );
    } else {
	die "** ERROR: Unknown application interface requested: \"$service\".\n" .
	    "Known applications are: " . join( ", ", keys %{ $app_map } ) . ".\n";
    }
}

##############

# Create global shell object.
# All functionality will be hooked to this central object.
#
$Globals::rosh = AppRegister->new();

##############

# if called in 'single command mode', we start the app timer as early as possible
$Globals::rosh->timer_start
  if ($opt_timer and scalar(@ARGV));

my $dialog = CLI_Dialog->new();
my $interactive = ( @ARGV == 0 );
if ( $interactive ) {
    $builtin->set( 'interactive', 1);
}

$Globals::rosh->set_terminate(\&terminate_application);
$Globals::rosh->link_dialog($dialog);
$Globals::rosh->link_shell( $builtin );

$SIG{'INT'} = \&catch_intr;

################################################################################
################################################################################
#		Start loading the application plugins
################################################################################

foreach my $this_application ( @required_plugins ) {
    ( $service, $instance ) = split( /\./, $this_application );

    $Globals::rosh->register_plugin( 
	AppPlugin->new(
	    'shell' => $Globals::rosh,
	    'service' => $service,
	    'instance' => $instance,
	)
	);
}

################################################################################
################################################################################
#		Start processing commands
################################################################################

my $cmd_status = "";
my $rc = 1;
my $command = shift(@ARGV);

# if a built-in command (help, or version) is run in batch mode, we execute it 
# without connecting to a service.
#
if ($opt_vers) {
  $command = 'version';
} elsif ($opt_help) {
  $command = 'help';
}

$builtin->set('pid', $$);
$builtin->set('version', $builtin->do_version('get'));
$opt_timer && $builtin->set('timer', 'on');

my $cmd_parser = CmdParser->new( 'verbs' => [ $Globals::rosh->get_action_verbs() ],
				 'nouns' => [ $Globals::rosh->get_nouns() ] );

$Globals::rosh->link_cmdparser( $cmd_parser );

# if the command was given on shell command line, we execute it and exit
if ($command) {
  $Globals::rosh->trace("Executing command '$command " . join(' ', @ARGV ) . "' in batch mode.");

  # if $opt_timer was set, the timer was started above. We have to stop it here
  # so that it can be restarted/stopped in 'do_command'.
  $opt_timer && $Globals::rosh->timer_stop;
  try {
      $cmd_parser->parse( join( ' ', $command, @ARGV ));
  } catch {
      die "Invalid command syntax: $_\n";
  };
  $cmd_status = do_command( 'cli_parser' => $cmd_parser, 'batch' => 1 );
  die $cmd_status
    if ($cmd_status);
  exit 0;
}

# if the application was called without any specific subcommand, we enter 
# the command loop.

my $prompt = basename($0, '.pl', '.exe');
$prompt .= ">";
$builtin->set('prompt', $prompt);
my $cmdline;
$Globals::rosh->set_terminate(\&terminate_command);
$Globals::rosh->trace("Entering command loop in interactive mode.");

#print "** Application struct $rosh: " . $Globals::rosh->phash() . "\n";
#print "** Plugins: " . join( "\n  ", keys %{ $Globals::rosh->{ 'plugins' } } ) . "\n";

my $exit_after_command = 0;

my $term;
if ( $interactive ) {
    use Term::ReadLine;
    $term = Term::ReadLine->new( 'about to start reading commands for rosh' );
}

while (1) {
    $command = undef;
    $builtin->set('status', $cmd_status);
    if ( $interactive ) {
	$cmdline = $term->readline( $builtin->set('prompt') . " " );
	$term->addhistory( $cmdline );
    } else {
	$cmdline = <STDIN>;
    }
    $exit_after_command = eof()
	if (not $interactive);
    chomp($cmdline);
    $cmdline =~ s/^\s+//;
    $cmdline =~ s/\s+$//;
    $Globals::rosh->trace("Cmdline: $cmdline");

    @ARGV = parse_line('\s+', 1, $cmdline);
    if ($builtin->known_alias($ARGV[0])) {
	$builtin->set( 'verbose' ) && print "[substitute alias $ARGV[0]]\n";
	$command = shift(@ARGV);
	$cmdline = $builtin->get_alias_command($command);
	my @additional = @ARGV;
	@ARGV = parse_line('\s+', 1, $cmdline);
	push (@ARGV, @additional) if (scalar(@additional));
	$cmdline = join(" ",@ARGV);
	$command = undef;
    } elsif ( $builtin->command_known($ARGV[0]) ) {
	$command = shift(@ARGV);
	$builtin->set( 'verbose' ) && print "[execute built-in command $command]\n";
    }
    if ( not defined $command ) {
	# parse regular command (non-alias, non-builtin)
	try {
	    $cmd_parser->parse( join(' ', @ARGV) );
	    $builtin->set( 'verbose' ) && print "[verb("
		. $cmd_parser->verb() . "), realm(" 
		. $cmd_parser->get_realm() . '), noun('
		. $cmd_parser->noun() . 
		"), args(" . 
		join( ',', @{ $cmd_parser->arguments() }) . ")]\n";
	} catch {
	    print "Invalid command syntax: $_\n";
	    next;
	};
	$builtin->set( 'verb', $cmd_parser->verb() );
	$builtin->set( 'noun', $cmd_parser->noun() );
    }
    # substitute variables 
    if ($cmdline =~ m/\$(\w+)/ and $cmdline !~ m/^alias /) {
	map { $_ = $builtin->set($1) 
		  if ($_ =~ m/^\$(\w+)$/) } @ARGV;
    }
    # 
    $cmd_status = do_command( 'command' => $command, 'cli_parser' => $cmd_parser);
    if ($cmd_status) {
	$rc = $dialog->check("ERR: $cmd_status");
    } else {
	$rc = 1;
    }
    $builtin->set('status', !$rc);
    $exit_after_command && last;
}

$builtin->save_preferences();

exit 0;

################################################################################
############## E N D  O F  M A I N  P R O G R A M ##############################
################################################################################

sub catch_intr {
  $Globals::rosh->dialog->confirm('** Caught INT signal - really terminate csc?', 'n') or 
    exit(0);
  return;
}

sub do_command {
  my %args = @_;

  my $command = $args{ 'command' };
  my $is_batch = exists $args{ 'batch' };
  my $cli_parser = $args{ 'cli_parser' };
  
  # handle built-in commands; they do not follow the '<verb> <object> <arguments>' syntax
  if ( $command ) {
      if ( $command eq "plugins") {
	  my $plugins = $Globals::rosh->plugins;
	  print "$progname: available plugins:\n";
	  foreach my $this_plugin (@$plugins) {
	      print "  $this_plugin (" . $Globals::rosh->plugin_version($this_plugin) . ")\n";
	  }
      } elsif ($builtin->command_known($command)) {
	  return $builtin->command_run($command, $is_batch);
      } else {
	  print "** ERROR: No such command \"$command\".\n"
	      if ($command);
      }
      return 0;
  }
  if ( $cli_parser->ready() ) {
    #####################################
    # THIS is the main command dispatch #
    #####################################
    $Globals::rosh->timer_start;
    my $ret;
    try {
	$ret = $Globals::rosh->call_application_command($cli_parser, $is_batch);
    } catch {
	print "* Error: $_\n";
    };
    $Globals::rosh->timer_stop;
    if ($builtin->set('timer') eq 'on') {
      my $command_time;
      $command_time = $Globals::rosh->timer_get;

      # reset timers for next round
      $Globals::rosh->timer_reset;
      print "** real:  $command_time->[1]sec\n";
      $command = $cli_parser->verb() . ' ' . $cli_parser->noun();
      $Globals::rosh->log_msg("time $command (r:$command_time->[1]s)");
    }
    return $ret;
  }
  return 0;
}

sub checkupdate {
  my ($term, $base) = @_;

  $Globals::rosh->trace("Checking for update utility in $term..");
  my $local_base = dirname($home);
  if ((not -e "$local_base/$term") or ((stat("$local_base/$term"))[9] < (stat("$base/$term"))[9])) {
    mkpath(dirname("$local_base/$term"), 0, 0755)
      unless (-d dirname("$local_base/$term"));
    $Globals::rosh->trace("Installing update utility from $base/$term to $local_base/$term..");
    copy("$base/$term", "$local_base/$term");
  }
}

sub terminate_application {
  my $msg = shift;

  chomp($msg);
  $builtin->save_preferences();
  exit(!$dialog->check($msg));
}

sub terminate_command {
  my $msg = shift;

  chomp($msg);
  die $msg . "\n";
}

