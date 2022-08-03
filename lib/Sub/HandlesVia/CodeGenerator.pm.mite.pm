{

    package Sub::HandlesVia::CodeGenerator;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Sub::HandlesVia::Mite";
    our $MITE_VERSION = "0.008002";

    BEGIN {
        require Scalar::Util;
        *bare    = \&Sub::HandlesVia::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Sub::HandlesVia::Mite::carp;
        *confess = \&Sub::HandlesVia::Mite::confess;
        *croak   = \&Sub::HandlesVia::Mite::croak;
        *false   = \&Sub::HandlesVia::Mite::false;
        *guard   = \&Sub::HandlesVia::Mite::guard;
        *lazy    = \&Sub::HandlesVia::Mite::lazy;
        *ro      = \&Sub::HandlesVia::Mite::ro;
        *rw      = \&Sub::HandlesVia::Mite::rw;
        *rwp     = \&Sub::HandlesVia::Mite::rwp;
        *true    = \&Sub::HandlesVia::Mite::true;
    }

    # Standard Moose/Moo-style constructor
    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute toolkit
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 12
        if ( exists $args->{"toolkit"} ) {
            $self->{"toolkit"} = $args->{"toolkit"};
        }

        # Attribute target
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 16
        if ( exists $args->{"target"} ) {
            $self->{"target"} = $args->{"target"};
        }

        # Attribute attribute
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 20
        if ( exists $args->{"attribute"} ) {
            $self->{"attribute"} = $args->{"attribute"};
        }

        # Attribute attribute_spec (type: HashRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 24
        if ( exists $args->{"attribute_spec"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"attribute_spec"} ) eq 'HASH';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "attribute_spec", "HashRef";
            $self->{"attribute_spec"} = $args->{"attribute_spec"};
        }

        # Attribute isa
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 29
        if ( exists $args->{"isa"} ) { $self->{"isa"} = $args->{"isa"}; }

        # Attribute coerce (type: Bool)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 33
        if ( exists $args->{"coerce"} ) {
            do {

                package Sub::HandlesVia::Mite;
                !ref $args->{"coerce"}
                  and (!defined $args->{"coerce"}
                    or $args->{"coerce"} eq q()
                    or $args->{"coerce"} eq '0'
                    or $args->{"coerce"} eq '1' );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "coerce", "Bool";
            $self->{"coerce"} = $args->{"coerce"};
        }

        # Attribute env (type: HashRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 38
        do {
            my $value = exists( $args->{"env"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"env"} ) eq 'HASH';
                    }
                ) ? $args->{"env"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "env", "HashRef"
                )
              )
              : {};
            $self->{"env"} = $value;
        };

        # Attribute generator_for_slot (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
        if ( exists $args->{"generator_for_slot"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_slot"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_slot", "CodeRef";
            $self->{"generator_for_slot"} = $args->{"generator_for_slot"};
        }

        # Attribute generator_for_get (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
        if ( exists $args->{"generator_for_get"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_get"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_get", "CodeRef";
            $self->{"generator_for_get"} = $args->{"generator_for_get"};
        }

        # Attribute generator_for_set (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
        if ( exists $args->{"generator_for_set"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_set"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_set", "CodeRef";
            $self->{"generator_for_set"} = $args->{"generator_for_set"};
        }

        # Attribute generator_for_default (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
        if ( exists $args->{"generator_for_default"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"generator_for_default"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "generator_for_default", "CodeRef";
            $self->{"generator_for_default"} = $args->{"generator_for_default"};
        }

        # Attribute generator_for_args (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 58
        do {
            my $value = exists( $args->{"generator_for_args"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_args"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_args"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_args", "CodeRef"
                )
              )
              : $self->_build_generator_for_args;
            $self->{"generator_for_args"} = $value;
        };

        # Attribute generator_for_arg (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 71
        do {
            my $value = exists( $args->{"generator_for_arg"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_arg"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_arg"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_arg", "CodeRef"
                )
              )
              : $self->_build_generator_for_arg;
            $self->{"generator_for_arg"} = $value;
        };

        # Attribute generator_for_argc (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 82
        do {
            my $value = exists( $args->{"generator_for_argc"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_argc"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_argc"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_argc", "CodeRef"
                )
              )
              : $self->_build_generator_for_argc;
            $self->{"generator_for_argc"} = $value;
        };

        # Attribute generator_for_currying (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 95
        do {
            my $value = exists( $args->{"generator_for_currying"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_currying"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_currying"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_currying", "CodeRef"
                )
              )
              : $self->_build_generator_for_currying;
            $self->{"generator_for_currying"} = $value;
        };

        # Attribute generator_for_usage_string (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 110
        do {
            my $value = exists( $args->{"generator_for_usage_string"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_usage_string"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_usage_string"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_usage_string", "CodeRef"
                )
              )
              : $self->_build_generator_for_usage_string;
            $self->{"generator_for_usage_string"} = $value;
        };

        # Attribute generator_for_self (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 121
        do {
            my $value = exists( $args->{"generator_for_self"} )
              ? (
                (
                    do {

                        package Sub::HandlesVia::Mite;
                        ref( $args->{"generator_for_self"} ) eq 'CODE';
                    }
                ) ? $args->{"generator_for_self"} : croak(
                    "Type check failed in constructor: %s should be %s",
                    "generator_for_self", "CodeRef"
                )
              )
              : $self->_build_generator_for_self;
            $self->{"generator_for_self"} = $value;
        };

        # Attribute method_installer (type: CodeRef)
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 124
        if ( exists $args->{"method_installer"} ) {
            do {

                package Sub::HandlesVia::Mite;
                ref( $args->{"method_installer"} ) eq 'CODE';
              }
              or croak "Type check failed in constructor: %s should be %s",
              "method_installer", "CodeRef";
            $self->{"method_installer"} = $args->{"method_installer"};
        }

        # Attribute is_method
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 134
        $self->{"is_method"} =
          ( exists( $args->{"is_method"} ) ? $args->{"is_method"} : "1" );

        # Attribute get_is_lvalue
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 139
        $self->{"get_is_lvalue"} = (
            exists( $args->{"get_is_lvalue"} )
            ? $args->{"get_is_lvalue"}
            : "" );

        # Attribute set_checks_isa
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 144
        $self->{"set_checks_isa"} = (
            exists( $args->{"set_checks_isa"} )
            ? $args->{"set_checks_isa"}
            : "" );

        # Attribute set_strictly
        # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 149
        $self->{"set_strictly"} =
          ( exists( $args->{"set_strictly"} ) ? $args->{"set_strictly"} : "1" );

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(
/\A(?:attribute(?:_spec)?|coerce|env|ge(?:nerator_for_(?:arg[cs]?|currying|default|get|s(?:e(?:lf|t)|lot)|usage_string)|t_is_lvalue)|is(?:_method|a)|method_installer|set_(?:checks_isa|strictly)|t(?:arget|oolkit))\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    # Used by constructor to call BUILD methods
    sub BUILDALL {
        my $class = ref( $_[0] );
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        $_->(@_) for @{ $meta->{BUILD} || [] };
    }

    # Destructor should call DEMOLISH methods
    sub DESTROY {
        my $self  = shift;
        my $class = ref($self) || $self;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $in_global_destruction =
          defined ${^GLOBAL_PHASE}
          ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
          : Devel::GlobalDestruction::in_global_destruction();
        for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
            my $e = do {
                local ( $?, $@ );
                eval { $demolisher->( $self, $in_global_destruction ) };
                $@;
            };
            no warnings 'misc';    # avoid (in cleanup) warnings
            die $e if $e;          # rethrow
        }
        return;
    }

    # Gather metadata for constructor and destructor
    sub __META__ {
        no strict 'refs';
        no warnings 'once';
        my $class = shift;
        $class = ref($class) || $class;
        my $linear_isa = mro::get_linear_isa($class);
        return {
            BUILD => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::BUILD" } reverse @$linear_isa
            ],
            DEMOLISH => [
                map   { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                  map { "$_\::DEMOLISH" } @$linear_isa
            ],
            HAS_BUILDARGS        => $class->can('BUILDARGS'),
            HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for _override
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 129
    if ($__XS) {
        Class::XSAccessor->import(
            chained     => 1,
            "accessors" => { "_override" => "_override" },
        );
    }
    else {
        *_override = sub {
            @_ > 1
              ? do { $_[0]{"_override"} = $_[1]; $_[0]; }
              : ( $_[0]{"_override"} );
        };
    }

    # Accessors for attribute
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 20
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute" => "attribute" },
        );
    }
    else {
        *attribute = sub {
            @_ > 1
              ? croak("attribute is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"attribute"};
        };
    }

    # Accessors for attribute_spec
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 24
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "attribute_spec" => "attribute_spec" },
        );
    }
    else {
        *attribute_spec = sub {
            @_ > 1
              ? croak(
                "attribute_spec is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"attribute_spec"};
        };
    }

    # Accessors for coerce
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 33
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "coerce" => "coerce" },
        );
    }
    else {
        *coerce = sub {
            @_ > 1
              ? croak("coerce is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"coerce"};
        };
    }

    # Accessors for env
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 38
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "env" => "env" },
        );
    }
    else {
        *env = sub {
            @_ > 1
              ? croak("env is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"env"};
        };
    }

    # Accessors for generator_for_arg
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 71
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_arg" => "generator_for_arg" },
        );
    }
    else {
        *generator_for_arg = sub {
            @_ > 1
              ? croak(
                "generator_for_arg is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_arg"};
        };
    }

    # Accessors for generator_for_argc
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 82
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_argc" => "generator_for_argc" },
        );
    }
    else {
        *generator_for_argc = sub {
            @_ > 1
              ? croak(
                "generator_for_argc is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_argc"};
        };
    }

    # Accessors for generator_for_args
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 58
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_args" => "generator_for_args" },
        );
    }
    else {
        *generator_for_args = sub {
            @_ > 1
              ? croak(
                "generator_for_args is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_args"};
        };
    }

    # Accessors for generator_for_currying
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 95
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" =>
              { "generator_for_currying" => "generator_for_currying" },
        );
    }
    else {
        *generator_for_currying = sub {
            @_ > 1
              ? croak(
"generator_for_currying is a read-only attribute of @{[ref $_[0]]}"
              )
              : $_[0]{"generator_for_currying"};
        };
    }

    # Accessors for generator_for_default
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_default" => "generator_for_default" },
        );
    }
    else {
        *generator_for_default = sub {
            @_ > 1
              ? croak(
"generator_for_default is a read-only attribute of @{[ref $_[0]]}"
              )
              : $_[0]{"generator_for_default"};
        };
    }

    # Accessors for generator_for_get
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_get" => "generator_for_get" },
        );
    }
    else {
        *generator_for_get = sub {
            @_ > 1
              ? croak(
                "generator_for_get is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_get"};
        };
    }

    # Accessors for generator_for_self
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 121
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_self" => "generator_for_self" },
        );
    }
    else {
        *generator_for_self = sub {
            @_ > 1
              ? croak(
                "generator_for_self is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_self"};
        };
    }

    # Accessors for generator_for_set
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_set" => "generator_for_set" },
        );
    }
    else {
        *generator_for_set = sub {
            @_ > 1
              ? croak(
                "generator_for_set is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_set"};
        };
    }

    # Accessors for generator_for_slot
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 45
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "generator_for_slot" => "generator_for_slot" },
        );
    }
    else {
        *generator_for_slot = sub {
            @_ > 1
              ? croak(
                "generator_for_slot is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"generator_for_slot"};
        };
    }

    # Accessors for generator_for_usage_string
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 110
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" =>
              { "generator_for_usage_string" => "generator_for_usage_string" },
        );
    }
    else {
        *generator_for_usage_string = sub {
            @_ > 1
              ? croak(
"generator_for_usage_string is a read-only attribute of @{[ref $_[0]]}"
              )
              : $_[0]{"generator_for_usage_string"};
        };
    }

    # Accessors for get_is_lvalue
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 139
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "get_is_lvalue" => "get_is_lvalue" },
        );
    }
    else {
        *get_is_lvalue = sub {
            @_ > 1
              ? croak(
                "get_is_lvalue is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"get_is_lvalue"};
        };
    }

    # Accessors for is_method
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 134
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "is_method" => "is_method" },
        );
    }
    else {
        *is_method = sub {
            @_ > 1
              ? croak("is_method is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"is_method"};
        };
    }

    # Accessors for isa
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 29
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "isa" => "isa" },
        );
    }
    else {
        *isa = sub {
            @_ > 1
              ? croak("isa is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"isa"};
        };
    }

    # Accessors for method_installer
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 124
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "method_installer" => "method_installer" },
        );
    }
    else {
        *method_installer = sub {
            @_ > 1
              ? croak(
                "method_installer is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"method_installer"};
        };
    }

    # Accessors for set_checks_isa
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 144
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "set_checks_isa" => "set_checks_isa" },
        );
    }
    else {
        *set_checks_isa = sub {
            @_ > 1
              ? croak(
                "set_checks_isa is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"set_checks_isa"};
        };
    }

    # Accessors for set_strictly
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 149
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "set_strictly" => "set_strictly" },
        );
    }
    else {
        *set_strictly = sub {
            @_ > 1
              ? croak("set_strictly is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"set_strictly"};
        };
    }

    # Accessors for target
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 16
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "target" => "target" },
        );
    }
    else {
        *target = sub {
            @_ > 1
              ? croak("target is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"target"};
        };
    }

    # Accessors for toolkit
    # has declaration, file lib/Sub/HandlesVia/CodeGenerator.pm, line 12
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "toolkit" => "toolkit" },
        );
    }
    else {
        *toolkit = sub {
            @_ > 1
              ? croak("toolkit is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"toolkit"};
        };
    }

    1;
}
