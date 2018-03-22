#!perl -w

use MIME::Base64 qw( decode_base64 encode_base64 );

my $what = shift @ARGV;
my $xwhat = encode_base64( $what );
print "Encode '$what' -> $xwhat\n";
print "  Decode to verify: " . decode_base64( $xwhat ) . "\n";

exit 0;
