use v5.24;
use warnings;
use Time::HiRes qw(time);
use Test::Modern qw( -default is_fastest );
use B::Deparse;

my $deparse = 'B::Deparse'->new;

sub make_class {
	my ( $toolkit, $delegation_mode, $type_mode ) = map ucfirst(lc($_)), @_;
	
	my $delegation_toolkit = 'Sub::HandlesVia';
	my $traits = "handles_via => 'Array'";
	if ( $delegation_mode eq 'Native' ) {
		$delegation_toolkit = {
			Moose => 'strict ()', # no-op
			Mouse => 'MouseX::NativeTraits',
			Moo   => 'MooX::HandlesVia',
		}->{$toolkit};
		
		$traits = "traits => [ 'Array' ]"
			unless $delegation_toolkit eq 'MooX::HandlesVia';
	}

	my $type_library = 'Types::Standard';
	if ( $type_mode eq 'Native' ) {
		$type_library = {
			Moose => 'MooseX::Types::Moose',
			Mouse => 'MouseX::Types::Mouse',
			Moo   => 'MooX::Types::MooseLike::Base',
		}->{$toolkit};
	}
	
	my $packagename = sprintf(
		'Local::%s%s%s',
		$toolkit,
		$delegation_mode,
		$type_mode,
	);
	
	my $postamble = '';
	$postamble = '__PACKAGE__->meta->make_immutable;' unless $toolkit eq 'Moo';
	
	local $@;
	my $start = time;
	eval qq{
		package $packagename;
		use $toolkit;
		use $delegation_toolkit;
		use $type_library qw( ArrayRef Int );
		has attr => (
			is => 'ro',
			isa => ArrayRef[Int],
			$traits,
			handles => { pushnum => 'push' },
			default => sub { [] },
		);
		$postamble;
	};
	die($@) if $@;
	my $end = time;
	diag sprintf( 'Compiled %s in %f seconds', $packagename, $end - $start );
	diag $deparse->coderef2text( $packagename->can('pushnum') );
	return $packagename;
}

my @classes;
my @TK   = qw/ Moo Moose Mouse /;
my @D    = qw/ Native Shv /;
my @TYPE = qw/ Native Tt /;
for my $tk ( @TK ) {
	for my $d ( @D ) {
		for my $type ( @TYPE ) {
			push @classes, make_class( $tk, $d, $type );
		}
	}
}

my %impl;

for my $class ( @classes ) {
	my $ok = subtest "Testing $class" => sub {
		can_ok( $class, 'pushnum' );
		my $obj = $class->new;
		$obj->pushnum($_) for 0 .. 99;
		is_deeply( $obj->attr, [ 0 .. 99 ], 'correct behaviour' );
		my $e = exception {
			$obj->pushnum( 'notnum' );
		};
		isnt( $e, undef, 'got an exeption when pushing non-number' );
	};
	
	my $name = $class;
	$name =~ s/^Local:://;
	
	$impl{$name} = sprintf( 'my $obj = %s->new; $obj->pushnum($_) for 0..999;', $class )
		if $ok;
}

is_fastest( 'MooShvTt', -3, \%impl );

done_testing;