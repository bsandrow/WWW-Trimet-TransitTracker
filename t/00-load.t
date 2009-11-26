#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Trimet::TransitTracker' );
}

diag( "Testing WWW::Trimet::TransitTracker $WWW::Trimet::TransitTracker::VERSION, Perl $], $^X" );
