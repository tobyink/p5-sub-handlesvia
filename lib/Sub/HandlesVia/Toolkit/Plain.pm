use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::Plain;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

use Sub::HandlesVia::Toolkit;
our @ISA = 'Sub::HandlesVia::Toolkit';

use Types::Standard qw( is_CodeRef is_Str );

sub code_generator_for_attribute {
	my ($me, $target, $attr) = (shift, @_);
	
	my ($get_slot, $set_slot, $default) = @$attr;
	$set_slot = $get_slot if @$attr < 2;
	
	my $captures = {};
	my ($get, $set, $get_is_lvalue) = (undef, undef, 0);
	
	require B;
	
	if (ref $get_slot) {
		$get = sub { '$_[0]->$shv_reader' };
		$captures->{'$shv_reader'} = \$get_slot;
	}
	elsif ($get_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$get = sub { "\$_[0][$index]" };
		++$get_is_lvalue;
	}
	elsif ($get_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$get = sub { "\$_[0]{$key}" };
		++$get_is_lvalue;
	}
	else {
		my $method = B::perlstring($get_slot);
		$get = sub { "\$_[0]->\${\\ $method}" };
	}
	
	if (ref $set_slot) {
		$set = sub { my $val = shift or die; "\$_[0]->\$shv_writer($val)" };
		$captures->{'$shv_writer'} = \$set_slot;
	}
	elsif ($set_slot =~ /\A \[ ([0-9]+) \] \z/sx) {
		my $index = $1;
		$set = sub { my $val = shift or die; "(\$_[0][$index] = $val)" };
	}
	elsif ($set_slot =~ /\A \{ (.+) \} \z/sx) {
		my $key = B::perlstring($1);
		$set = sub { my $val = shift or die; "(\$_[0]{$key} = $val)" };
	}
	else {
		my $method = B::perlstring($set_slot);
		$set = sub { my $val = shift or die; "\$_[0]->\${\\ $method}($val)" };
	}
	
	if (is_CodeRef $default) {
		$captures->{'$shv_default_for_reset'} = \$default;
	}

	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		target                => $target,
		attribute             => $attr,
		env                   => $captures,
		coerce                => !!0,
		generator_for_get     => $get,
		generator_for_set     => $set,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => !!1,
		set_strictly          => !!1,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			if ( !$default and $handler ) {
				return $handler->default_for_reset->();
			}
			elsif ( is_CodeRef $default ) {
				return sprintf(
					'(%s)->$shv_default_for_reset',
					$gen->generator_for_self->(),
				);
			}
			elsif ( is_Str $default ) {
				require B;
				return sprintf(
					'(%s)->${\ %s }',
					$gen->generator_for_self->(),
					B::perlstring( $default ),
				);
			}
			return;
		},
	);
}

1;

