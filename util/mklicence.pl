#!perl

################################################################################

=head1 mklicence

 Version: 0.0.1
 Purpose: 
    Build an application licence file from a given set of application plugin
    files.
 Description:     
    For the modules of a given application, build a SHA1 checksum and associate
    it with the module's name in hash table.
    The applications passed as parameters are taken as names of directories
    which will be scanned for perl modules. Only perl module pairs of the 
    form <name>_IF.pm - <name>.pm will be considered.
    A separate licence file will be written for each application. The licence
    will be placed in the applicaion directory,  and is named "licence.xml".
 Restrictions: none
 Author: Axel Mahler, ickooch@gmail.com

=head1 Function

=cut

################################################################################

use strict;
BEGIN {
  my $common_packages = "./packages";
  #use unshift to load view modules before locally installed one
  unshift(@INC, $common_packages);
}


my $PROGRAM_ID = "mklicence - Create application licence files V1.0";

use File::Basename;
use Getopt::Long;
use XML::Simple;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use FileHandle;

my $progname = basename($0);

#
# Acquire parameters
#


unless (scalar (@ARGV)) {
  usage ();
  terminate (0);
}

my (
    $opt_applications,
    $opt_help,
   );

GetOptions (
	    'apps=s' => \$opt_applications,	# undocumented - for local tests only
	    'help' => \$opt_help,
	   ) or usage (), terminate (1);

usage (), terminate (0)
  if ($opt_help);

my @application = split(/,/, $opt_applications);

die "** ERROR: Missing parameter --apps.\n"
  unless (scalar(@application));

foreach my $this_app (@application) {
  if (licence_application($this_app)) {
    print "$progname: Built licence file for application $this_app.\n";
  } else {
    print STDERR "** ERROR: Could not build license file for $this_app.\n";
  }
}

print "Done.\n";
exit(0);

sub licence_application {
  my $appname = shift;

  unless (-d $appname) {
    print STDERR "** ERROR: Cannot open application directory $appname.\n";
    return 0;
  }

  opendir(APP, $appname) or
    die "Cannot open application library: $@ \n";

  my @plugins = grep(m/.+\.pm$/, readdir(APP));
  closedir(APP);
  my @app_interfaces =  grep(m/.+_IF\.pm$/, @plugins);
  my @app_implementations = @app_interfaces;
  map { s/_IF\.pm$/.pm/ } @app_implementations;

  my $licence = {
		 '__Magic' => $PROGRAM_ID,
		 $appname => {},
		 };
  my $sha = Digest::SHA1->new;
  
  my $contents;
  local *MOD;
  foreach my $this_mod (@app_interfaces, @app_implementations) {
    $sha->reset;
    unless (open(MOD, "$appname/$this_mod")) {
      print STDERR "** ERROR: Could not read application module $appname/$this_mod\n";
      return 0;
    }
    binmode(MOD);
    $sha->addfile(*MOD);
    close(MOD);
    $licence->{$appname}->{$this_mod} = $sha->b64digest;
  }
  unless (open(XML, ">$appname/licence.xml")) {
    print STDERR "** ERROR: Could not create license file for application $appname\n";
    return 0;
  }
  print XML XMLout($licence, RootName => 'ApplicationLicence', NoAttr => '1');
  close(XML);

  return 1;
}
    

sub usage {
  print STDERR "Usage: perl $0 --apps <application1>,.. [--help]\n";
  
  return;
}

sub terminate {
  my $stat = shift;

  exit ($stat);
}

# THE END
