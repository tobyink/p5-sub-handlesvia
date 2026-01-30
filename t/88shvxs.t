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
	
	has status => (
		is          => 'rw',
		isa         => Enum[ qw/ urgent normal / ],
		default     => 'normal',
		handles_via => 'Enum',
		handles     => 1,
	);
	
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

{
	package Local::Tasks2;
	use Moo;
	use Types::Standard -types;
	use Sub::HandlesVia;
	
	has status => (
		is          => 'rw',
		isa         => Enum[ qw/ urgent normal / ],
		default     => 'normal',
		handles_via => 'Enum',
		handles     => 1,
	);
	
	has list => (
		is          => 'lazy',
		isa         => ( ArrayRef[Str] )->where( sub { 1 } ),
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

sub run_tests {
	my $class = shift;
	
	my $todo = $class->new;
	
	ok( $todo->is_normal );
	
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
}

subtest "Local::Tasks works" => sub { run_tests('Local::Tasks') };
ok( Sub::HandlesVia::is_xs( Local::Tasks->can($_) ), "Local::Tasks::$_ is XS" ) for qw/
	add_task
	next_task
	take_task
	task_count
	free_time
	uc_tasks
	is_urgent
	is_normal
/;

subtest "Local::Tasks2 works" => sub { run_tests('Local::Tasks2') };
ok( Sub::HandlesVia::is_xs( Local::Tasks->can($_) ), "Local::Tasks2::$_ is XS" ) for qw/
	next_task
	task_count
	free_time
	uc_tasks
	is_urgent
	is_normal
/;
ok( Sub::HandlesVia::is_xs( Local::Tasks->can($_) ), "Local::Tasks2::$_ is PURE PERL" ) for qw/
	add_task
	take_task
/;

done_testing;
