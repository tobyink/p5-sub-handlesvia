use Test::More;

{
	package ParentClass;
	use Mouse;

	has 'test' => (
		is => 'ro',
		default => sub { [] },
	);
}

{
	package ThisFails;
	use Mouse;
	use Sub::HandlesVia;

	extends 'ParentClass';

	has '+test' => (
		handles_via => 'Array',
		handles => {
			'push' => 'push...'
		}
	);
}

my $obj = ThisFails->new;
is_deeply($obj->push('a')->push('test')->test, [qw(a test)]);

done_testing;
