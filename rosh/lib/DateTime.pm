package DateTime;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (
	      shorttime
              str_to_tval
	      cqtime
              utc_cqtime
              cctime
              utc_cctime
              lbtime
              utc_lbtime
	      timecq
              is_utc
              use_utc
              use_localtime
              get_default_format
              is_valid_format
              normalize_format
             );

use strict;

use Time::Local;

my $use_utc;
BEGIN {
  $use_utc = 0;  # default is localtime 
}

sub get_default_format {
  my ($param) = @_;
  
  if (!$param or $param eq 'datetime') {
    return 'yyyy-mm-dd.hh:mm:ss';
  }elsif ($param eq 'date') {
    return 'yyyy-mm-dd';
  }
}

sub is_valid_format {
  my ($val) = @_;
  
  $val = normalize_format($val);
  return ($val =~ m/^Illegal/) ? 0 : 1;
}

sub normalize_format {
  my ($val, $param) = @_;
  
  $val =~ s/"//g;#remove encapsulating quotes
  $val =~ s/\//-/g;#e.g convert 2005/09/08 to 2005-09-08

  # we normalize the estimated date to a long-format cq date string.
  # if no time was given, we assume 12:00:00. 
  my ($cq1, $cq2, $cc1, $cc2) = (
                                 '^(\d\d\d\d)-(\d\d)-(\d\d)[\. ](\d\d):(\d\d):(\d\d)$', #2005-09-15.12:35:12 - yyyy-mm-dd.hh:mm:ss
                                 '^(\d\d\d\d)-(\d\d)-(\d\d)$',                      #2005-09-15          - yyyy-mm-dd
                                 '^(\d\d)-(...)-(\d{2,4})\.(\d\d):(\d\d):\d\d$',     #01-Sep-05.12:35:00  - dd-mon-yy.hh:mm:ss/dd-mon-yyyy.hh:mm:ss
                                 '^(\d\d)-(...)-(\d{2,4})$',                        #01-Sep-05           - dd-mon-yy/dd-mon-yyyy
                                );
  my $deftime;
  $deftime = ' 12:00:00' if (!$param or $param eq 'datetime');
  
  if ($val =~ m/${cq1}/) {
    # do nothing
    $val =~ s/\./ /g;#replace the concatination item between date and time by space, e.g. 2005-09-08 12:35:00 to 2005-09-08.12:35:00
  } elsif ($val =~ m/${cq2}/) {
    $val .=  $deftime;
  } elsif ($val =~ m/${cc1}/) {
    $val = cqtime(timecc($val));
  } elsif ($val =~ m/${cc2}/) {
      $val = cqtime(timecc($val . $deftime));
  } else {
    return "Illegal date format used in estimated completion time.\n";
  }
  return $val;
}
  
sub use_utc {
  $use_utc = 1;
}

sub use_localtime {
  $use_utc = 0;
}

sub is_utc {
  return $use_utc;
}

sub utc_cqtime {
  my $tval = shift;

  my $was_utc = DateTime::is_utc();
  DateTime::use_utc();
  my $cqdate = DateTime::cqtime($tval);
  DateTime::use_localtime()
      unless($was_utc);

  return $cqdate;
}

sub utc_lbtime {
  my $tval = shift;

  my $was_utc = DateTime::is_utc();
  DateTime::use_utc();
  my $lbdate = DateTime::lbtime($tval);
  DateTime::use_localtime()
      unless($was_utc);

  return $lbdate;
}

sub timesource {
  if ($use_utc) {
    return CORE::gmtime(shift);
  } else {
    return CORE::localtime(shift);
  }
}

sub shorttime {
    my ($tval, $only_date) = @_;

    $tval ||= time;

    my ($min, $hr, $d, $m, $y) = (timesource($tval))[1,2,3,4,5];
    return sprintf ("%02d/%02d/%02d", $y%100, $m+1, $d) if (defined($only_date) and $only_date);
    return sprintf ("%02d/%02d/%02d %02d:%02d", $y%100, $m+1, $d, $hr, $min);
}

# compute a clearcase time constraint string from a timeval ("dd-mmm[-yy[yy]].hh:mm")
sub cctime {
    my ($tval) = shift;

    my @months = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    my ($sec, $min, $hr, $d, $m, $y) = (timesource($tval))[0..5];

    return sprintf ("%d-%s-%02d.%02d:%02d:%02d", $d, $months[$m], $y%100, $hr, $min, $sec);
}

# compute a clearcase time constraint string in UTC format from a timeval ("dd-mmm[-yy[yy]].hh:mmUTC")
sub utc_cctime {
    my ($tval) = shift;

    my @months = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    my $was_utc = DateTime::is_utc();
    DateTime::use_utc();
    my ($sec, $min, $hr, $d, $m, $y) = (timesource($tval))[0..5];
    DateTime::use_localtime()
      unless($was_utc);

    return sprintf ("%d-%s-%02d.%02d:%02d:%02dUTC", $d, $months[$m], $y%100, $hr, $min);
}


# CQ datetime: 2004-11-01 12:00:00

# compute a clearquest time constraint string from a timeval ("yyyy-mm-dd hh:mm:ss")
sub cqtime {
    my ($tval) = shift;

    my @months = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    my ($sec, $min, $hr, $d, $m, $y) = (timesource($tval))[0,1,2,3,4,5];

    return sprintf ("%04d-%02d-%02d %02d:%02d:%02d", $y+1900, $m+1, $d, $hr, $min, $sec);
}

# Label datetime: 20051007_120010

# compute a time string suitabel for use in a label from a timeval ("yyyymmdd_hhmmss")
sub lbtime {
    my ($tval) = shift;
    
    $tval ||= time;

    my @months = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    my ($sec, $min, $hr, $d, $m, $y) = (timesource($tval))[0,1,2,3,4,5];

    return sprintf ("%04d%02d%02d_%02d%02d%02d", $y+1900, $m+1, $d, $hr, $min, $sec);
}

# check for valid time format
sub str_to_tval {
  my $tstr = shift;

  my $formats = [ 
                 ['^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$', \&timecq], 
                 ['^(\d\d)-(...)-(\d\d)\.(\d\d):(\d\d):\d\d$', \&timecc],
                ];
  my ($fmt, $func, $tval);
  foreach my $tconv (@$formats) {
    ($fmt, $func) = @$tconv;
    if ($tstr =~ m/${fmt}/) {
      eval ('$tval = &{$func}($tstr)');
      return undef
        if ($@);
      return $tval;
    }
  }
  return undef;
}

# compute a timeval from a clearquest date-time value string ("yyyy-mm-dd hh:mm:ss")
sub timecq {
    my $tstr = shift;

    $tstr =~ m/^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;

    return undef 
      unless (defined($1) && defined($2) && defined($3) && defined($4) && defined($5) && defined($6));

    my ($yr, $mon, $day, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    return timelocal ($sec, $min, $hr, $day, $mon-1, $yr);

}

# compute a timeval from a clearcase time constraint string ("dd-mmm[-yy[yy]].hh:mm")
sub timecc {
    my $tstr = shift;

    my %mapmon = qw ( Jan 0 Feb 1 Mar 2 Mrz 2 Apr 3 May 4 Jun 5 Jul 6 Aug 7 Sep 8
		  Oct 9 Okt 9 Nov 10 Dec 11 Dez 11);

    $tstr =~ m/^(\d\d)-(...)-(\d\d)\.(\d\d):(\d\d):(\d\d)$/;
    my ($day, $mon, $yr, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    return timelocal ($sec, $min, $hr, $day, $mapmon{$mon}, $yr);

}

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

1;
