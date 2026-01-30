use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moo;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.053001';

our $NO_SHVXS;

use Sub::HandlesVia::Mite;
extends 'Sub::HandlesVia::Toolkit';

use Types::Standard qw( is_ArrayRef is_Str assert_HashRef is_CodeRef is_Undef is_Object );
use Types::Standard qw( Any ArrayRef HashRef Str Num Int CodeRef Bool );

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	$me->install_has_wrapper($target);
}

sub install_has_wrapper {
	my $me = shift;
	my ($target) = @_;

	require Moo::_Utils;
	Moo::_Utils::_install_modifier( $target, around => has => sub {
		my $orig = shift;
		if (@_ % 2 == 0) {
			require Carp;
			Carp::croak("Invalid options for attribute(s): even number of arguments expected, got " . scalar @_);
		}
		my ($attrs, %spec) = @_;
		my $got_no_SHVXS = delete $spec{no_SHVXS};
		return $orig->($attrs, %spec) unless $spec{handles}; # shortcut
		for my $attr ( ref($attrs) ? @$attrs : $attrs ) {
			( my $real_attr = $attr ) =~ s/^[+]//;
			my $shv = $me->clean_spec($target, $real_attr, \%spec);
			$orig->($attr, %spec);
			local $NO_SHVXS = $got_no_SHVXS;
			$me->install_delegations($shv) if $shv;
		}
		return;
	});
}

sub make_xs_info {
	my ($me, $maker, $attrname, $spec) = @_;
	return if $NO_SHVXS;
	
	require Sub::HandlesVia;
	return unless Sub::HandlesVia::HAS_SHVXS;
	
	my $need_to_call_accessor = 0;
	# These seem too complicated to handle via direct hashref access.
	++$need_to_call_accessor if $spec->{trigger};
	++$need_to_call_accessor if $spec->{weak_ref};
	++$need_to_call_accessor if $spec->{moosify};
	
	# Check that the accessor maker isn't doing something crazy.
	do {
		my $generated = $maker->_generate_core_set( q{$XXX}, 'yyy', {}, q{"zzz"} );
		my $expected  = q{$XXX->{"yyy"} = "zzz"};
		++$need_to_call_accessor if $generated ne $expected;
	};
	
	my %xs_info = $need_to_call_accessor
		# Tell Sub::HandlesVia::XS that it can find an array to operate on by
		# treating the invocant as an object, and calling the reader/accessor.
		? (
			arr_source         => Sub::HandlesVia::XS->ArraySource( 'CALL_METHOD' ),
			arr_source_string  => $spec->{reader}
				|| $spec->{accessor}
				|| ( $spec->{is} =~ /^(ro|rw|lazy|rwp)$/ ? $attrname : undef ),
		)
		# Tell Sub::HandlesVia::XS that it can find an array to operate on by
		# treating the invocant as a hash, and looking at the $attrname key.
		: (
			arr_source         => Sub::HandlesVia::XS->ArraySource( 'DEREF_HASH' ),
			arr_source_string  => $attrname,
		);
	return unless defined $xs_info{arr_source_string};
	
	# In the direct hashref case, if the key doesn't exist, try calling the
	# reader method first because that might have a lazy default or builder!
	if ( $spec->{lazy} and $xs_info{arr_source} == Sub::HandlesVia::XS->ArraySource( 'DEREF_HASH' ) ) {
		$xs_info{arr_source_fallback} = $spec->{reader}
			|| $spec->{accessor}
			|| ( $spec->{is} =~ /^(ro|rw|lazy|rwp)$/ ? $attrname : undef );
		return unless defined $xs_info{arr_source_fallback};
	}

	# Strings are found the same way!
	for my $key ( sort keys %xs_info ) {
		my ( $stub ) = ( $key =~ /^arr_(.+)$/ ) or next;
		
		if ( exists $xs_info{"arr_$stub"} and not exists $xs_info{"str_$stub"} ) {
			$xs_info{"str_$stub"} = $xs_info{"arr_$stub"};
		}
	}
	
	# Type constraints in a form Sub::HandlesVia::XS can understand.
	if ( my $type = $spec->{isa} ) {
		if ( is_Object $type and $type->isa('Type::Tiny') ) {
			return if ref $spec->{coerce};
			
			my ( $coderef, $flags ) = Sub::HandlesVia::XS->TypeInfo( $spec->{isa} );
			$xs_info{type}        = $flags;
			$xs_info{type_cv}     = $coderef;
			$xs_info{type_tiny}   = $type;
			$xs_info{coercion_cv} = $type->coercion->compiled_coercion if ( $spec->{coerce} and $type->has_coercion );
			
			my $constraining_type = $type->find_constraining_type;
			if ( $constraining_type == ArrayRef ) {
				$constraining_type = ArrayRef[Any];
			}
			
			if ( $constraining_type == $type
			and  $constraining_type->is_parameterized
			and  ( $constraining_type->parent == ArrayRef or $constraining_type->parent == HashRef )
			and  @{ $constraining_type->parameters } == 1 ) {
				my $element_type = $constraining_type->type_parameter;
				my ( $coderef, $flags ) = Sub::HandlesVia::XS->TypeInfo( $element_type );
				$xs_info{element_type}        = $flags;
				$xs_info{element_type_cv}     = $coderef;
				$xs_info{element_type_tiny}   = $element_type;
				$xs_info{element_coercion_cv} = $element_type->coercion->compiled_coercion if ( $spec->{coerce} and $element_type->has_coercion );
			}
		}
		else {
			return if $spec->{coerce} && !ref $spec->{coerce};
			
			my ( $coderef, $flags ) = Sub::HandlesVia::XS->TypeInfo( $spec->{isa} );
			$xs_info{type}        = $flags;
			$xs_info{type_cv}     = $coderef;
			$xs_info{coercion_cv} = $spec->{coerce} if $spec->{coerce};
		}
	}
	elsif ( $spec->{coerce} ) {
		return;
	}
	
	return \%xs_info;
}

