use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moo' };

{
	package Local::Bleh;
	use Moo;
	use Types::Standard -types;
	use Sub::HandlesVia;

	has status => (
		is           => 'ro',
		lazy         => 1,
		isa          => Enum[qw/ pass fail unknown /],
		coerce       => 1,
		builder      => '_build_status',
		handles_via  => 'Enum',
		handles      => {
			is_pass        => 'is_pass',
			is_fail        => 'is_fail',
			is_unknown     => 'is_unknown',
			assign_pass    => 'assign_pass',
			assign_fail    => 'assign_fail',
			assign_unknown => 'assign_unknown',
			is             => 'is',
			assign         => 'assign',
		},
	);
	
	sub _build_status { 'unknown' }
}

my $obj = Local::Bleh->new;

is( $obj->status, 'unknown' );
ok( $obj->is( 'unknown' ) );
ok( $obj->is_unknown );

$obj->assign_pass;
is( $obj->status, 'pass' );
ok( $obj->is( 'pass' ) );
ok( $obj->is_pass );

$obj->assign( 'fail' );
is( $obj->status, 'fail' );
ok( $obj->is( 'fail' ) );
ok( $obj->is_fail );

done_testing;
