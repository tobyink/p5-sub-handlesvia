use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Type::Params qw(compile_named_oo);
use Types::Standard qw( ArrayRef HashRef Str Num Int CodeRef Bool );
use Types::Standard qw( assert_HashRef is_ArrayRef );

my $sig;
sub install_delegations {
	$sig ||= compile_named_oo(
		target      => Str,
		attribute   => ArrayRef->of(Str|CodeRef)->plus_coercions(Str|CodeRef, '[$_]'),
		handles_via => ArrayRef->of(Str)->plus_coercions(Str, '[$_]'),
		handles     => HashRef->plus_coercions(ArrayRef, '+{map(+($_,$_),@$_)}'),
	);
	
	my $me = shift;
	my $arg = &$sig;

	my $callbacks = $me->make_callbacks($arg->target, $arg->attribute);
	
	use Sub::HandlesVia::Handler;
	my %handles = %{ $arg->handles };
	for my $h (sort keys %handles) {
		my $handler = Sub::HandlesVia::Handler->lookup($handles{$h}, $arg->handles_via);
#		warn $handler->code_as_string(
#			%$callbacks,
#			target      => $arg->target,
#			method_name => $h,
#		);
		$handler->install_method(
			%$callbacks,
			target      => $arg->target,
			method_name => $h,
		);
	}
}

my %native = qw(
	Array           1
	Bool            1
	Code            1
	Counter         1
	Hash            1
	Number          1
	String          1
);

sub known_handler_libraries {
	sort keys %native;
}

my %default_type = (
	Array     => ArrayRef,
	Hash      => HashRef,
	String    => Str,
	Number    => Num,
	Counter   => Int,
	Code      => CodeRef,
	Bool      => Bool,
);

sub clean_spec {
	my ($me, $target, $attr, $spec) = (shift, @_);

	delete $spec->{no_inline};

	# Clean our stuff out of traits list...
	if (ref $spec->{traits} and not $spec->{handles_via}) {
		my @keep = grep !$native{$_}, @{$spec->{traits}};
		my @cull = grep  $native{$_}, @{$spec->{traits}};
		delete $spec->{traits};
		if (@keep) {
			$spec->{traits} = \@keep;
		}
		if (@cull) {
			$spec->{handles_via} = \@cull;
		}
	}

	return unless $spec->{handles_via};
	
	my @handles_via = ref($spec->{handles_via}) ? @{$spec->{handles_via}} : $spec->{handles_via};
	my $joined      = join('|', @handles_via);

	if ($default_type{$joined} and not exists $spec->{isa}) {
		$spec->{isa}    =    $default_type{$joined};
		$spec->{coerce} = !! $default_type{$joined}->has_coercion;
	}
	
	$spec->{handles} = { map +($_ => $_), @{ $spec->{handles} } }
		if is_ArrayRef $spec->{handles};	
	assert_HashRef $spec->{handles};

	return {
		target       => $target,
		attribute    => $attr,
		handles_via  => delete($spec->{handles_via}),
		handles      => delete($spec->{handles}),
	};
}

sub make_callbacks {
	my ($me, $target, $attr) = (shift, @_);
	die "must be implemented by child classes";
}

1;