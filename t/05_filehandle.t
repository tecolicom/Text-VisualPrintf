use strict;
use warnings;
use utf8;
use Encode;
use open ':std', ':encoding(utf8)';
use Data::Dumper;
use Text::VisualPrintf qw(vprintf vsprintf);

use Test::More;

my $out;

open OUT, ">", \$out or die;
Text::VisualPrintf::printf OUT "%12s\n", "あいうえお";
close OUT;

is( decode('utf8', $out),  "  あいうえお\n", 'filehandle' );

done_testing;
