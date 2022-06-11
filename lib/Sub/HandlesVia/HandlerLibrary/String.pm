use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::String;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.017';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
use Types::Standard qw( Optional Str CodeRef RegexpRef Int Any Item Defined );

our @METHODS = qw(
	set get inc append prepend chop chomp clear reset
	length substr replace replace_globally uc lc fc
	starts_with   ends_with   contains   match   cmp  eq  ne  gt  lt  ge  le
	starts_with_i ends_with_i contains_i match_i cmpi eqi nei gti lti gei lei
);

my $fold = ( $] >= 5.016 ) ? 'CORE::fc' : 'lc';

sub _type_inspector {
	my ($me, $type) = @_;
	if ($type == Str or $type == Defined) {
		return {
			trust_mutated => 'always',
		};
	}
	return $me->SUPER::_type_inspector($type);
}

sub set {
	handler
		name      => 'String:set',
		args      => 1,
		signature => [Str],
		template  => '« $ARG »',
		lvalue_template => '$GET = $ARG',
}

sub get {
	handler
		name      => 'String:get',
		args      => 0,
		template  => '$GET',
}

sub inc {
	handler
		name      => 'String:inc',
		args      => 0,
		template  => '« do { my $shv_tmp = $GET; ++$shv_tmp } »',
		lvalue_template => '++$GET',
		additional_validation => 'no incoming values',
}

sub append {
	handler
		name      => 'String:append',
		args      => 1,
		signature => [Str],
		template  => '« $GET . $ARG »',
		lvalue_template => '$GET .= $ARG',
}

sub prepend {
	handler
		args      => 1,
		name      => 'String:prepend',
		signature => [Str],
		template  => '« $ARG . $GET »',
}

sub replace {
	handler
		name      => 'String:replace',
		args      => 2,
		signature => [ Str|RegexpRef, Str|CodeRef ],
		usage     => '$regexp, $replacement',
		template  => sprintf(
			'my $shv_tmp = $GET; if (%s) { my $shv_callback = $ARG[2]; $shv_tmp =~ s/$ARG[1]/$shv_callback->()/e } else { $shv_tmp =~ s/$ARG[1]/$ARG[2]/ } «$shv_tmp»',
			CodeRef->inline_check('$ARG[2]'),
		),
		lvalue_template => sprintf(
			'if (%s) { my $shv_callback = $ARG[2]; $GET =~ s/$ARG[1]/$shv_callback->()/e } else { $GET =~ s/$ARG[1]/$ARG[2]/ } $GET',
			CodeRef->inline_check('$ARG[2]'),
		),
}

sub replace_globally {
	handler
		name      => 'String:replace_globally',
		args      => 2,
		signature => [ Str|RegexpRef, Str|CodeRef ],
		usage     => '$regexp, $replacement',
		template  => sprintf(
			'my $shv_tmp = $GET; if (%s) { my $shv_callback = $ARG[2]; $shv_tmp =~ s/$ARG[1]/$shv_callback->()/eg } else { $shv_tmp =~ s/$ARG[1]/$ARG[2]/g } «$shv_tmp»',
			CodeRef->inline_check('$ARG[2]'),
		),
		lvalue_template => sprintf(
			'if (%s) { my $shv_callback = $ARG[2]; $GET =~ s/$ARG[1]/$shv_callback->()/eg } else { $GET =~ s/$ARG[1]/$ARG[2]/g } $GET',
			CodeRef->inline_check('$ARG[2]'),
		),
}

sub match {
	handler
		name      => 'String:match',
		args      => 1,
		signature => [ Str|RegexpRef ],
		usage     => '$regexp',
		template  => '$GET =~ /$ARG/',
}

sub match_i {
	handler
		name      => 'String:match_i',
		args      => 1,
		signature => [ Str|RegexpRef ],
		usage     => '$regexp',
		template  => '$GET =~ /$ARG/i',
}

