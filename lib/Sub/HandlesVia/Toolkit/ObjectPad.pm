use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::ObjectPad;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.040';

use Sub::HandlesVia::Mite -all;
extends 'Sub::HandlesVia::Toolkit';

around code_generator_for_attribute => sub {
	my ( $next, $me, $target, $attr ) = ( shift, shift, @_ );
	
	if ( @$attr > 1 or $attr->[0] =~ /^\w/ ) {
		return $me->$next( @_ );
	}
	
	my $attrname = $attr->[0];
	
	if ( $attrname =~ /^[@%]/ ) {
		croak "Only scalar attributes are currently supported, not $attrname";
	}
	
	use Object::Pad qw( :experimental(mop) );
	use Object::Pad::MetaFunctions ();
	
	my $metaclass = Object::Pad::MOP::Class->for_class($target);
	my $metafield = $metaclass->get_field( $attrname );
	
	my $get = sub {
		my ( $gen ) = ( shift );
		sprintf( '$metafield->value(%s)', $gen->generate_self );
	};
	
	my $set = sub {
		my ( $gen, $value ) = ( shift, @_ );
		sprintf( '( $metafield->value(%s) = %s )', $gen->generate_self, $value );
	};
	
	my $slot = sub {
		my ( $gen, $value ) = ( shift, @_ );
		sprintf( '${ Object::Pad::MetaFunctions::ref_field(%s) }', $gen->generate_self );
	};
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attrname,
		env                   => { '$metafield' => \$metafield },
		coerce                => !!0,
		generator_for_get     => $get,
		generator_for_set     => $set,
		set_checks_isa        => !!1,
		set_strictly          => !!1,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			return;
		},
		generator_for_slot    => $slot,
	);
};

1;

