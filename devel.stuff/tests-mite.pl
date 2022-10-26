#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use lib "$Bin/../lib", $Bin;

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
		no strict 'refs';
		my @funcs = @{"$class\::METHODS"};
		undef $all{$category}{$_} for @funcs;
	}
}

for my $category ( @categories ) {
	my $class = "Sub::HandlesVia::HandlerLibrary::$category";
	my $lccat = lc $category;
	
	my $file = path("t/40mite/$lccat.t");
	my $fh = $file->openw;
	
	my $classfile = path("t/40mite/lib/MyTest/TestClass/$category.pm");
	my $classfh = $classfile->openw;
	
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
use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.008001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

HEADER

	my $CLASS = "MyTest::TestClass::$category";
	print $fh "use $CLASS;\n";
	print $fh "my \$CLASS = q[$CLASS];\n\n";

	print $classfh "package $CLASS;\n";
	print $classfh "\n";
	print $classfh "use MyTest::Mite;\n";
	print $classfh "use Sub::HandlesVia;\n";
	print $classfh "\n";
	print $classfh "has attr => (\n";
	print $classfh "  is => 'rwp',\n";
	print $classfh "  isa => '$type',\n";
	print $classfh "  handles_via => '$category',\n";
	print $classfh "  handles => {\n";
	print $classfh "    'my_$_' => '$_',\n" for sort keys %{$all{$category}};
	print $classfh "  },\n";
	print $classfh "  default => sub { $default },\n";	
	print $classfh ");\n";
	print $classfh "\n";
	print $classfh "1;\n";
	print $classfh "\n";
	
	for my $method (sort keys %{$all{$category}}) {
		my $h = $class->$method;

		print $fh "## $method\n\n";
		printf $fh "can_ok( \$CLASS, 'my_%s' );\n\n", $method;

		if ( $h->_examples ) {
			print $fh "subtest 'Testing my_$method' => sub {\n";
			my @lines = split /\n/, $h->_examples->( '$CLASS', "attr", "my_$method" );
			print $fh "  my \$e = exception {\n";
			for my $line ( @lines ) {
				print $fh '  ', munge_line( $line ), "\n";
			}
			print $fh "  };\n";
			print $fh "  is( \$e, undef, 'no exception thrown running $method example' );\n";
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