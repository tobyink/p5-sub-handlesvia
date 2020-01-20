use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Handler;

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
	),
	{
		is_mutator   => sub { defined $_[0]{lvalue_template} or $_[0]{template} =~ /«/ },
		min_args     => sub { shift->args },
		max_args     => sub { shift->args },
		usage        => sub { shift->_build_usage },
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
	ref($self)->new(
		name         => sprintf('%s[curried]', $self->name),
		max_args     => $self->has_max_args ? $self->max_args - @curried : undef,
		min_args     => $self->has_min_args ? $self->min_args - @curried : undef,
		signature    => $self->signature ? do { my @sig = @{$self->{signature}}; splice(@sig,0,scalar(@curried)); \@sig } : undef,
		curried      => \@curried,
		is_mutator   => $self->is_mutator,
		template     => $self->template,
		lvalue_template => $self->lvalue_template,
		additional_validation => $self->additional_validation,
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
			return ('1;', {});
		}
		if ($ti and $ti->{trust_mutated} eq 'maybe') {
			return ('1;', {});
		}
		return;
	} if $av eq 'no incoming values';

	return;
}

sub lookup {
	my $class = shift;
	my ($method, $traits) = map { ref($_) eq 'ARRAY' ? $_ : [$_] } @_;
	my ($method_name, @curry) = @$method;
	
	my $make_chainable = 0;
	if ($method_name =~ /\-\>$/) {
		$method_name =~ s/\-\>$//;
		++$make_chainable;
	}
	
	my $make_loose = 0;
	if ($method_name =~ /^\~/) {
		$method_name =~ s/^\~//;
		++$make_loose;
	}
	
	my $handler;
	SEARCH: for my $trait (@$traits) {
		my $class = "Sub::HandlesVia::HandlerLibrary::$trait";
		eval "require $class";
		if ($class->can($method_name)) {
			$handler = $class->$method_name;
		}
	}
	
	return unless $handler;
	
	$handler = $handler->curry(@curry)   if @curry;
	$handler = $handler->loose           if $make_loose;
	$handler = $handler->chainable       if $make_chainable;
	
	return $handler;
}