sub code_generator_for_attribute {
	my ($me, $target, $attrname) = (shift, @_);
	
	if (ref $attrname) {
		@$attrname==1 or die;
		($attrname) = @$attrname;
	}
	
	my $ctor_maker = $INC{'Moo.pm'} && 'Moo'->_constructor_maker_for($target);
	
	if (!$ctor_maker) {
		return $me->_code_generator_for_role_attribute($target, $attrname);
	}
	
	my $spec = $ctor_maker->all_attribute_specs->{$attrname};
	my $maker = 'Moo'->_accessor_maker_for($target);

	my $type   = $spec->{isa} ? Types::TypeTiny::to_TypeTiny($spec->{isa}) : undef;
	my $coerce = exists($spec->{coerce}) ? $spec->{coerce} : 0;
	if ((ref($coerce)||'') eq 'CODE') {
		$type   = $type->plus_coercions(Types::Standard::Any(), $coerce);
		$coerce = 1;
	}
	
	my $slot = sub {
		my $gen = shift;
		my ($code) = $maker->generate_simple_get($gen->generate_self, $attrname, $spec);
		$code;
	};
	
	my $captures = {};
	my ($is_simple_get, $get) = $maker->is_simple_get($attrname, $spec)
		? (1, sub {
			my $gen = shift;
			my $selfvar = $gen ? $gen->generate_self : '$_[0]';
			my ($return) = $maker->generate_simple_get($selfvar, $attrname, $spec);
			%$captures = ( %$captures, %{ delete($maker->{captures}) or {} } );
			$return;
		})
		: (0, sub {
			my $gen = shift;
			my $selfvar = $gen ? $gen->generate_self : '$_[0]';
			my ($return) = $maker->_generate_use_default(
				$selfvar,
				$attrname,
				$spec,
				$maker->_generate_simple_has($selfvar, $attrname, $spec),
			);
			%$captures = ( %$captures, %{ delete($maker->{captures}) or {} } );
			$return;
		});
	my ($is_simple_set, $set) = $maker->is_simple_set($attrname, $spec)
		? (1, sub {
			my ($gen, $var) = @_;
			my $selfvar = $gen ? $gen->generate_self : '$_[0]';
			my $code = $maker->_generate_simple_set($selfvar, $attrname, $spec, $var);
			$captures = { %$captures, %{ delete($maker->{captures}) or {} } };  # merge environments
			$code;
		})
		: (0, sub { # that allows us to avoid going down this yucky code path
			my ($gen, $var) = @_;
			my $selfvar = $gen ? $gen->generate_self : '$_[0]';
			my $code = $maker->_generate_set($attrname, $spec);
			$captures = { %$captures, %{ delete($maker->{captures}) or {} } };  # merge environments
			$code = "do { local \@_ = ($selfvar, $var); $code }";
			$code;
		});
	
	# force $captures to be updated
	$get->(undef, '$dummy');
	$set->(undef, '$dummy');
	
	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}
	
	if (is_CodeRef $default->[1]) {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attrname,
		attribute_spec        => $spec,
		xs_info               => scalar( $me->make_xs_info($maker, $attrname, $spec) ),
		env                   => $captures,
		isa                   => $type,
		coerce                => !!$coerce,
		generator_for_slot    => $slot,
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $is_simple_get,
		set_checks_isa        => !$is_simple_set,
		set_strictly          => $spec->{weak_ref} || $spec->{trigger},
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( $default->[0] eq 'builder' ) {
				return sprintf(
					'(%s)->%s',
					$gen->generate_self,
					$default->[1],
				);
			}
			elsif ( $default->[0] eq 'default' and is_CodeRef $default->[1] ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( $default->[0] eq 'default' and is_Undef $default->[1] ) {
				return 'undef';
			}
			elsif ( $default->[0] eq 'default' and is_Str $default->[1] ) {
				require B;
				return B::perlstring( $default->[1] );
			}
			return;
		},
	);
}

