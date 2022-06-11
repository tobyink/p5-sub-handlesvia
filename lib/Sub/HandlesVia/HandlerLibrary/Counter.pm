use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Counter;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.018';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Optional Int Any Item Defined Num );

our @METHODS = qw( set inc dec reset );

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type == Defined) {
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
	return $me->SUPER::_type_inspector($type);
}

sub set {
	handler
		name      => 'Counter:set',
		args      => 1,
		signature => [Int],
		template  => '« $ARG »',
		usage     => '$value',
		documentation => 'Sets the counter to the given value.',
}

sub inc {
	handler
		name      => 'Counter:inc',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		template  => '« $GET + (#ARG ? $ARG : 1) »',
		lvalue_template => '$GET += (#ARG ? $ARG : 1)',
		usage     => '$amount?',
		documentation => 'Increments the counter by C<< $amount >>, or by 1 if no value is given.',
}

sub dec {
	handler
		name      => 'Counter:dec',
		min_args  => 0,
		max_args  => 1,
		signature => [Optional[Int]],
		template  => '« $GET - (#ARG ? $ARG : 1) »',
		lvalue_template => '$GET -= (#ARG ? $ARG : 1)',
		usage     => '$amount?',
		documentation => 'Decrements the counter by C<< $amount >>, or by 1 if no value is given.',
}

sub reset {
	handler
		name      => 'Counter:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 0 },
		documentation => 'Sets the counter to its default value, or 0 if it has no default.',
}

1;