sub starts_with {
	handler
		name      => 'String:starts_with',
		args      => 1,
		signature => [ Str ],
		usage     => '$head',
		template  => 'substr($GET, 0, length $ARG) eq $ARG',
}

sub starts_with_i {
	handler
		name      => 'String:starts_with_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$head',
		template  => sprintf( '%s(substr($GET, 0, length $ARG)) eq %s($ARG)', $fold, $fold ),
}

sub ends_with {
	handler
		name      => 'String:ends_with',
		args      => 1,
		signature => [ Str ],
		usage     => '$tail',
		template  => 'substr($GET, -length $ARG) eq $ARG',
}

sub ends_with_i {
	handler
		name      => 'String:ends_with_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$tail',
		template  => sprintf( '%s(substr($GET, -length $ARG)) eq %s($ARG)', $fold, $fold ),
}

sub contains {
	handler
		name      => 'String:contains',
		args      => 1,
		signature => [ Str ],
		usage     => '$str',
		template  => 'index($GET, $ARG) != -1',
}

sub contains_i {
	handler
		name      => 'String:contains_i',
		args      => 1,
		signature => [ Str ],
		usage     => '$tail',
		template  => sprintf( 'index(%s($GET), %s($ARG)) != -1', $fold, $fold ),
}

sub chop {
	handler
		name      => 'String:chop',
		args      => 0,
		template  => 'my $shv_return = chop(my $shv_tmp = $GET); «$shv_tmp»; $shv_return',
		lvalue_template => 'chop($GET)',
		additional_validation => 'no incoming values',
}

sub chomp {
	handler
		name      => 'String:chomp',
		args      => 0,
		template  => 'my $shv_return = chomp(my $shv_tmp = $GET); «$shv_tmp»; $shv_return',
		lvalue_template => 'chomp($GET)',
		additional_validation => 'no incoming values',
}

sub clear {
	handler
		name      => 'String:clear',
		args      => 0,
		template  => '«q()»',
		additional_validation => 'no incoming values',
}

sub reset {
	handler
		name      => 'String:reset',
		args      => 0,
		template  => '« $DEFAULT »',
		default_for_reset => sub { 'q()' },
}

sub length {
	handler
		name      => 'String:length',
		args      => 0,
		template  => 'length($GET)',
}

sub substr {
	handler
		name      => 'String:substr',
		min_args  => 1,
		max_args  => 3,
		signature => [Int, Optional[Int], Optional[Str]],
		usage     => '$start, $length?, $replacement?',
		template  => 'if (#ARG==1) { substr($GET, $ARG[1]) } elsif (#ARG==2) { substr($GET, $ARG[1], $ARG[2]) } elsif (#ARG==3) { my $shv_tmp = $GET; my $shv_return = substr($shv_tmp, $ARG[1], $ARG[2], $ARG[3]); «$shv_tmp»; $shv_return } ',
		lvalue_template  => 'if (#ARG==1) { substr($GET, $ARG[1]) } elsif (#ARG==2) { substr($GET, $ARG[1], $ARG[2]) } elsif (#ARG==3) { substr($GET, $ARG[1], $ARG[2], $ARG[3]) } ',
}

for my $comparison ( qw/ cmp eq ne lt gt le ge / ) {
	no strict 'refs';

	*$comparison = sub {
		handler
			name      => "String:$comparison",
			args      => 1,
			signature => [Str],
			usage     => '$str',
			template  => "\$GET $comparison \$ARG",
	};

	*{ $comparison . 'i' } = sub {
		handler
			name      => "String:$comparison" . 'i',
			args      => 1,
			signature => [Str],
			usage     => '$str',
			template  => "$fold(\$GET) $comparison $fold(\$ARG)",
	};
}

for my $mutation ( qw/ uc fc lc / ) {
	no strict 'refs';
	*$mutation = sub {
		handler
			name      => "String:$mutation",
			args      => 0,
			template  => "$mutation(\$GET)",
	};
}

1;
