#!perl -w

use strict;

use HTML::Template;
use YAML::XS;
use Getopt::Long;
use File::Basename;
use Data::Dump qw( dump );

#
# This is a simple main script to generate a modular application CLI based
# on plugin templates.
#
# Usage: perl mkapplication.pl [ --clobber|-f ] [ --help|-h ] <commands-spec>.yml
#

my ( $yml_fn, $yml_fd, $yml, $app_spec, $module_specs );
my ( $opt_clobber, $opt_noclobber, $opt_only_interfaces, 
     $opt_plugin, $opt_plugin_path, $opt_increment, $opt_help );


GetOptions (
    'help|h' => \$opt_help,
    'clobber|f' => \$opt_clobber,
    'noclobber=s' => \$opt_noclobber,
    'plugin=s' => \$opt_plugin,
    'plugin-path=s' => \$opt_plugin_path,
    'increment|update|u' => \$opt_increment,
    'if-only' => \$opt_only_interfaces,
    );

my $noclobber_re;
if ( $opt_noclobber ) {
    $noclobber_re = '^(' . join('|', split(',', $opt_noclobber ) ) . ')';
}

$yml_fn = shift @ARGV;

open( $yml_fd, '<', $yml_fn )
    or die "Cannot open YML input file $yml_fn: $!\n";

$yml = join( '', <$yml_fd> );
close( $yml_fd );

$opt_plugin_path ||= $ENV{ 'ROSH_PLUGIN_PATH' };
$opt_plugin_path ||= '../rosh/realms';

# YAML file contains a sequence of module definitions.
#    Sample:
#    ---
#    Branches:
#      commands:
#      - cardinality: many
#        endpoint: /projects/:project-id/repository/branches
#        name: ls*
#        options:
#        - &opt-help
#          switchspec: help
#          varname: help
#        - &opt-long
#          switchspec: long|l
#          varname: long
#        - &opt-short
#          switchspec: short|s
#          varname: short
#        - &opt-project
#          switchspec: project|p=s
#          varname: project
#        - &opt-project-id
#          switchspec: in=i
#          varname: project_id
#        request_type: GET
#        verb: list
#      - cardinality: single
#        endpoint: /projects/:project-id/repository/branches/:branch-id
#        name: desc*
#        options:
#        - *opt-help
#        - *opt-long
#        - *opt-short
#        - *opt-project
#        - *opt-project-id
#        request_type: GET
#        verb: describe
#      kind: resource
#      noun: branch
#      suffix: br
#        

( $app_spec, $module_specs ) =  Load( $yml );

if ( not exists $app_spec->{ 'Application' } or 
     not defined  $app_spec->{ 'Application' }->{ 'name' } ) {
    die "Invalid application specification. Header information (name, prefix) missing.\n";
}
my $APPLICATION = $opt_plugin_path . '/' . $app_spec->{ 'Application' }->{ 'name' };
my $SERVICE = $app_spec->{ 'Application' }->{ 'service' };
my $APP_PREFIX = $app_spec->{ 'Application' }->{ 'prefix' };

my $base = 'lib';
my $mod_if_tmpl_fn = 'Mod_IF.pm.tmpl';
my $mod_impl_tmpl_fn = 'Mod.pm.tmpl';

my $mod_if_tmpl = HTML::Template->new( 'filename' => $base . '/' . $mod_if_tmpl_fn, 'die_on_bad_params' => 0, 'global_vars' => 1 );
my $mod_impl_tmpl = HTML::Template->new( 'filename' => $base . '/' . $mod_impl_tmpl_fn, 'die_on_bad_params' => 0, 'global_vars' => 1 );

# determine which plugins to build
my @plugins;
if ( not $opt_increment ) {
    if ( $opt_plugin ) {
	my $plugin_re = '^(' . join( '|', split( ',', $opt_plugin )) . ')';
	@plugins = sort grep { m/${ plugin_re }/ } keys %{ $module_specs };
	confirm( "Building the following $APPLICATION plugin modules:\n  " . join( "\n  ", @plugins ) .
		 "\nExisting interface " . ( $opt_only_interfaces ? '' : 'and implementation ' ) . "files will be overwritten. Ok?", 'yes' )
	or die "Nothing generated.\n";
	$opt_clobber = 1;
    } else {
	@plugins = sort grep { not /DUMMY/ } keys %{ $module_specs };
	confirm( "Building the following $APPLICATION plugin modules:\n  " . join( "\n  ", @plugins ) .
		 "\nExisting interface " . ( $opt_only_interfaces ? '' : 'and implementation ' ) . "files will " . ( defined $opt_clobber ? '' : 'not ' ) . "be overwritten. Ok?", 'yes' )
	    or die "Nothing generated.\n";
    }
} else {
    my $plugin_re = '^(' . join( '|', split( ',', $opt_plugin )) . ')';
    @plugins = sort grep { m/${ plugin_re }/ } keys %{ $module_specs };
}

if ( not -d "$APPLICATION" ) {
    mkdir $APPLICATION, '022';
}

