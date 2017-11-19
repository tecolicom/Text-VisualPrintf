use strict;
use warnings;
use utf8;
use Text::VisualPrintf;

use Test::More tests => 6;

is( Text::VisualPrintf::sprintf( "%5s", '%s'),     '   %s', '%s in %s' );
is( Text::VisualPrintf::sprintf( "%5s", '$^X'),    '  $^X', 'VAR' );
is( Text::VisualPrintf::sprintf( "%5s", '@ARGV'),  '@ARGV', 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "\001\001", "日本語", "\001\002" ),
    "(\001\001, 日本語, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "日本語", "\001\001", "\001\002" ),
    "(日本語, \001\001, \001\002)", 'ARRAY' );

TODO: {
    local $TODO = "Unavoidable error.";
    is( Text::VisualPrintf::sprintf( "\001\001(%s, %s, %s)",
				     "壱", "日本語", "\001\002" ),
	"\001\001(壱, 日本語, \001\002)", 'ARRAY' );
}

done_testing;
