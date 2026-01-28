use strict;
use warnings;
use Benchmark 'cmpthese';

package Local::PP {
	use Moo;
	use Sub::HandlesVia;
	use Types::Common -types;
	has list => (
		no_SHVXS     => 1,
		is           => 'lazy',
		isa          => ArrayRef[Int],
		default      => sub { [] },
		handles_via  => 'Array',
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count' },
	);
}

package Local::XS {
	use Moo;
	use Sub::HandlesVia;
	use Types::Common -types;
	has list => (
		is           => 'lazy',
		isa          => ArrayRef[Int],
		default      => sub { [] },
		handles_via  => 'Array',
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count' },
	);
}

package Local::PPmxtt {
	use Moo;
	use MooX::TypeTiny;
	use Sub::HandlesVia;
	use Types::Common -types;
	has list => (
		no_SHVXS     => 1,
		is           => 'lazy',
		isa          => ArrayRef[Int],
		default      => sub { [] },
		handles_via  => 'Array',
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count' },
	);
}

package Local::XSmxtt {
	use Moo;
	use MooX::TypeTiny;
	use Sub::HandlesVia;
	use Types::Common -types;
	has list => (
		is           => 'lazy',
		isa          => ArrayRef[Int],
		default      => sub { [] },
		handles_via  => 'Array',
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count' },
	);
}

my %closures = map {
	my $tag   = $_;
	my $class = "Local::$tag";
	$tag => sub {
		for my $i ( 1..10 ) {
			my $obj = $class->new;
			$obj->mypush($_) for 1..10_000;
			die unless $obj->mycount == 10_000;
			$obj->mypop for 1..9_999;
			die unless $obj->mycount == 1;
			die unless $obj->mypop == 1;
		}
	};
} qw( PP PPmxtt XS XSmxtt );

cmpthese( -3, \%closures );
