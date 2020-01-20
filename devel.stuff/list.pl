use v5.16;
use strict;
use warnings;

use Data::Perl ();
use MouseX::NativeTraits ();
use Moose ();
use Sub::HandlesVia ();
use Data::Dumper;
use Class::Inspector;
use Path::Tiny 'path';

my $MooseTraitBase = path(
	'/home/tai/perl5/perlbrew/perls/perl-5.26.2/lib/site_perl/5.26.2/x86_64-linux/Moose/Meta/Method/Accessor/Native/'
);

my @categories = qw(
	Array
	Bool
	Code
	Counter
	Hash
	Number
	String
);

my %all;

for my $category (@categories) {
	
	{
		my $class = 'Data::Perl::Role::'.($category=~/(Hash)|(Array)/ ? 'Collection::' : '').$category;
		eval "require $class" or die($@);
		my @funcs = 
			grep !/^_/,
			grep !/^(new|with|after|around|before|requires|use_package_optimistically|blessed)$/,
			@{ Class::Inspector->functions($class) };
		undef $all{$category}{$_}{'Data::Perl'} for @funcs;
	}
	
	{
		my $class = "Sub::HandlesVia::HandlerLibrary::$category";
		eval "require $class" or die($@);
		no strict 'refs';
		my @funcs = @{"$class\::METHODS"};
		undef $all{$category}{$_}{'Sub::HandlesVia'} for @funcs;
	}
	
	{
		my $dir   = $MooseTraitBase->child($category);
		my @files = $dir->children(qr/\.pmc?$/);
		my @funcs = grep !/Writer/, map $_->basename(qr/\.pmc?$/), @files;
		undef $all{$category}{$_}{'Moose'} for @funcs;
	}
	
	{
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
		eval "require $class" or die($@);
		my @funcs = 
			map  s/^generate_//r,
			grep /^generate_/,
			@{ Class::Inspector->functions($class) };
		undef $all{$category}{$_}{'MouseX::NativeTraits'} for @funcs;
	}
}

delete $all{Code}{execute_method}{'Data::Perl'};

for my $category (sort keys %all) {
	print "  $category ", "="x(48-length $category), "\n";
	for my $method (sort keys %{$all{$category}}) {
		printf(
			"%20s : %5s  %5s  %5s  %5s\n",
			$method,
			exists($all{$category}{$method}{'Sub::HandlesVia'})       ? 'SubHV' : '',
			exists($all{$category}{$method}{'Data::Perl'})            ? 'DataP' : '',
			exists($all{$category}{$method}{'Moose'})                 ? 'Moose' : '',
			exists($all{$category}{$method}{'MouseX::NativeTraits'})  ? 'Mouse' : '',
		);
	}
	print "\n";
}