sub _code_generator_for_role_attribute {
	my ($me, $target, $attrname) = (shift, @_);
	
	if (ref $attrname) {
		@$attrname==1 or die;
		($attrname) = @$attrname;
	}
	
	require B;
	
	my %all_specs = @{ $Moo::Role::INFO{$target}{attributes} };
	my $spec      = $all_specs{$attrname};

	my ($reader_name, $writer_name);
	
	if ($spec->{is} eq 'ro') {
		$reader_name = $attrname;
	}
	elsif ($spec->{is} eq 'rw') {
		$reader_name = $attrname;
		$writer_name = $attrname;
	}
	elsif ($spec->{is} eq 'rwp') {
		$reader_name = $attrname;
		$writer_name = "_set_$attrname";
	}
	if (exists $spec->{reader}) {
		$reader_name = $spec->{reader};
	}
	if (exists $spec->{writer}) {
		$writer_name = $spec->{reader};
	}
	if (exists $spec->{accessor}) {
		$reader_name = $spec->{accessor} unless defined $reader_name;
		$writer_name = $spec->{accessor} unless defined $writer_name;
	}
	
	my $type = $spec->{isa} ? Types::TypeTiny::to_TypeTiny($spec->{isa}) : undef;
	my $coerce = $spec->{coerce};
	if ((ref($coerce)||'') eq 'CODE') {
		$type   = $type->plus_coercions(Types::Standard::Any(), $coerce);
		$coerce = 1;
	}
	
	my $captures = {};
	my ($get, $set);
	
	if (defined $reader_name) {
		$get = ($reader_name =~ /^[\W0-9]\w*$/s)
			? sub { my $gen = shift; sprintf "%s->%s", $gen->generate_self, $reader_name }
			: sub { my $gen = shift; sprintf "%s->\${\\ %s }", $gen->generate_self, B::perlstring($reader_name) };
	}
	else {
		my ($default, $default_literal) = (undef, 0);
		if (is_Coderef $spec->{default}) {
			$default = $spec->{default};
		}
		elsif (exists $spec->{default}) {
			++$default_literal;
			$default = $spec->{default};
		}
		elsif (is_CodeRef $spec->{builder} or (($spec->{builder}||0) eq 1)) {
			$default = '_build_'.$attrname;
		}
		elsif ($spec->{builder}) {
			$default = $spec->{builder};
		}
		else {
			++$default_literal;
		}
		my $dammit_i_need_to_build_a_reader = sub {
			my $instance = shift;
			exists($instance->{$attrname}) or do {
				$instance->{$attrname} ||= $default_literal ? $default : $instance->$default;
			};
			$instance->{$attrname};
		};
		$captures->{'$shv_reader'} = \$dammit_i_need_to_build_a_reader;
		$get = sub { my $gen = shift; $gen->generate_self . '->$shv_reader()' };
	}
	
	
	if (defined $writer_name) {
		$set = $writer_name =~ /^[\W0-9]\w*$/s
			? sub { my ($gen, $val) = @_; sprintf "%s->%s(%s)", $gen->generate_self, $writer_name, $val }
			: sub { my ($gen, $val) = @_; sprintf "%s->\${\\ %s }(%s)", $gen->generate_self, B::perlstring($writer_name), $val };
	}
	else {
		my $trigger;
		if (($spec->{trigger}||0) eq 1) {
			$trigger = "_trigger_$attrname";
		}
		my $weaken = $spec->{weak_ref} || 0;
		my $dammit_i_need_to_build_a_writer = sub {
			my ($instance, $new_value) = (shift, @_);
			if ($type) {
				($type->has_coercion && $coerce)
					? ($new_value = $type->assert_coerce($new_value))
					: $type->assert_valid($new_value);
			}
			if ($trigger) {
				$instance->$trigger($new_value, exists($instance->{$attrname}) ? $instance->{$attrname} : ())
			}
			$instance->{$attrname} = $new_value;
			if ($weaken and ref $new_value) {
				Scalar::Util::weaken($instance->{$attrname});
			}
			$instance->{$attrname};
		};
		$captures->{'$shv_writer'} = \$dammit_i_need_to_build_a_writer;
		$set = sub { my ($gen, $val) = @_; $gen->generate_self . "->\$shv_writer($val)" };
	}

	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}
	
	if (is_CodeRef $default->[1]) {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attrname,
		attribute_spec        => $spec,
		env                   => $captures,
		isa                   => $type,
		coerce                => !!$coerce,
		generator_for_slot    => sub { shift->generate_self.'->{'.B::perlstring($attrname).'}' }, # icky
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => !!0,
		set_checks_isa        => !!1,
		set_strictly          => !!0,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( $default->[0] eq 'builder' ) {
				return sprintf(
					'(%s)->%s',
					$gen->generate_self,
					$default->[1],
				);
			}
			elsif ( $default->[0] eq 'default' and is_CodeRef $default->[1] ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generate_self,
				);
			}
			elsif ( $default->[0] eq 'default' and is_Undef $default->[1] ) {
				return 'undef';
			}
			elsif ( $default->[0] eq 'default' and is_Str $default->[1] ) {
				require B;
				return B::perlstring( $default->[1] );
			}
			return;
		},
	);
}

1;
