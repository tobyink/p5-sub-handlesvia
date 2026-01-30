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
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count', myfor => 'for_each' },
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
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count', myfor => 'for_each' },
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
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count', myfor => 'for_each' },
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
		handles      => { mypush => 'push', mypop => 'pop', mycount => 'count', myfor => 'for_each' },
	);
}

my $n = 100_000;
my $N = 0.5 * $n * ( $n + 1 );
my %closures = map {
	my $tag   = $_;
	my $class = "Local::$tag";
	$tag => sub {
		for my $i ( 1..10 ) {
			my $obj = $class->new;
			$obj->mypush($_) for 1..$n;
			die unless $obj->mycount == $n;
			my $sum = 0;
			$obj->myfor( sub { $sum += $_ } );
			die $sum unless $sum == $N;
			$obj->mypop for 2..$n;
			die unless $obj->mycount == 1;
			die unless $obj->mypop == 1;
		}
	};
} qw( PP PPmxtt XS XSmxtt );

cmpthese( -5, \%closures );

__END__
       s/iter     PP PPmxtt XSmxtt     XS
PP       1.16     --   -10%   -33%   -35%
PPmxtt   1.04    12%     --   -25%   -27%
XSmxtt  0.777    49%    33%     --    -3%
XS      0.757    53%    37%     3%     --

       s/iter     PP PPmxtt XSmxtt     XS
PP       1.25     --    -1%   -29%   -30%
PPmxtt   1.23     1%     --   -28%   -29%
XSmxtt  0.882    42%    40%     --    -0%
XS      0.880    42%    40%     0%     --

       s/iter     PP PPmxtt XSmxtt     XS
PP       1.37     --    -8%   -42%   -44%
PPmxtt   1.25     9%     --   -37%   -38%
XSmxtt  0.786    74%    59%     --    -2%
XS      0.770    77%    62%     2%     --
