use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires { 'Object::Pad' => 0.67 }; }

##############################################################################

use Object::Pad;

class FooBar {
	use Sub::HandlesVia qw(delegations);
	
	has $x :reader = [];
	
	delegations(
		attribute    => '$x',
		handles_via  => 'Array',
		handles      => {
			all_x => 'all',
			add_x => 'push',
		},
	);
}

my $o = FooBar->new;

$o->add_x( 123 );
$o->add_x( 456 );

is_deeply( $o->x, [ 123, 456 ] );

is_deeply( [ $o->all_x ], [ 123, 456 ] );

done_testing;
