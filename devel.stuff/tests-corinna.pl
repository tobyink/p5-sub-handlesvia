#!/usr/bin/env perl
use v5.38;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
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
	my $class = "Sub::HandlesVia::HandlerLibrary::$category";
	eval "require $class" or die($@);
	my @funcs = $class->handler_names;
	undef $all{$category}{$_} for @funcs;
	if ( $category eq 'Scalar' ) {
		delete $all{$category}{scalar_reference};
	}
}

for my $category ( @categories ) {
	my $class = "Sub::HandlesVia::HandlerLibrary::$category";
	my $lccat = lc $category;
	my $file = path("t/55corinna/$lccat.t");
	my $fh = $file->openw;
	my $type = {
		Array   => 'ArrayRef',
		Bool    => 'Bool',
		Code    => 'CodeRef',
		Counter => 'Int',
		Hash    => 'HashRef',
		Number  => 'Num',
		Scalar  => 'Any',
		String  => 'Str',
	}->{$category} // 'Any';
	my $default = {
		Array   => '[]',
		Bool    => '0',
		Code    => 'sub {}',
		Counter => '0',
		Hash    => '{}',
		Number  => '0',
		Scalar  => 'q[]',
		String  => 'q[]',
	}->{$category} // 'undef';

print $fh <<'HEADER';
use Test::Requires '5.038';
use 5.038;
use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';
use Test::More;
use Test::Fatal;
## skip Test::Tabs

HEADER

	print $fh "class My::Class {\n";
	print $fh "  use Types::Standard '$type';\n";
	print $fh "  field \$attr :param = $default;\n";
	print $fh "  method attr ()         { \$attr }\n";
	print $fh "  method _set_attr(\$new) { \$attr = \$new }\n";
	print $fh "  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { $default } ],\n";
	print $fh "    $category => (\n";
	print $fh "      'my_$_' => '$_',\n" for sort keys %{$all{$category}};
	print $fh "    );\n";
	print $fh "}\n";
	print $fh "\n";
	
	for my $method (sort keys %{$all{$category}}) {
		my $h = $class->get_handler($method);

		print $fh "## $method\n\n";
		printf $fh "can_ok( 'My::Class', 'my_%s' );\n\n", $method;

		if ( $h->_examples ) {
			print $fh "subtest 'Testing my_$method' => sub {\n";
			my @lines = split /\n/, $h->_examples->( 'My::Class', "attr", "my_$method" );
			print $fh "  my \$e = exception {\n";
			for my $line ( @lines ) {
				print $fh '  ', munge_line( $line ), "\n";
			}
			print $fh "  };\n";
			print $fh "  is( \$e, undef, 'no exception thrown running $method example' );\n";
			print $fh "};\n\n";
		}
	}

	my %EG = %SubHandlesViaExamples::EG;
	if ( ref $EG{$category} ) {
		for my $eg ( @{ $EG{$category} } ) {
			my @eg = @$eg;
			my $code = pop @eg;
			my ( $name, %args ) = @eg;
			my @lines = split /\n/, $code;
			print $fh "## $name\n\n";
			print $fh "subtest q{$name (extended example)} => sub {\n";
			print $fh "  my \$e = exception {\n";
			@lines = map { /^package (.+) \{/ ? ("{", "  package $1;") : $_ } @lines;
			for my $line ( @lines ) {
				print $fh '    ', munge_line( $line ), "\n";
			}
			print $fh "  };\n\n";
			print $fh "  is( \$e, undef, 'no exception thrown running example' );\n";
			print $fh "};\n\n";
		}
	}

	print $fh "done_testing;\n";
}

sub trim {
	my $arg = shift;
	$arg =~ s/^\s*//g;
	$arg =~ s/\s*$//g;
	return $arg;
}

sub munge_line {
	my $line = shift;

	if ( $line =~ /^(\s*)say Dumper\((.*)\)\s*;\s*#(.*)# ==>(.*)$/ ) {
		my ( $space, $expr, $pfx, $expected ) = ( $1, trim("$2"), $3, trim("$4") );
		return "${space}${pfx}is_deeply( $expr, $expected, q{$expr deep match} );";
	}
	elsif ( $line =~ /^(\s*)say(.*);\s*#(.*)# ==>(.*)$/ ) {
		my ( $space, $expr, $pfx, $expected ) = ( $1, trim("$2"), $3, trim("$4") );
		if ( $expected eq 'true' ) {
			return "${space}${pfx}ok( $expr, q{$expr is true} );";
		}
		elsif ( $expected eq 'false' ) {
			return "${space}${pfx}ok( !($expr), q{$expr is false} );";
		}
		else {
			return "${space}${pfx}is( $expr, $expected, q{$expr is $expected} );";
		}
	}

	$line =~ s/\bsay\b/note/;
	return $line;
}