use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Enum;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.045';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( is_Str Any );

# Non-exhaustive list!
sub handler_names {
	qw( is assign );
}

sub has_handler {
	my ($me, $handler_name) = @_;
	return 1 if $handler_name =~ /^(is|assign)$/;
	return 1 if is_Str $handler_name and $handler_name =~ /^(is|assign)_(.+)$/;
	return 0;
}

sub get_handler {
	my ($me, $handler_name) = @_;
	
	$handler_name =~ /^(is|assign)_(.+)$/
		or return $me->SUPER::get_handler( $handler_name );
	
	my $handler_type = $1;
	my $param        = $2;
	
	return $me->get_handler( $handler_type )->curry( $param );
}

sub assign {
	handler
		name      => 'Enum:assign',
		args      => 1,
		signature => [Any],
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
		usage     => '$value',
		documentation => "Sets the enum to a new value.",
}

sub is {
	handler
		name      => "Enum:is",
		args      => 1,
		signature => [Any],
		template  => "\$GET eq \$ARG",
		documentation => "Returns C<< \$object->attr eq \$str >>.",
};

1;

__END__

=head1 NAME

Sub::HandlesVia::HandlerLibrary::Enum - library of enum-related methods

=head1 SYNOPSIS

  package My::Class {
    use Moo;
    use Sub::HandlesVia;
    use Types::Standard 'Enum';
    has status => (
      is => 'ro',
      isa => Enum[ 'pass', 'fail' ],
      handles_via => 'Enum',
      handles => {
        'is_pass'      => [ is     => 'pass' ],
        'is_fail'      => [ is     => 'fail' ],
        'assign_pass'  => [ assign => 'pass' ],
        'assign_fail'  => [ assign => 'fail' ],
      },
      default => sub { 'fail' },
    );
  }

Or, using a shortcut:

  package My::Class {
    use Moo;
    use Sub::HandlesVia;
    use Types::Standard 'Enum';
    has status => (
      is => 'ro',
      isa => Enum[ 'pass', 'fail' ],
      handles_via => 'Enum',
      handles => {
        'is_pass'      => 'is_pass',
        'is_fail'      => 'is_fail',
        'assign_pass'  => 'assign_pass',
        'assign_fail'  => 'assign_fail',
      },
      default => sub { 'fail' },
    );
  }

(Sub::HandlesVia::HandlerLibrary::Enum will split on "_".)

=head1 DESCRIPTION

This is a library of methods for L<Sub::HandlesVia>.

=head1 DELEGATABLE METHODS

This allows for delegation roughly compatible with L<MooseX::Enumeration>
and L<MooX::Enumeration>, even though that's basically a renamed subset of
L<Sub::HandlesVia::HandlerLibrary::String> anyway.

=head2 C<< is( $value ) >>

Returns a boolean indicating whether the enum is that value.

  my $object = My::Class->new( status => 'pass' );
  say $object->is_pass(); ## ==> true
  say $object->is_fail(); ## ==> false

=head2 C<< assign( $value ) >>

Sets the enum to the value.

  my $object = My::Class->new( status => 'pass' );
  say $object->is_pass(); ## ==> true
  say $object->is_fail(); ## ==> false
  $object->assign_fail();
  say $object->is_pass(); ## ==> false
  say $object->is_fail(); ## ==> true

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

