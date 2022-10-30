use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires { 'Object::Pad' => 0.67 }; }

##############################################################################

use Object::Pad;

class FooBar {
	has $x :reader = [];
	use Sub::HandlesVia::Declare '$x', Array => (
		all_x => 'all',
		add_x => 'push',
	);

	has @y;
	use Sub::HandlesVia::Declare '@y', (
		all_y => 'all',
		add_y => 'push',
	);
	
	has %z;
	use Sub::HandlesVia::Declare '%z', (
		all_z => 'all',
		add_z => 'set',
	);
}

my $o = FooBar->new;

$o->add_x( 123 );
$o->add_x( 456 );
is_deeply( $o->x, [ 123, 456 ] );
is_deeply( [ $o->all_x ], [ 123, 456 ] );

$o->add_y( 123 );
$o->add_y( 456 );
is_deeply( [ $o->all_y ], [ 123, 456 ] );

$o->add_z( foo => 123 );
$o->add_z( bar => 456 );
is_deeply( { $o->all_z }, { bar => 456, foo => 123 } );

done_testing;
