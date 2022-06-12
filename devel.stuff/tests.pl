#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";

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
	my $file = path("t/30egpod/$lccat.t");
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
	}->{$category};
	my $default = {
		Array   => '[]',
		Bool    => '0',
		Code    => 'sub {}',
		Counter => '0',
		Hash    => '{}',
		Number  => '0',
		Scalar  => 'q[]',
		String  => 'q[]',
	}->{$category};

print $fh <<'HEADER';
use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
## skip Test::Tabs

{ package Local::Dummy1; use Test::Requires { 'Moo' => '1.006' } };

use constant { true => !!1, false => !!0 };

HEADER

	print $fh "BEGIN {\n";
	print $fh "  package My::Class;\n";
	print $fh "  use Moo;\n";
	print $fh "  use Sub::HandlesVia;\n";
	print $fh "  use Types::Standard '$type';\n";
	print $fh "  has attr => (\n";
	print $fh "    is => 'rwp',\n";
	print $fh "    isa => $type,\n";
	print $fh "    handles_via => '$category',\n";
	print $fh "    handles => {\n";
	print $fh "      'my_$_' => '$_',\n" for sort keys %{$all{$category}};
	print $fh "    },\n";
	print $fh "    default => sub { $default },\n";	
	print $fh "  );\n";
	print $fh "};\n";
	print $fh "\n";
	
	for my $method (sort keys %{$all{$category}}) {
		my $h = $class->$method;

		print $fh "## $method\n\n";
		printf $fh "can_ok( 'My::Class', 'my_%s' );\n\n", $method;

		if ( $h->_examples ) {
			print $fh "subtest 'Testing my_$method' => sub {\n";
			my @lines = split /\n/, $h->_examples->( 'My::Class', "attr", "my_$method" );
			print $fh "  my \$e = exception {\n";
			for my $line ( @lines ) {
				if ( $line =~ /^(\s*)say Dumper\((.*)\)\s*;\s## ==>(.*)$/ ) {
					my ( $space, $expr, $expected ) = ( $1, trim("$2"), trim("$3") );
					print $fh $space . "  is_deeply( $expr, $expected, q{$expr deep match} );\n";
				}
				elsif ( $line =~ /^(\s*)say(.*);\s## ==>(.*)$/ ) {
					my ( $space, $expr, $expected ) = ( $1, trim("$2"), trim("$3") );
					if ( $expected eq 'true' ) {
						print $fh $space . "  ok( $expr, q{$expr is true} );\n";
					}
					elsif ( $expected eq 'false' ) {
						print $fh $space . "  ok( !($expr), q{$expr is false} );\n";
					}
					else {
						print $fh $space . "  is( $expr, $expected, q{$expr is $expected} );\n";
					}
				}
				elsif ( $line ) {
					$line =~ s/\bsay\b/note/;
					print $fh "  $line\n";
				}
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
