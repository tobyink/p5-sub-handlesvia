use Test::More;

use Sub::HandlesVia::CodeGenerator ();
use Sub::HandlesVia::Handler ();

my $gen1 = Sub::HandlesVia::CodeGenerator->new(
	target                     => 'Local::Foo',
	generator_for_slot         => sub { return '$_[0]' },
	generator_for_get          => sub { return '$_[0]' },
	generator_for_set          => sub { return '$_[0] = ' . pop; },
	generator_for_default      => sub { return '[]'; },
);

my $gen2 = Sub::HandlesVia::CodeGenerator->new(
	target                     => 'Local::Foo',
	generator_for_slot         => sub { return '$_[0]' },
	generator_for_get          => sub { return '$_[0]' },
	generator_for_set          => sub { return '$_[0] = ' . pop; },
	generator_for_default      => sub { return '[]'; },
	never_shift_self           => 1,
);

my $h = Sub::HandlesVia::Handler->lookup( [ get => 0 ], 'Array' );

my $code1 = $h->code_as_string( method_name => 'peek', code_generator => $gen1 );
my $code2 = $h->code_as_string( method_name => 'peek', code_generator => $gen2 );

like( $code1, qr/shv_self\s*=\s*shift/ );
like( $code1, qr/CORE::unshift/ );
unlike( $code1, qr/splice/ );

unlike( $code2, qr/shv_self\s*=\s*shift/ );
unlike( $code2, qr/CORE::unshift/ );
like( $code2, qr/splice/ );

done_testing;