sub _process_template {
	my ($self, $template, %callbacks) = @_;
	
	my $wrapper;
	
	my $getter = $callbacks{get}->();
	if ($getter !~ /^ 
		\$                 # scalar access
		[^\W0-9]\w*        # normal-looking variable name (including $_)
		(?:                # then...
			(?:\-\>)?       #     dereference maybe
			[\[\{]          #     opening [ or {
			[\'\"]?         #     quote maybe
			\w+             #     word characters (includes digits)
			[\'\"]?         #     quote maybe
			[\]\}]          #     closing ] or }
		){0,3}             # ... up to thrice
		$/x
		and $template =~ /\$GET/) {
		# Getter is kind of complex (maybe includes function calls, etc
		# So only do it once.
		$getter =~ s/%/%%/g;
		$wrapper = "do { my \$shv_real_invocant = $getter; %s }";
		$getter  = '$shv_real_invocant';
	}
	$template =~ s/\$GET/$getter/g;
	$template =~ s/\$ARG\[([0-9]+)\]/$callbacks{arg}->($1)/eg;
	$template =~ s/\$ARG/$callbacks{arg}->(1)/eg;
	$template =~ s/\$SELF/$callbacks{self}->()/eg;
	$template =~ s/\#ARG/$callbacks{argc}->()/eg;
	$template =~ s/\@ARG/$callbacks{args}->()/eg;
	$template =~ s/«(.+?)»/$callbacks{set}->($1)/eg;
	$template =~ s/\$DEFAULT/$callbacks{default_for_reset}->($self, \%callbacks)/eg;
	
	$wrapper ? sprintf($wrapper, $template) : $template;
}

sub _coderef {
	my ($self, %callbacks) = @_;
	my $env = { %{$callbacks{env}||{}} };
	my $min_args = $self->has_min_args ? $self->min_args : 0;
	my $max_args = $self->max_args;
	
	my @code = ('sub {');
	
	my $sig_was_checked = 0;
	if (@{ $self->signature || [] }) {
		require Type::Params;
		unshift @code, 'my $__sigcheck;';
		$env->{'@__sig'} = $self->signature;
		push @code, '$__sigcheck||=Type::Params::compile(1, @__sig);@_=&$__sigcheck;';
		++$sig_was_checked;
	}
	else {
		my $usg = sprintf(
			'do { require Carp; Carp::croak("Wrong number of parameters; usage: ".%s) }',
			B::perlstring( $callbacks{usage_string}->($callbacks{method_name}, $self->usage) ),
		);
		
		if (defined $min_args and defined $max_args and $min_args==$max_args) {
			push @code, sprintf('@_==%d or %s;', $min_args + 1, $usg);
		}
		elsif (defined $min_args and defined $max_args) {
			push @code, sprintf('(@_ >= %d and @_ <= %d) or %s;', $min_args + 1, $max_args + 1, $usg);
		}
		elsif (defined $min_args) {
			push @code, sprintf('@_ >= %d or %s;', $min_args + 1, $usg);
		}
	}
	
	if (my $curried = $self->curried) {
		if (grep ref, @$curried) {
			$env->{'@curry'} = $curried;
			push @code, $callbacks{curry}->('@curry');
		} else {
			require B;
			push @code, $callbacks{curry}->(sprintf('(%s)', join ',', map { defined ? B::perlstring($_) : 'undef' } @$curried));
		}
	}
	
	my $something_can_go_wrong = $self->is_mutator && !!ref($callbacks{isa});
	
	if ($self->no_validation_needed) {
		$something_can_go_wrong = 0;
	}
	
	if ($self->name =~ /^(Array|Hash):/) {
		my $getter = $callbacks{get}->();
		if ($getter !~ /^ 
			\$                 # scalar access
			[^\W0-9]\w*        # normal-looking variable name (including $_)
			(?:                # then...
				(?:\-\>)?       #     dereference maybe
				[\[\{]          #     opening [ or {
				[\'\"]?         #     quote maybe
				\w+             #     word characters (includes digits)
				[\'\"]?         #     quote maybe
				[\]\}]          #     closing ] or }
			){0,3}             # ... up to thrice
			$/x) {
			push @code, "my \$shv_ref_invocant = do { $getter };";
			$callbacks{get} = sub { '$shv_ref_invocant' };
			$callbacks{get_is_lvalue} = 1;
		}
	}
	
	my $add_later;
	if ($something_can_go_wrong and defined $self->additional_validation) {
		my ($add_code, $add_env, $later) = $self->_real_additional_validation->($self, $sig_was_checked, \%callbacks);
		if ($later) {
			$add_later = $add_code;
			$env->{$_} = $add_env->{$_} for keys %$add_env;
			$something_can_go_wrong = 0;
		}
		elsif ($add_code) {
			push @code, $add_code;
			$env->{$_} = $add_env->{$_} for keys %$add_env;
			$something_can_go_wrong = 0;
		}
	}
	
	if (!$something_can_go_wrong
	and !$callbacks{be_strict}
	and $callbacks{set_checks_isa}
	and defined $callbacks{simple_set}) {
		$callbacks{set} = $callbacks{simple_set};
	}

	if ($something_can_go_wrong and not $callbacks{set_checks_isa}) {
		my $orig_set = delete $callbacks{set};
		$callbacks{get_is_lvalue} = 0;
		$callbacks{set} = sub {
			my $value = shift;
			$orig_set->(sprintf(
				'do { my $unchecked = %s; %s }',
				$value,
				$callbacks{isa}->inline_assert('$unchecked', '$finaltype'),
			));
		};
		$env->{'$finaltype'} = \$callbacks{isa};
		$something_can_go_wrong = 0;
	}
	
	my $template = $self->template;
	if ($callbacks{get_is_lvalue} and !$callbacks{be_strict} and !$something_can_go_wrong) {
		$template = $self->lvalue_template if $self->lvalue_template;
	}
	
	my $body = $self->_process_template($template, %callbacks);
	$body =~ s/\"?____VALIDATION_HERE____\"?/$add_later/ if defined $add_later;
	
	push @code, $body;
	push @code, "}";
	
	return (
		source      => \@code,
		environment => $env,
		description => sprintf("%s=%s", $callbacks{method_name}||'__ANON__', $self->name),
	);
}

sub coderef {
	my ($self, %callbacks) = @_;
	my %eval = $self->_coderef(%callbacks);
#	warn join("\n", @{$eval{source}});
#	for my $key (sort keys %{$eval{environment}}) {
#		warn ">> $key : ".ref($eval{environment}{$key});
#	}
	require Eval::TypeTiny;
	Eval::TypeTiny::eval_closure(%eval);
}

sub install_method {
	my ($self, %callbacks) = @_;
	my $target  = $callbacks{target} or die;
	my $name    = $callbacks{method_name} or die;
	my $coderef = $self->coderef(is_method => 1, %callbacks);
	
	if ( eval { require Sub::Util }) {
		$coderef = Sub::Util::set_subname("$target\::$name", $coderef);
		no strict 'refs';
		*{"$target\::$name"} = $coderef;
	}
	else {
		eval qq{
			package $target;
			sub $name { goto \$coderef };
			1;
		} or die($@);
	}
}

use Exporter::Shiny qw( handler );
sub _generate_handler {
	my $me = shift;
	return sub {
		my (%args) = @_%2 ? (template=>@_) : @_;
		$me->new(%args);
	};
}	



1;
