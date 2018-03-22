package CLI_Dialog;

require Dialog;
@ISA = qw(Dialog);

use Globals;
use File::Temp qw( :mktemp tempfile );
  
use strict;

sub check {
    my ($msg) = pop;

    chomp($msg);
    my (@parts) = split (/:/, $msg);
    my ($msgkind) = shift (@parts);
    my ($msgcont) = join (":", @parts);

    if ($msgkind eq "ERR") {
	print STDERR "$progname: **ERROR - $msgcont\n";
	return 0;
    } elsif ($msgkind =~ m/^(NOT|MSG)$/) {
	print "$progname: $msgcont\n";
	return 1;
    } elsif ($msgkind eq "WNG") {
	print STDERR "$progname: **WARNING - $msgcont\n";
    }
    return 1;
}

sub printout {
  my ($this, $text) = @_;

  print $text;
}

sub prompt_logon {
  my ($this, $prompt) = @_;

  my ($username, $password);
  print "$prompt ";
  $username = <STDIN>;
  chomp($username);
  while (not (defined($password) and $password)) {
    print "Password: ";
    ReadMode('noecho');
    $password = ReadLine(0);
    chomp($password);
    ReadMode(0);
    print "\n";
  }
  return "$username\n$password";
}

sub confirm {
    my ($this, $quest, $default) = @_;

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

sub ask {
    my ($this, $quest, $prop, $rest) = @_;

    my $ans = '';
    
    my ($tmpf) = "$ENV{TEMP}/msgask".time;

    my ($proposal);
    $proposal = $prop ? " ($prop) " : "";

    my ($oldselect) = CORE::select (STDOUT);
    my ($savbuff) = $|;
    $| = 1;
    print "${quest}$proposal";

    $| = $savbuff;
    CORE::select ($oldselect);

    my ($savdel) = $/;
    $/ = "\n";
    if (defined $rest and $rest =~ m/-mult/) {
	print "[Terminate with a single \".\"]\n";
	while (<STDIN>) {
	    last if (m/^\.$/);
	    $ans .= "$_";
	}
    } else {
	$ans = scalar (<STDIN>);
	chomp ($ans);
    }
    if (!$ans && $prop) {
	$ans = $prop;
    }
    $/ = $savdel;

    return $ans;
}

sub get_text {
    my ( $this, $prompt, $prompt2 ) = @_;

    if ( exists $ENV{ 'EDITOR' } ) {
	my ( $tfh, $tmpfile );
	if ( $prompt ) {
	    ( $tfh, $tmpfile ) = tempfile();
	    print $tfh $prompt;
	    close $tfh;
	}
	
	my $sbuf = $|;
	$| = 1;
	print "[Starting editor $ENV{ 'EDITOR' } to harvest text..]";
	$| = $sbuf;
	
	system( $ENV{ 'EDITOR' }, $tmpfile );
	open( $tfh, '<', $tmpfile )
	    or die "** Error: Cannot open temp file $tmpfile: $!\n";
	my $text = join( '', <$tfh> );
	close $tfh;
	unlink $tmpfile;
	return $text;
    }

    # prompt2 is a presumably shorter prompt that - if available -
    # will be used only if no EDITOR is defined.
    if ( $prompt2 ) {
	$prompt = $prompt2;
    }
    my ($oldselect) = CORE::select (STDOUT);
    my ($savbuff) = $|;
    $| = 1;
    print "${prompt} ";

    $| = $savbuff;
    CORE::select ($oldselect);

    my ($savdel) = $/;
    $/ = "\n";

    my $ans = '';
    print "[Terminate with a single \".\"]\n";
    while (<STDIN>) {
	last if (m/^\.$/);
	$ans .= "$_";
    }

    $/ = $savdel;

    return $ans;
}

1;
