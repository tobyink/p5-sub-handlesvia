use strict;
use warnings;

## skip Test::Tabs

use lib 't/lib';

{ package Local::Dummy1; use Test::Requires 'Moose' };

#use Moose ();
#use Moose::Util::TypeConstraints;
#use NoInlineAttribute;
use Test::More;
use Test::Fatal;
use Test::Moose;

use Types::Standard ();

{
    my %handles = (
        inc_counter    => 'inc',
        inc_counter_2  => [ inc => 2 ],
        dec_counter    => 'dec',
        dec_counter_2  => [ dec => 2 ],
        reset_counter  => 'reset',
        set_counter    => 'set',
        set_counter_42 => [ set => 42 ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;
        my %handles_copy = %handles;
         my $class = ++$name;
#        my $class = Moose::Meta::Class->create(
#            $name++,
#            superclasses => ['Moose::Object'],
#        );

        my @traits = 'Counter';
#        push @traits, 'NoInlineAttribute'
#            if delete $attr{no_inline};

eval qq{
        package $class;
		  use Moose;
		  use Sub::HandlesVia;
		  use Types::Standard qw(Int);
		  has counter => (
                traits  => [\@traits],
                is      => 'rw',
                isa     => Int,
                default => 0,
                handles => \\%handles_copy,
                clearer => '_clear_counter',
                %attr,
        );
		  sub class_is_lazy { \$attr{lazy} }
		  1;
	  } or die($@);
        return ( $class, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1 ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    run_tests( build_class( isa => Types::Standard::Int()->where(sub {1}) ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

note "Testing class $class";

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new();

        is( $obj->counter, 0, '... got the default value' );

        is( $obj->inc_counter, 1, 'inc returns new value' );
        is( $obj->counter, 1, '... got the incremented value' );

        is( $obj->inc_counter, 2, 'inc returns new value' );
        is( $obj->counter, 2, '... got the incremented value (again)' );

        like( exception { $obj->inc_counter( 1, 2 ) }, qr/number of parameters/, 'inc throws an error when two arguments are passed' );

        is( $obj->dec_counter, 1, 'dec returns new value' );
        is( $obj->counter, 1, '... got the decremented value' );

        like( exception { $obj->dec_counter( 1, 2 ) }, qr/number of parameters/, 'dec throws an error when two arguments are passed' );

        is( $obj->reset_counter, 0, 'reset returns new value' );
        is( $obj->counter, 0, '... got the original value' );

        like( exception { $obj->reset_counter(2) }, qr/number of parameters/, 'reset throws an error when an argument is passed' );

        is( $obj->set_counter(5), 5, 'set returns new value' );
        is( $obj->counter, 5, '... set the value' );

        like( exception { $obj->set_counter( 1, 2 ) }, qr/number of parameters/, 'set throws an error when two arguments are passed' );

        $obj->inc_counter(2);
        is( $obj->counter, 7, '... increment by arg' );

        $obj->dec_counter(5);
        is( $obj->counter, 2, '... decrement by arg' );

        $obj->inc_counter_2;
        is( $obj->counter, 4, '... curried increment' );

        $obj->dec_counter_2;
        is( $obj->counter, 2, '... curried deccrement' );

        $obj->set_counter_42;
        is( $obj->counter, 42, '... curried set' );

        if ( $class->class_is_lazy ) {
            my $obj = $class->new;

            $obj->inc_counter;
            is( $obj->counter, 1, 'inc increments - with lazy default' );

            $obj->_clear_counter;

            $obj->dec_counter;
            is( $obj->counter, -1, 'dec decrements - with lazy default' );
        }
    }
    $class;
}

{
    package WithBuilder;
    use Moose;
	 use Sub::HandlesVia;
	 use Types::Standard 'Int';

    has nonlazy => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => Int,
        builder => '_builder',
        handles => {
            reset_nonlazy => 'reset',
        },
    );

    has lazy => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => Int,
        lazy    => 1,
        builder => '_builder',
        handles => {
            reset_lazy => 'reset',
        },
    );

    sub _builder { 1 }
}

for my $attr ('lazy', 'nonlazy') {
    my $obj = WithBuilder->new;
    is($obj->$attr, 1, "built properly");
    $obj->$attr(0);
    is($obj->$attr, 0, "can be manually set");
    $obj->${\"reset_$attr"};
    is($obj->$attr, 1, "reset resets it to its default value");
}

done_testing;
