use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Counter;

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Optional Int Any Item Defined Num );

our @METHODS = qw( set inc dec );

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type == Any or $type == Item or $type == Defined ) {
		return {
			trust_mutated => 'always',
		};
	}
	if ($type==Num or $type==Int) {
		return {
			trust_mutated => 'maybe',
			value_type    => $type,
		};
	}
	return {
		trust_mutated => 'never',
	};
}

sub set {
	handler
		name      => 'Counter:set',
		args      => 1,
		signature => [Int],
		template  => '« $ARG »',
}

sub inc {
	handler
		name      => 'Counter:inc',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		template  => '« $GET + (#ARG ? $ARG : 1) »',
		lvalue_template => '$GET += (#ARG ? $ARG : 1)',
}

sub dec {
	handler
		name      => 'Counter:dec',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		template  => '« $GET - (#ARG ? $ARG : 1) »',
		lvalue_template => '$GET -= (#ARG ? $ARG : 1)',
}

sub reset {
	handler
		name      => 'Counter:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 0 },
}

1;