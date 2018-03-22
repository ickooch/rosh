#!perl -w

use MIME::Base64 qw( decode_base64 encode_base64 );

my $what = shift @ARGV;
my $xwhat = decode_base64( $what );
print "Decode '$what' -> $xwhat\n";
print "  Encode to verify: " . encode_base64( $xwhat ) . "\n";

exit 0;
