use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires 'Sub::HandlesVia::XS';

{
	package Local::Tasks;
	use Moo;
	use Types::Standard -types;
	use Sub::HandlesVia;
	
	has list => (
		is          => 'lazy',
		isa         => ArrayRef[Str],
		default     => sub { [] },
		handles_via => 'Array',
		handles     => {
			add_task       => 'push...',
			next_task      => 'peek',
			take_task      => 'shift',
			task_count     => 'count',
			free_time      => 'is_empty',
			uc_tasks       => [ map => sub { uc $_ } ],
		},
	);
}

my $todo = Local::Tasks->new;
$todo
	->add_task("Wake up")
	->add_task("Get out of bed")
	->add_task("Get dressed")
	->add_task("Brush teeth");

is( $todo->task_count, 4 );
is( $todo->next_task, 'Wake up' );
is( $todo->take_task, 'Wake up' );
is( $todo->task_count, 3 );

isnt( exception { $todo->add_task([]) }, undef );

is( $todo->task_count, 3 );
is( $todo->take_task, 'Get out of bed' );
is( $todo->task_count, 2 );

is_deeply( [ $todo->uc_tasks ], [ 'GET DRESSED', 'BRUSH TEETH' ] );

ok( Sub::HandlesVia::is_xs( Local::Tasks->can($_) ), "$_ is XS" ) for qw/
	add_task
	next_task
	take_task
	task_count
	free_time
	uc_tasks
/;

done_testing;
