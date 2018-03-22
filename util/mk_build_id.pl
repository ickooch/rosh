#!perl

use strict;

use File::Basename;

my $progname = $0;
$progname =~ s/^.*[\\\/]//;

my $my_uid;

if ($^O =~ m/^MSWin/) {
  eval ("use Win32");	
  $my_uid = Win32::LoginName();
} else {
  $my_uid = $ENV{'LOGNAME'} ? $ENV{'LOGNAME'} :
	     ( $ENV{'USER'} ? $ENV{'USER'} :
	       ( $ENV{'USERNAME'} ? $ENV{'USERNAME'} : "Unknown"));
}
$my_uid = lc $my_uid;


my ($bid_file) = shift (@ARGV);
my ($notime) =  shift (@ARGV);
$bid_file = "build_id"
    unless (defined ($bid_file));

#my $bline = get_cspec_var ('baseline');
my $bline = `git branch`;
chomp $bline;

my $bid;
if (defined ($bline) and defined (get_cspec_var ('purpose'))) {
    $bid = $bline;
} else {
    $bid = "*INTERIM*";
}

my $build_date = shorttime (time);
#my $build_view = `cleartool pwv -s -wdview`;
my $build_view = '';
chomp ($build_view);

use POSIX qw(uname);

my (@fqhn) = split (/\./, (uname)[1]);
my $build_host = shift (@fqhn);
my $build_time = time;

open (BT, ">$bid_file");
$bid_file =~ s/\.pm$//;
$bid_file = basename( $bid_file );

my $pkg_txt = <<EOPKG;
package $bid_file;
require Exporter;
\@ISA = qw(Exporter);
\@EXPORT = qw (
	      \$build_id
	      \$build_time
	      );
BEGIN {
    \$build_id = "$bid (built on $build_date by $my_uid on $build_host in view $build_view)";
    \$build_time = $build_time;
}

1;
EOPKG

print BT $pkg_txt;
close BT;

exit 0;

sub get_cspec_var {
    my ($attr) = @_;

    my (%map_attr) = (
		      'project' => "# Project:",
		      'role' => "# Workspace Configuration for Role:",
		      'intbr' => "# Integration Branch:",
		      'wspbr' => "# Workspace Branch:",
		      'baseline' => "# Baseline:",
		      'purpose' => "# Purpose:"
		     );

    unless (defined ($map_attr{$attr})) {
	die "$progname: ERR: attempt to retrieve unknown project attribute $attr.";
	return undef;
    }
    
    my @cspec = split (/\n/, `cleartool catcs`);

    my ($attrpt) = $map_attr{$attr};
    my @cslines = grep (m/^${attrpt}\s+(\S+)$/, @cspec);
    if (scalar (@cslines) == 1) {
	my ($csline) = shift (@cslines);
	$csline =~ m/^${attrpt}\s+(\S+)$/;
        my ($var, $id) = split (/:/, $1);

        return $var;
    }

    return undef;
}

sub shorttime {
    my ($tval, $only_date) = @_;

    my ($min, $hr, $d, $m, $y) = (localtime($tval))[1,2,3,4,5];
    return sprintf ("%02d/%02d/%02d", $y%100, $m+1, $d) if (defined($only_date) and $only_date);
    return sprintf ("%02d/%02d/%02d %02d:%02d", $y%100, $m+1, $d, $hr, $min);
}
