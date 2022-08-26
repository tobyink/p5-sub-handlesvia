#!/usr/bin/env perl
use v5.16;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";

use Data::Perl ();
use MouseX::NativeTraits ();
use Moose ();
use Sub::HandlesVia ();
use Data::Dumper;
use Class::Inspector;
use Path::Tiny 'path';

my $MooseTraitBase = path(
	'/home/tai/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/x86_64-linux/Moose/Meta/Method/Accessor/Native/'
);

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
	
	DATAPERL: {
		my $class = 'Data::Perl::Role::'.($category=~/(Hash)|(Array)/ ? 'Collection::' : '').$category;
		eval "require $class" or last DATAPERL;
		my @funcs = 
			grep !/^_/,
			grep !/^(new|with|after|around|before|requires|use_package_optimistically|blessed)$/,
			@{ Class::Inspector->functions($class) };
		undef $all{$category}{$_}{'Data::Perl'} for @funcs;
	};
	
	SHV: {
		my $class = "Sub::HandlesVia::HandlerLibrary::$category";
		eval "require $class" or last SHV;
		no strict 'refs';
		my @funcs = @{"$class\::METHODS"};
		undef $all{$category}{$_}{'Sub::HandlesVia'} for @funcs;
	};
	
	MOOSE: {
		my $dir = $MooseTraitBase->child($category);
		$dir->is_dir or last MOOSE;
		my @files = $dir->children(qr/\.pmc?$/);
		my @funcs = grep !/Writer/, map $_->basename(qr/\.pmc?$/), @files;
		undef $all{$category}{$_}{'Moose'} for @funcs;
	};
	
	MOUSE: {
		my $mousecat = {qw/
			Array      ArrayRef
			Bool       Bool
			Code       CodeRef
			Counter    Counter
			Hash       HashRef
			Number     Num
			String     Str
		/}->{$category};
		my $class = "MouseX::NativeTraits::MethodProvider::$mousecat";
		eval "require $class" or last MOUSE;
		my @funcs = 
			map  s/^generate_//r,
			grep /^generate_/,
			@{ Class::Inspector->functions($class) };
		undef $all{$category}{$_}{'MouseX::NativeTraits'} for @funcs;
	};
}

delete $all{Code}{execute_method}{'Data::Perl'};

$all{Array}{fetch}{info}   = 'alias: get';
$all{Array}{remove}{info}  = 'alias: delete';
$all{Array}{sort_by}{info} = 'sort';
$all{Array}{sort_in_place_by}{info} = 'sort_in_place';
$all{Array}{store}{info}   = 'alias: set';
$all{Hash}{fetch}{info}    = 'alias: get';
$all{Hash}{store}{info}    = 'alias: set';

for my $category (sort keys %all) {
	print "  $category ", "="x(51-length $category), "\n";
	for my $method (sort keys %{$all{$category}}) {
		printf(
			"%23s : %5s  %5s  %5s  %5s  %s\n",
			$method,
			exists($all{$category}{$method}{'Sub::HandlesVia'})       ? 'SubHV' : '',
			exists($all{$category}{$method}{'Data::Perl'})            ? 'DataP' : '',
			exists($all{$category}{$method}{'Moose'})                 ? 'Moose' : '',
			exists($all{$category}{$method}{'MouseX::NativeTraits'})  ? 'Mouse' : '',
			exists($all{$category}{$method}{'info'})                  ? sprintf('(%s)', $all{$category}{$method}{'info'}) : '',
		);
	}
	print "\n";
}


