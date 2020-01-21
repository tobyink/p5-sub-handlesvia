use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Moose;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

sub setup_for {
	my $me = shift;
	my ($target) = @_;
	
	require Moose::Util;
	my $meta = Moose::Util::find_meta($target);
	Role::Tiny->apply_roles_to_object($meta, $me->package_trait);
}

sub package_trait {
	__PACKAGE__ . "::PackageTrait";
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
	
	my $meta;
	if (ref $target) {
		$meta   = $target;
		$target = $meta->name;
	}
	else {
		require Moose::Util;
		$meta = Moose::Util::find_meta($target);
	}

	my $attr = $meta->get_attribute($attrname);	
	my $spec = +{%$attr};

	my $captures = {};

	my ($get, $set, $get_is_lvalue, $set_checks_isa);
	if (!$spec->{lazy} and !$spec->{traits} and !$spec->{auto_deref}) {
		require B;
		my $slot = B::perlstring($attr->name);
		$get = sub { "\$_[0]{$slot}" };
		++$get_is_lvalue;
	}
	elsif ($attr->has_read_method) {
		my $read_method = $attr->get_read_method;
		$get = sub { "scalar(\$_[0]->$read_method)" };
	}
	else {
		my $read_method = $attr->get_read_method_ref;
		eval { $read_method = $read_method->{body} };  # Moose docs lie!
		$captures->{'$shv_read_method'} = \$read_method;
		$get = sub { 'scalar($_[0]->$shv_read_method)' };
	}
	
	if ($attr->has_write_method) {
		my $write_method = $attr->get_write_method;
		$set = sub { my $val = shift; "\$_[0]->$write_method\($val)" };
		++$set_checks_isa;
	}
	else {
		$captures->{'$shv_write_method'} = \(sub { $attr->set_value(@_) });
		$set = sub { my $val = shift; '$_[0]->$shv_write_method('.$val.')' };
		++$set_checks_isa;
	}

	my $default;
	if (exists $spec->{default}) {
		$default = [ default => $spec->{default} ];
	}
	elsif (exists $spec->{builder}) {
		$default = [ builder => $spec->{builder} ];
	}

	if (ref $default->[1] eq 'CODE') {
		$captures->{'$shv_default_for_reset'} = \$default->[1];
	}

	return {
		%standard_callbacks,
		is_method      => !!1,
		get            => $get,
		get_is_lvalue  => $get_is_lvalue,
		set            => $set,
		set_checks_isa => $set_checks_isa,
		isa            => Types::TypeTiny::to_TypeTiny($attr->type_constraint),
		coerce         => !!$spec->{coerce},
		env            => $captures,
		be_strict      => !!1,
		install_method => sub { $meta->add_method(@_) },
		default_for_reset => sub {
			my ($handler, $callbacks) = @_ or die;
			if (!$default) {
				return $handler->default_for_reset->();
			}
			elsif ($default->[0] eq 'builder') {
				return sprintf('(%s)->%s', $callbacks->{self}->(), $default->[1]);
			}
			elsif ($default->[0] eq 'default' and ref $default->[1] eq 'CODE') {
				return sprintf('(%s)->$shv_default_for_reset', $callbacks->{self}->());
			}
			elsif ($default->[0] eq 'default' and !defined $default->[1]) {
				return 'undef';
			}
			elsif ($default->[0] eq 'default' and !ref $default->[1]) {
				require B;
				return B::perlstring($default->[1]);
			}
			else {
				die 'lolwut?';
			}
		},
	};
}

package Sub::HandlesVia::Toolkit::Moose::PackageTrait;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Role::Tiny;

sub _shv_toolkit {
	'Sub::HandlesVia::Toolkit::Moose',
}

around add_attribute => sub {
	my ($next, $self, $attrname, @args) = (shift, shift, @_);
	my $spec = (@args == 1) ? $args[0] : { @args };
	$spec->{definition_context}{shv} = $self->_shv_toolkit->clean_spec($self->name, $attrname, $spec);
	my $attr = $self->$next($attrname, $spec);
	if ($spec->{definition_context}{shv} and $self->isa('Moose::Meta::Class')) {
		$self->_shv_toolkit->install_delegations($spec->{definition_context}{shv});
	}
	return $attr;
};

1;