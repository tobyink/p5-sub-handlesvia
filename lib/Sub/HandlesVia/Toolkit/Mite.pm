use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Mite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.026';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	$me->install_has_wrapper($target);
}

my %SPECS;
sub install_has_wrapper {
	my $me = shift;
	my ($target) = @_;
	
	no strict 'refs';
	no warnings 'redefine';
	
	my $orig = \&{ "$target\::has" };
	*{ "$target\::has" } = sub {
		my ( $names, %spec ) = @_;
		return $orig->($names, %spec) unless $spec{handles}; # shortcut
		
		$names = [ $names ] unless ref($names);
		for my $name ( @$names ) {
			my $shv = $me->clean_spec( $target, $name, \%spec );
			$SPECS{$target}{$name} = \%spec;
			$orig->( $name, %spec );
			$me->install_delegations( $shv ) if $shv;
		}
		
		return;
	};
}

my @method_name_generator = (
	{ # public
		reader      => sub { "get_$_" },
		writer      => sub { "set_$_" },
		accessor    => sub { $_ },
		clearer     => sub { "clear_$_" },
		predicate   => sub { "has_$_" },
		builder     => sub { "_build_$_" },
		trigger     => sub { "_trigger_$_" },
	},
	{ # private
		reader      => sub { "_get_$_" },
		writer      => sub { "_set_$_" },
		accessor    => sub { $_ },
		clearer     => sub { "_clear_$_" },
		predicate   => sub { "_has_$_" },
		builder     => sub { "_build_$_" },
		trigger     => sub { "_trigger_$_" },
	},
);

sub code_generator_for_attribute {
	my ( $me, $target, $attrname ) = ( shift, @_ );
	
	my $name = $attrname->[0];
	my $spec = $SPECS{$target}{$name};
	my $env  = {};
	
	my $private = 0+!! ( $name =~ /^_/ );
	
	$spec->{is} ||= 'bare';
	if ( $spec->{is} eq 'lazy' ) {
		$spec->{builder} = 1 unless exists $spec->{builder};
		$spec->{is}      = 'ro';
	}
	if ( $spec->{is} eq 'ro' ) {
		$spec->{reader} = $name unless exists $spec->{reader};
	}
	if ( $spec->{is} eq 'rw' ) {
		$spec->{accessor} = $name unless exists $spec->{accessor};
	}
	if ( $spec->{is} eq 'rwp' ) {
		$spec->{reader} = $name unless exists $spec->{reader};
		$spec->{writer} = "_set_$name" unless exists $spec->{writer};
	}
	
	for my $property ( 'reader', 'writer', 'accessor', 'builder' ) {
		my $methodname = $spec->{$property};
		if ( defined $methodname and $methodname eq 1 ) {
			my $gen = $method_name_generator[$private]{$property};
			local $_ = $name;
			$spec->{$property} = $gen->( $_ );
		}
	}
	
	my ( $get, $set, $get_is_lvalue, $set_checks_isa, $default, $slot );
	
	if ( my $reader = $spec->{reader} || $spec->{accessor} ) {
		$get = sub { shift->generate_self . "->$reader" };
		$get_is_lvalue = !!0;
	}
	else {
		$get = sub { shift->generate_self . "->{q[$name]}" };
		$get_is_lvalue = !!1;
	}
	
	if ( my $writer = $spec->{writer} || $spec->{accessor} ) {
		$set = sub {
			my ( $gen, $expr ) = @_;
			$gen->generate_self . "->$writer($expr)";
		};
		$set_checks_isa = !!1;
	}
	else {
		$set = sub {
			my ( $gen, $expr ) = @_;
			"( " . $gen->generate_self . "->{q[$name]} = $expr )";
		};
		$set_checks_isa = !!0;
	}
	
	$slot = sub { shift->generate_self . "->{q[$name]}" };
	
	if ( ref $spec->{builder} ) {
		$default = $spec->{builder};
		$env->{'$shv_default_for_reset'} = \$default;
	}
	elsif ( $spec->{builder} ) {
		$default = $spec->{builder};
	}
	elsif ( ref $spec->{default} ) {
		$default = $spec->{default};
		$env->{'$shv_default_for_reset'} = \$default;
	}
	elsif ( exists $spec->{default} ) {
		my $value = $spec->{default};
		$default = sub { $value };
		$env->{'$shv_default_for_reset'} = \$default;
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $name,
		env                   => $env,
		isa                   => $spec->{type},
		coerce                => $spec->{coerce},
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => $set_checks_isa,
		set_strictly          => !!1,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( is_CodeRef $default ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( is_Str $default ) {
				require B;
				return sprintf(
					'(%s)->${\ %s }',
					$gen->generate_self,
					B::perlstring( $default ),
				);
			}
			return;
		},
		( $slot ? ( generator_for_slot => $slot ) : () ),
	);
}

1;
