package Globals;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (
	      emitc
	      emitc_short
	      shorttime
	      timecc
              $rosh
              $my_uid
              $opt_help
              $opt_pwd
              $opt_test
              $opt_timer
              $opt_user
              $opt_vers
              $passwd
              $process_id
              $progbuilt
              $progdir
              $progname 
              $progvers
              $restrictions
              $this_host
              &debug
              cctime
              intersect
              subtract
              uniq
             );

use strict;

use vars  qw(
             $rosh
             $build_id
             $my_uid
             $opt_help
             $opt_pwd
             $opt_test
             $opt_timer
             $opt_user
             $opt_vers
             $passwd
             $progbuilt
             $progdir
             $progname 
             $progvers
             $restrictions
             $this_host
            );

BEGIN {
#
# Set some global defaults
#
    use File::Basename;
    $progname = basename ($0, qw(.pl .exe));
    $progvers = "2.0";
    
    eval ("use build_id");
    $progbuilt = $@ ? "Ad-hoc development build." : $build_id;
    
    use POSIX qw(uname);
    $this_host = (uname())[1];
    
    $my_uid = ( $ENV{LOGNAME} ? $ENV{LOGNAME} :
		( $ENV{USER} ? $ENV{USER} :
		  ( $ENV{USERNAME} ? $ENV{USERNAME} :
		    "Unknown")));
    $my_uid = lc $my_uid;
}

sub new {
    return bless ({}, shift);
}

sub md5_crypt {
    my $str = pop (@_);

    use Digest::MD5;
    my $md5 = new Digest::MD5;

    $md5->add ($str);
    return $md5->b64digest;
}

sub shorttime {
    my ($tval, $only_date) = @_;

    my ($min, $hr, $d, $m, $y) = (localtime($tval))[1,2,3,4,5];
    return sprintf ("%02d/%02d/%02d", $y%100, $m+1, $d) if (defined($only_date) and $only_date);
    return sprintf ("%02d/%02d/%02d %02d:%02d", $y%100, $m+1, $d, $hr, $min);
}

# compute a clearcase time constraint string from a timeval ("dd-mmm[-yy[yy]].hh:mm")
sub cctime {
    my ($tval) = shift;

    my @months = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    my ($min, $hr, $d, $m, $y) = (localtime($tval))[1,2,3,4,5];

    return sprintf ("%d-%s-%02d.%02d:%02d", $d, $months[$m], $y%100, $hr, $min);
}

# compute a timeval from a clearcase time constraint string ("dd-mmm[-yy[yy]].hh:mm")
sub timecc {
    my $tstr = shift;

    my %mapmon = qw ( Jan 0 Feb 1 Mar 2 Mrz 2 Apr 3 May 4 Jun 5 Jul 6 Aug 7 Sep 8
		  Oct 9 Okt 9 Nov 10 Dec 11 Dez 11);

    $tstr =~ m/^(\d\d)-(...)-(\d\d)\.(\d\d):(\d\d):\d\d$/;
    my ($day, $mon, $yr, $hr, $min) = ($1, $2, $3, $4, $5);
    return timelocal (0, $min, $hr, $day, $mapmon{$mon}, $yr);

}

#
# compute an epoch-seconds timevalue from a date string in a format
# as produced by "ctime" (thus the subroutine name emitc).
#
sub emitc {
    my (@t) = split (/\s/, shift);

    use Time::Local;
    use Time::localtime;

    my %mapmon = qw ( Jan 0 Feb 1 Mar 2 Mrz 2 Apr 3 May 4 Jun 5 Jul 6 Aug 7 Sep 8
		  Oct 9 Okt 9 Nov 10 Dec 11 Dez 11);

    shift (@t);
    my ($mon, $dom, $hr, $min, $sec, $yr) =
	($mapmon{shift(@t)}, shift (@t), split (/:/, shift (@t)), shift (@t));

    return timelocal ($sec, $min, $hr, $dom, $mon, $yr);
}

#
# compute an epoch-seconds timevalue from a date string in a format mm/dd/yy
# we assume time 22:00:00
#
sub emitc_short {
    my $tstr = shift;
    my $d = "[-/]";

    return 0
	unless (($tstr =~ m.^\d{2,4}${d}\d\d${d}\d{2}$.) or
		($tstr =~ m.^\d{2,4}${d}\d\d${d}\d{4}$.) or
		($tstr =~ m.^\d{2,4}${d}\d\d${d}\d{2}\s\d\d:\d\d.) or
		($tstr =~ m.^\d{2,4}${d}\d\d${d}\d{4}\s\d\d:\d\d.));

    my ($date, $time) = split (/\s+/, $tstr);

    my (@d) = split (/[-\/]/, $date);
    my ($hr, $min) = (22, 0);
    if ($time) {
	($hr, $min) = split (/:/, $time);
    }

    use Time::Local;
    use Time::localtime;

    my ($yr, $mon, $dom,) =
	(shift (@d), shift(@d) - 1,  shift (@d));


    # FIXME: the call to timelocal should be canned in eval...
    return timelocal (0, $min, $hr, $dom, $mon, $yr % 100);
}

################################################################################
#                 A few simple set operation functions                         #
################################################################################

# takes an array reference as argument and returns a reference to
# a sorted array with duplicates removed.
sub uniq {
    my $aref = shift;

    my %uniq;
    grep (do {$uniq{$_} = 1;}, @$aref);

    return [ sort keys %uniq ];
}

sub intersect {
  my ($arr1, $arr2) = @_;
  my %reg;
  my @intersect = ();
  map { $reg{$_} = 1 } @$arr1;
  map { push(@intersect, $_) if (exists($reg{$_})) } @$arr2;

  return \@intersect;
}

sub subtract {
  my ($arr1, $arr2) = @_;
  my %reg;
  my @intersect = ();
  map { $reg{$_} = 1 } @$arr1;
  map { delete($reg{$_}) } @$arr2;

  return [ keys(%reg) ];
}

################################################################################
#                     End of set operation functions                           #
################################################################################

sub debug {
  my $msg = shift (@_);

  # TBD
}

1;
