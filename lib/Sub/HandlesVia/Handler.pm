use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Handler;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

use Class::Tiny (
	qw(
		template
		lvalue_template
		args
		name
		signature
		curried
		is_chainable
		no_validation_needed
		additional_validation
		default_for_reset
		documentation
		_examples
	),
	{
		is_mutator   => sub { defined $_[0]{lvalue_template} or $_[0]{template} =~ /«/ },
		min_args     => sub { shift->args },
		max_args     => sub { shift->args },
		usage        => sub { shift->_build_usage },
		allow_getter_shortcuts => sub { 1 },
	},
);
sub has_min_args { defined shift->min_args }
sub has_max_args { defined shift->max_args }
sub _build_usage {
	no warnings 'uninitialized';
	my $self = shift;
	if ($self->has_max_args and $self->max_args==0) {
		return '';
	}
	elsif ($self->min_args==0 and $self->max_args==1) {
		return '$arg?';
	}
	elsif ($self->min_args==1 and $self->max_args==1) {
		return '$arg';
	}
	elsif ($self->min_args > 0 and $self->max_args > 0) {
		return sprintf('@min_%d_max_%d_args', $self->min_args, $self->max_args);
	}
	elsif ($self->max_args > 0) {
		return sprintf('@max_%d_args', $self->max_args);
	}
	return '@args';
}

sub curry {
	my ($self, @curried) = @_;
	if ($self->has_max_args and @curried > $self->max_args) {
		die "too many arguments to curry";
	}
	my %copy = %$self;
	delete $copy{usage};
	ref($self)->new(
		%copy,
		name         => sprintf('%s[curried]', $self->name),
		max_args     => $self->has_max_args ? $self->max_args - @curried : undef,
		min_args     => $self->has_min_args ? $self->min_args - @curried : undef,
		signature    => $self->signature ? do { my @sig = @{$self->{signature}}; splice(@sig,0,scalar(@curried)); \@sig } : undef,
		curried      => \@curried,
	);
}

sub loose {
	my $self = shift;
	ref($self)->new(%$self, signature => undef);
}

sub chainable {
	my $self = shift;
	ref($self)->new(%$self, is_chainable => 1);
}

sub _real_additional_validation {
	my $me = shift;
	my $av = $me->additional_validation;
	return $av if ref $av;
	
	my ($lib) = split /:/, $me->name;
	return sub {
		my $self = shift;
		my ($sig_was_checked, $callbacks) = @_;
		my $ti = "Sub::HandlesVia::HandlerLibrary::$lib"->_type_inspector($callbacks->{isa});
		if ($ti and $ti->{trust_mutated} eq 'always') {
			return { code => '1;', env => {} };
		}
		if ($ti and $ti->{trust_mutated} eq 'maybe') {
			return { code => '1;', env => {} };
		}
		return;
	} if $av eq 'no incoming values';

	return;
}

sub lookup {
	my $class = shift;
	my ($method, $traits) = map { ref($_) eq 'ARRAY' ? $_ : [$_] } @_;
	my ($method_name, @curry) = @$method;
	
	my $handler;
	my $make_chainable = 0;
	my $make_loose = 0;

	if (ref $method_name eq 'CODE') {
		$handler = Sub::HandlesVia::Handler::CodeRef->new(
			name              => '__ANON__',
			delegated_coderef => $method_name,
		);
	}
	else {
		if ($method_name =~ /\s*\.\.\.$/) {
			$method_name =~ s/\s*\.\.\.$//;
			++$make_chainable;
		}
		if ($method_name =~ /^\~\s*/) {
			$method_name =~ s/^\~\s*//;
			++$make_loose;
		}
		if ($method_name =~ /^(.+?)\s*\-\>\s*(.+?)$/) {
			$traits = [$1];
			$method_name = $2;
		}
	}
	
	if (not $handler) {
		SEARCH: for my $trait (@$traits) {
			my $class = $trait =~ /:/
				? $trait
				: "Sub::HandlesVia::HandlerLibrary::$trait";
			if ( $class ne $trait ) {
				local $@;
				eval "require $class; 1"
					or warn $@;
			}
			if ($class->isa('Sub::HandlesVia::HandlerLibrary') and $class->can($method_name)) {
				$handler = $class->$method_name;
			}
		}
	}
	
	if (not $handler) {
		$handler = Sub::HandlesVia::Handler::Traditional->new(name => $method_name);
	}
	
	$handler = $handler->curry(@curry)   if @curry;
	$handler = $handler->loose           if $make_loose;
	$handler = $handler->chainable       if $make_chainable;
	
	return $handler;
}

sub install_method {
	my ( $self, %arg ) = @_;
	my $gen = $arg{code_generator} or die;
	
	$gen->generate_and_install_method( $arg{method_name}, $self );
	
	return;
}

sub code_as_string {
	my ($self, %arg ) = @_;
	my $gen = $arg{code_generator} or die;

	my $eval = $gen->_generate_ec_args_for_handler( $arg{method_name}, $self );
	my $code = join "\n", @{$eval->{source}};
	if ($arg{method_name}) {
		$code =~ s/sub/sub $arg{method_name}/xs;
	}
	if (eval { require Perl::Tidy }) {
		my $tidy = '';
		Perl::Tidy::perltidy(
			source      => \$code,
			destination => \$tidy,
		);
		$code = $tidy;
	}
	$code;
}

sub _tweak_env {}

use Exporter::Shiny qw( handler );
sub _generate_handler {
	my $me = shift;
	return sub {
		my (%args) = @_%2 ? (template=>@_) : @_;
		$me->new(%args);
	};
}

package Sub::HandlesVia::Handler::Traditional;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

BEGIN { our @ISA = 'Sub::HandlesVia::Handler' };

sub BUILD {
	$_[1]{name} or die 'name required';
}

sub is_mutator { 0 }

sub template {
	my $self = shift;
	require B;
	my $q_name = B::perlstring( $self->name );
	return sprintf(
		'$GET->${\\ '.$q_name.'}( @ARG )',
	);
}

package Sub::HandlesVia::Handler::CodeRef;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.021';

BEGIN { our @ISA = 'Sub::HandlesVia::Handler' };

use Class::Tiny qw( delegated_coderef );

sub is_mutator { 0 }

sub BUILD {
	$_[1]{delegated_coderef} or die 'delegated_coderef required';
}

sub _tweak_env {
	my ( $self, $env ) = @_;
	$env->{'$shv_callback'} = \($self->delegated_coderef);
}

sub template {
	return '$shv_callback->(my $shvtmp = $GET, @ARG)';
}

1;
