use 5.008;
use strict;
use warnings;

package Sub::HandlesVia;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

sub import {
	my $me     = shift;
	my $target = caller;
	if ($INC{'Moo/Role.pm'} && Moo::Role->is_role($target)) {
		require Sub::HandlesVia::Toolkit::Moo;
		Sub::HandlesVia::Toolkit::Moo->install_has_wrapper($target);
	}
	elsif ($Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}) {
		require Sub::HandlesVia::Toolkit::Moo;
		Sub::HandlesVia::Toolkit::Moo->install_has_wrapper($target);
	}
	else {
		require Carp;
		Carp::croak("$target does not seem to be a Moo class or role");
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia - alternative handles_via implementation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-HandlesVia>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

