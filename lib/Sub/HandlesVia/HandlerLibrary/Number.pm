use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Number;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.018';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Num Any Item Defined );

our @METHODS = qw( set get add sub mul div mod abs cmp eq ne gt lt ge le );

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type==Num or $type==Defined) {
		return {
			trust_mutated => 'maybe',
			value_type    => $type,
		};
	}
	return $me->SUPER::_type_inspector($type);
}

sub set {
	handler
		name      => 'Number:set',
		args      => 1,
		signature => [Num],
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
		usage => '$value',
		documentation => "Sets the number to a new value.",
}

sub get {
	handler
		name      => 'Number:get',
		args      => 0,
		template  => '$GET',
		documentation => "Returns the current value of the number.",
}

sub add {
	handler
		name      => 'Number:add',
		args      => 1,
		signature => [Num],
		template  => '« $GET + $ARG »',
		usage     => '$addend',
		documentation => "Adds a number to the existing number, updating the attribute.",
}

sub sub {
	handler
		name      => 'Number:sub',
		args      => 1,
		signature => [Num],
		template  => '« $GET - $ARG »',
		usage     => '$subtrahend',
		documentation => "Subtracts a number from the existing number, updating the attribute.",
}

sub mul {
	handler
		name      => 'Number:mul',
		args      => 1,
		signature => [Num],
		template  => '« $GET * $ARG »',
		usage     => '$factor',
		documentation => "Multiplies the existing number by a number, updating the attribute.",
}

sub div {
	handler
		name      => 'Number:div',
		args      => 1,
		signature => [Num],
		template  => '« $GET / $ARG »',
		usage     => '$divisor',
		documentation => "Divides the existing number by a number, updating the attribute.",
}

sub mod {
	handler
		name      => 'Number:mod',
		args      => 1,
		signature => [Num],
		template  => '« $GET % $ARG »',
		usage     => '$divisor',
		documentation => "Finds the current number modulo a divisor, updating the attribute.",
}

sub abs {
	handler
		name      => 'Number:abs',
		args      => 0,
		template  => '« abs($GET) »',
		additional_validation => 'no incoming values',
		documentation => "Finds the absolute value of the current number, updating the attribute.",
}

for my $comparison ( qw/ cmp eq ne lt gt le ge / ) {
	my $op = {
		cmp => '<=>',
		eq  => '==',
		ne  => '!=',
		lt  => '<',
		gt  => '>',
		le  => '<=',
		ge  => '>=',
	}->{$comparison};

	no strict 'refs';
	*$comparison = sub {
		handler
			name      => "Number:$comparison",
			args      => 1,
			signature => [Num],
			usage     => '$num',
			template  => "\$GET $op \$ARG",
			documentation => "Returns C<< \$object->attr $op \$num >>.",
	};
}


1;
