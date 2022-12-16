#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib", $Bin;

use SubHandlesViaExamples;
use Sub::HandlesVia ();
use Path::Tiny 'path';

my @categories = qw(
	Array
	Bool
	Code
	Counter
	Hash
	Number
	Scalar
	String
);

my %all;

for my $category (@categories) {
	{
		my $class = "Sub::HandlesVia::HandlerLibrary::$category";
		eval "require $class" or die($@);
		my @funcs = $class->handler_names;
		undef $all{$category}{$_} for @funcs;
	}
}

for my $category ( @categories ) {
	my $file = path("lib/Sub/HandlesVia/HandlerLibrary/$category.pod");
	my $fh = $file->openw;
	my $class = "Sub::HandlesVia::HandlerLibrary::$category";
	my $lccat = lc $category;
	my $type = {
		Array   => 'ArrayRef',
		Bool    => 'Bool',
		Code    => 'CodeRef',
		Counter => 'Int',
		Hash    => 'HashRef',
		Number  => 'Num',
		Scalar  => 'Any',
		String  => 'Str',
	}->{$category};

	print $fh "=head1 NAME\n\n";
	print $fh "Sub::HandlesVia::HandlerLibrary::$category - library of $lccat-related methods\n\n";

	print $fh "=head1 SYNOPSIS\n\n";
	print $fh "  package My::Class {\n";
	print $fh "    use Moo;\n";
	print $fh "    use Sub::HandlesVia;\n";
	print $fh "    use Types::Standard '$type';\n";
	print $fh "    has attr => (\n";
	print $fh "      is => 'rwp',\n";
	print $fh "      isa => $type,\n";
	print $fh "      handles_via => '$category',\n";
	print $fh "      handles => {\n";
	print $fh "        'my_$_' => '$_',\n" for sort keys %{$all{$category}};
	print $fh "      },\n";
	print $fh "    );\n";
	print $fh "  }\n";
	print $fh "\n";

	print $fh "=head1 DESCRIPTION\n\n";
	print $fh "This is a library of methods for L<Sub::HandlesVia>.\n\n";

	print $fh "=head1 DELEGATABLE METHODS\n\n";
	for my $method (sort keys %{$all{$category}}) {
		my $h = $class->get_handler($method);

		if ( $h->usage ) {
			printf $fh "=head2 C<< %s( %s ) >>\n\n", $method, $h->usage;
		}
		elsif ( $h->args == 0 ) {
			printf $fh "=head2 C<< %s() >>\n\n", $method;
		}
		else {
			printf $fh "=head2 C<< %s >>\n\n", $method;
		}

		if ( $h->signature and @{ $h->signature } ) {
			printf $fh "Arguments: %s.\n\n",
				join q[, ], map sprintf( 'B<< %s >>', $_->display_name ), @{ $h->signature };
		}

		if ( $h->documentation ) {
			print $fh $h->documentation, "\n\n";
		}

		if ( $h->_examples ) {
			print $fh $h->_examples->( 'My::Class', "attr", "my_$method" );
		}
	}

	my %SEC = %SubHandlesViaExamples::SEC;
	if ( $SEC{$category} ) {
		print $fh $SEC{$category};
	}

	my %EG = %SubHandlesViaExamples::EG;
	if ( ref $EG{$category} ) {
		print $fh "=head1 EXTENDED EXAMPLES\n\n";
		for my $eg ( @{ $EG{$category} } ) {
			my @eg = @$eg;
			my $code = pop @eg;
			my ( $name, %args ) = @eg;
			my @lines = split /\n/, $code;
			print $fh "=head2 $name\n\n";
			print $fh "$args{head}\n\n" if $args{head};
			for ( @lines ) {
				s/#.*(#\s*==>)/#$1/g;
				print $fh "  $_\n";
			}
			print $fh "\n";
			print $fh "$args{tail}\n\n" if $args{tail};
		}
	}

	print $fh <<'EOF';
=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

=head1 SEE ALSO

L<Sub::HandlesVia>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

EOF
}