foreach my $mod ( @plugins ) {
    next
	if ( $mod =~ m/DUMMY/ );
    
    my $mod_path1 = $APPLICATION . '/' . $mod . '_IF.pm';
    my $mod_path2 = $APPLICATION . '/' . $mod . '.pm';

    if ( $opt_increment ) {
	$mod_path1 .= '.gen';
	$mod_path2 .= '.gen';
	print "** Update module $mod interface and implementation to:\n  => $mod_path1\n  => $mod_path2\n";
    } else {
	if ( not $opt_only_interfaces ) {
	    if ( -e $mod_path2 and not $opt_clobber ) {
		warn "** Will not overwrite existing module $mod_path1 or $mod_path2\n";
		next;
	    }
	    if ( -e $mod_path2 and $opt_noclobber and ( $mod =~ m/${noclobber_re}/i ) ) {
		warn "** Will not overwrite existing module $mod_path1 or $mod_path2 (noclobber)\n";
		next;
	    }
	    
	    next
		if ( not exists $module_specs->{ $mod }->{ 'kind' } );
	} else {
	    warn "(Re-)Generating only plugin interfaces.\n";
	}
    }
    $mod_if_tmpl->clear_params();
    $mod_impl_tmpl->clear_params();
    $mod_if_tmpl->param( 
	'application' => basename( $APPLICATION ),
	'application_prefix' => $APP_PREFIX,
	'plugin' => $mod,
	);
    $mod_impl_tmpl->param( 
	'application' => basename( $APPLICATION ),
	'service_connector' => $SERVICE,
	'application_prefix' => $APP_PREFIX,
	'plugin' => $mod,
	);
    my $params = $module_specs->{ $mod };
    my $suff = $params->{ 'suffix' };
    foreach my $cmd ( @{ $params->{ 'commands' } } ) {
	$cmd->{ 'name' } =~ s/\*/$suff/;
	my $key = { 
	    'GET' => 'rest_get_single',
	    'POST' => 'rest_post',
	    'PUT' => 'rest_put',
	    'DELETE' => 'rest_delete'
	}->{ $cmd->{ 'request_type' } };
	if (( $key eq 'rest_get_single' ) and 
	    ( $cmd->{ 'cardinality' } eq 'many' )) {
	    $key = 'rest_get_list';
	}
	if ( exists $cmd->{ 'verb' } ) {
	    $cmd->{ 'primary-verb' } = ( split( /\s*,\s*/, $cmd->{ 'verb' } ) )[0];
	    $cmd->{ 'verb' } = '[ \'' . join('\', \'', split( /\s*,\s*/, $cmd->{ 'verb' } ) ) . '\' ]';
	    $cmd->{ 'kind' } = 'cli';
	} else {
	    $cmd->{ 'kind' } = 'service';
	}
        $cmd->{ $key } = 1;
	# set switch indicating whether the command requires a subject argument on the command line
	# e.g. the "descbranch" command requires a branch argument (which is not set as an option)!
	if ( { 'rest_get_single' => 1,
	       'rest_put' => 1,
	       'rest_delete' => 1 }->{ $key } ) {
	    $cmd->{ 'require_subject' } = 1;
	} 
	if ( { 'rest_post' => 1,
	       'rest_put' => 1 }->{ $key } ) {
	    $cmd->{ 'require_params' } = 1;
	}
	if ( $cmd->{ 'kind' } eq 'cli' ) {
	    foreach my $this_opt ( map { $_->{ 'varname' } } @{ $cmd->{ 'options' } } ) {
		next
		    if ( not defined $this_opt );
		$cmd->{ 'opt-' . $this_opt } = 1;
	    }
	    if ( exists $cmd->{ 'required' } ) {
		my @require_opts = map { $_ =~ s/-/_/; $_ } split(/\s*,\s*/, $cmd->{ 'required' });
		$cmd->{ 'required' } = [ map { { 'opt' => '$' . $_  } } @require_opts ];
	    }
	}
    }
    # print "*** Params = $params: " . dump( $params->{ 'commands' }->[ 0 ]->{ 'options' } ) . "\n";
    $mod_if_tmpl->param( $params );
    $mod_impl_tmpl->param( $params );

    my $mod_fh;
    
    if ( not open( $mod_fh, '>', $mod_path1 ) ) {
	die "Cannot create $mod_path1: $!\n";
    }
    print $mod_fh $mod_if_tmpl->output();
    close $mod_fh;

    next
	if ( $opt_only_interfaces );
    
    if ( not open( $mod_fh, '>', $mod_path2 ) ) {
	die "Cannot create $mod_path2: $!\n";
    }
    print $mod_fh $mod_impl_tmpl->output();
    close $mod_fh;

}

sub confirm {
    my ( $quest, $default) = @_;

    my $def = $default ? " [$default]" : "";

    my $oldselect = select(STDOUT);
    my $savbuff = $|;
    $| = 1;
    print "$quest (yes|no)$def ";
    $| = $savbuff;
    select ($oldselect);

    my ($savdel) = $/;
    $/ = "\n";
    my $answer = lc scalar(<STDIN>);
    $/ = $savdel;
    $answer =~ s/\s*//g;
    $answer ||= $default;

    return ("yes" =~ m/${answer}/i);
}

####

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
