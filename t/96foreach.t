use strict;
use warnings;
use Test::More;
{ package Local::Dummy; use Test::Requires 'Moo' };

{
	package Local::Class;
	use Moo;
	use Sub::HandlesVia;
	has collection => (
		is          => 'ro',
		handles_via => 'Array',
		handles     => [qw/ for_each for_each_pair /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ 1 2 3 4 5 6 /],
);

my @r = ();

is_deeply(
	$collection->for_each(sub {
		push @r, [@_];
	}),
	$collection,
);

is_deeply(
	\@r,
	[[1,0], [2,1], [3,2], [4,3], [5,4], [6,5]],
);

@r = ();

is_deeply(
	$collection->for_each_pair(sub {
		push @r, [@_];
	}),
	$collection,
);

is_deeply(
	\@r,
	[[1,2], [3,4], [5,6]],
);

done_testing;
