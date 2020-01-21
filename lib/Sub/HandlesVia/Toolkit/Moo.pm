use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moo;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

use Data::Dumper;
use Types::Standard qw( is_ArrayRef is_Str assert_HashRef is_CodeRef is_Undef );
use Types::Standard qw( ArrayRef HashRef Str Num Int CodeRef Bool );

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	$me->install_has_wrapper($target);
}

sub install_has_wrapper {
	my $me = shift;
	my ($target) = @_;

	my ($installer, $orig);
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		$installer = 'Moo::Role::_install_tracked';
		$orig = $Moo::Role::INFO{$target}{exports}{has};
	}
	else {
		$installer = 'Moo::_install_tracked';
		$orig = $Moo::MAKERS{$target}{exports}{has} || $Moo::MAKERS{$target}{non_methods}{has};
	}
	
	$orig ||= $target->can('has');
	ref($orig) or croak("$target doesn't have a `has` function");
	
	$target->$installer(has => sub {
		if (@_ % 2 == 0) {
			require Carp;
			Carp::croak("Invalid options for attribute(s): even number of arguments expected, got " . scalar @_);
		}
		my ($attrs, %spec) = @_;
		return $orig->($attrs, %spec) unless $spec{handles}; # shortcut
		$attrs = [$attrs] unless ref $attrs;
		for my $attr (@$attrs) {
			my $shv = $me->clean_spec($target, $attr, \%spec);
			$orig->($attr, %spec);
			$me->install_delegations($shv) if $shv;
		}
		return;
	});
}

my %standard_callbacks = (
	args => sub {
		'@_[1..$#_]';
	},
	arg => sub {
		@_==1 or die;
		my $n = shift;
		"\$_[$n]";
	},
	argc => sub {
		'(@_-1)';
	},
	curry => sub {
		@_==1 or die;
		my $arr = shift;
		"splice(\@_,1,0,$arr);";
	},
	usage_string => sub {
		@_==2 or die;
		my $method_name = shift;
		my $guts = shift;
		"\$instance->$method_name($guts)";
	},
	self => sub {
		'$_[0]';
	},
);

sub make_callbacks {
	my ($me, $target, $attrname) = (shift, @_);
	
	if (ref $attrname) {
		@$attrname==1 or die;
		($attrname) = @$attrname;
	}
	
	my $spec = Moo->_constructor_maker_for($target)->all_attribute_specs->{$attrname};
		
	my $maker = $me->_accessor_maker_for($target);
	my ($is_simple_get, $get, $captures) = $maker->is_simple_get($attrname, $spec)
		? (1, $maker->generate_simple_get('$_[0]', $attrname, $spec))
		: (0, $maker->_generate_get($attrname, $spec), delete($maker->{captures})||{});
	my ($is_simple_set, $set) = $maker->is_simple_set($attrname, $spec)
		? (1, sub {
			my ($var) = @_;
			$maker->_generate_simple_set('$_[0]', $attrname, $spec, $var);
		})
		: (0, sub { # that allows us to avoid going down this yucky code path
			my ($var) = @_;
			my $code = $maker->_generate_set($attrname, $spec);
			$captures = { %$captures, %{ delete($maker->{captures}) or {} } };  # merge environments
			$code = "do { local \@_ = (\$_[0], $var); $code }";
			$code;
		});
	
	# force $captures to be updated
	$set->('$dummy') if !$is_simple_set;
	
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
	
	return {
		%standard_callbacks,
		is_method      => !!1,
		get            => sub { $get },
		get_is_lvalue  => $is_simple_get,
		set            => $set,
		set_checks_isa => !$is_simple_set,
		isa            => Types::TypeTiny::to_TypeTiny($spec->{isa}),
		coerce         => !!$spec->{coerce},
		env            => $captures,
		be_strict      => $spec->{weak_ref}||$spec->{trigger},
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and is_CodeRef $default->[1]) {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and is_Undef $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and is_Str $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	};
}

sub _accessor_maker_for {
	my $me = shift;
	my ($target) = @_;
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		my $dummy = 'MooX::Enumeration::____DummyClass____';
		eval('package ' # hide from CPAN indexer
		. "$dummy; use Moo");
		return Moo->_accessor_maker_for($dummy);
	}
	elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
		return Moo->_accessor_maker_for($target);
	}
	else {
		require Carp;
		Carp::croak("Cannot get accessor maker for $target");
	}
}

1;
