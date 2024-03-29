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

{
    my %handles = (
        count    => 'count',
        elements => 'elements',
        is_empty => 'is_empty',
        push     => 'push',
        push_curried =>
            [ push => 42, 84 ],
        unshift => 'unshift',
        unshift_curried =>
            [ unshift => 42, 84 ],
        pop           => 'pop',
        shift         => 'shift',
        get           => 'get',
        get_curried   => [ get => 1 ],
        set           => 'set',
        set_curried_1 => [ set => 1 ],
        set_curried_2 => [ set => ( 1, 98 ) ],
        accessor      => 'accessor',
        accessor_curried_1 => [ accessor => 1 ],
        accessor_curried_2 => [ accessor => ( 1, 90 ) ],
        clear          => 'clear',
        delete         => 'delete',
        delete_curried => [ delete => 1 ],
        insert         => 'insert',
        insert_curried => [ insert => ( 1, 101 ) ],
        splice         => 'splice',
        splice_curried_1   => [ splice => 1 ],
        splice_curried_2   => [ splice => 1, 2 ],
        splice_curried_all => [ splice => 1, 2, ( 3, 4, 5 ) ],
        sort          => 'sort',
        sort_curried  => [ sort => ( sub { $_[1] <=> $_[0] } ) ],
        sort_in_place => 'sort_in_place',
        sort_in_place_curried =>
            [ sort_in_place => ( sub { $_[1] <=> $_[0] } ) ],
        map           => 'map',
        map_curried   => [ map => ( sub { $_ + 1 } ) ],
        grep          => 'grep',
        grep_curried  => [ grep => ( sub { $_ < 5 } ) ],
        first         => 'first',
        first_curried => [ first => ( sub { $_ % 2 } ) ],
        first_index   => 'first_index',
        first_index_curried => [ first_index => ( sub { $_ % 2 } ) ],
        join          => 'join',
        join_curried => [ join => '-' ],
        shuffle      => 'shuffle',
        uniq         => 'uniq',
        reduce       => 'reduce',
        reduce_curried => [ reduce => ( sub { $_[0] * $_[1] } ) ],
        natatime       => 'natatime',
        natatime_curried => [ natatime => 2 ],
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

        my @traits = 'Array';
#        push @traits, 'NoInlineAttribute'
#            if delete $attr{no_inline};

eval qq{
        package $class;
		  use Moose;
		  use Sub::HandlesVia;
		  has _values => (
                traits  => [\@traits],
                is      => 'rw',
                isa     => 'ArrayRef[Int]',
                default => sub { [] },
                handles => \\%handles_copy,
                clearer => '_clear_values',
                %attr,
        );
		  sub class_is_lazy { \$attr{lazy} }
		  1;
	  } or die($@);
        return ( $class, \%handles );
    }
}

{
    package Overloader;

    use overload
        '&{}' => sub { ${ $_[0] } },
        bool  => sub {1};

    sub new {
        bless \$_[1], $_[0];
    }
}

{
    package OverloadStr;
    use overload
        q{""} => sub { ${ $_[0] } },
        fallback => 1;

    sub new {
        my $class = shift;
        my $str   = shift;
        return bless \$str, $class;
    }
}

{
    package OverloadNum;
    use overload
        q{0+} => sub { ${ $_[0] } },
        fallback => 1;

    sub new {
        my $class = shift;
        my $str   = shift;
        return bless \$str, $class;
    }
}

{
use Moose::Util::TypeConstraints;
    subtest( 'simple case', sub { run_tests(build_class) } );
    subtest(
        'lazy default attr',
        sub {
            run_tests(
                build_class( lazy => 1, default => sub { [ 42, 84 ] } ) );
        }
    );

    subtest(
        'attr with trigger',
        sub {
            run_tests( build_class( trigger => sub { } ) );
        }
    );
    subtest(
        'attr is not inlined',
        sub { run_tests( build_class( no_inline => 1 ) ) }
    );


    type 'MyArray', as 'ArrayRef', where { 1 };
    subtest(
        'attr type forces the inlining code to check the entire arrayref when it is modified',
        sub {
            run_tests( build_class( isa => 'MyArray') );
        }
    );

    coerce 'MyArray', from 'ArrayRef', via { $_ };
    subtest(
        'attr type has coercion',
        sub {
            run_tests( build_class( isa => 'MyArray', coerce => 1 ) );
        }
    );
}

subtest(
    'setting value to undef with accessor',
    sub {			
        my ( $class, $handles ) = build_class( isa => 'ArrayRef' );

note "Testing class $class";

        my $obj = $class->new;
        with_immutable {
            is(
                exception { $obj->accessor( 0, undef ) },
                undef,
                'can use accessor to set value to undef'
            );
            is(
                exception { $obj->accessor_curried_1(undef) },
                undef,
                'can use curried accessor to set value to undef'
            );
        }
        $class;
    }
);

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    with_immutable {
        my $obj = $class->new( _values => [ 10, 12, 42 ] );

        is_deeply(
            $obj->_values, [ 10, 12, 42 ],
            'values can be set in constructor'
        );

        ok( !$obj->is_empty, 'values is not empty' );
        is( $obj->count, 3, 'count returns 3' );

        like( exception { $obj->count(22) }, qr/number of parameters/, 'throws an error when passing an argument passed to count' );

        is( exception { $obj->push( 1, 2, 3 ) }, undef, 'pushed three new values and lived' );

        is( exception { $obj->push() }, undef, 'call to push without arguments lives' );

        is( exception {
            is( $obj->unshift( 101, 22 ), 8,
                'unshift returns size of the new array' );
        }, undef, 'unshifted two values and lived' );

        is_deeply(
            $obj->_values, [ 101, 22, 10, 12, 42, 1, 2, 3 ],
            'unshift changed the value of the array in the object'
        );

        is( exception { $obj->unshift() }, undef, 'call to unshift without arguments lives' );

        is( $obj->pop, 3, 'pop returns the last value in the array' );

        is_deeply(
            $obj->_values, [ 101, 22, 10, 12, 42, 1, 2 ],
            'pop changed the value of the array in the object'
        );

        like( exception { $obj->pop(42) }, qr/number of parameters/, 'call to pop with arguments dies' );

        is( $obj->shift, 101, 'shift returns the first value' );

        like( exception { $obj->shift(42) }, qr/number of parameters/, 'call to shift with arguments dies' );

        is_deeply(
            $obj->_values, [ 22, 10, 12, 42, 1, 2 ],
            'shift changed the value of the array in the object'
        );

        is_deeply(
            [ $obj->elements ], [ 22, 10, 12, 42, 1, 2 ],
            'call to elements returns values as a list'
        );

        is(scalar($obj->elements), 6, 'elements accessor in scalar context returns the number of elements in the list');

        like( exception { $obj->elements(22) }, qr/number of parameters/, 'throws an error when passing an argument passed to elements' );

        $obj->_values( [ 1, 2, 3 ] );

        is( $obj->get(0),      1, 'get values at index 0' );
        is( $obj->get(1),      2, 'get values at index 1' );
        is( $obj->get(2),      3, 'get values at index 2' );
        is( $obj->get_curried, 2, 'get_curried returns value at index 1' );

        like( exception { $obj->get() }, qr/number of parameters/, 'throws an error when get is called without any arguments' );

        like( exception { $obj->get( {} ) }, qr/did not pass type constraint/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get(2.2) }, qr/did not pass type constraint/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get('foo') }, qr/did not pass type constraint/, 'throws an error when get is called with an invalid argument' );

        like( exception { $obj->get_curried(2) }, qr/number of parameters/, 'throws an error when get_curried is called with an argument' );

        is( exception {
            is( $obj->set( 1, 100 ), 100, 'set returns new value' );
        }, undef, 'set value at index 1 lives' );

        is( $obj->get(1), 100, 'get value at index 1 returns new value' );


        like( exception { $obj->set( 1, 99, 42 ) }, qr/number of parameters/, 'throws an error when set is called with three arguments' );

        is( exception { $obj->set_curried_1(99) }, undef, 'set_curried_1 lives' );

        is( $obj->get(1), 99, 'get value at index 1 returns new value' );

        like( exception { $obj->set_curried_1( 99, 42 ) }, qr/number of parameters/, 'throws an error when set_curried_1 is called with two arguments' );

        is( exception { $obj->set_curried_2 }, undef, 'set_curried_2 lives' );

        is( $obj->get(1), 98, 'get value at index 1 returns new value' );

        like( exception { $obj->set_curried_2(42) }, qr/number of parameters/, 'throws an error when set_curried_2 is called with one argument' );
#use B::Deparse;
#diag(B::Deparse->new->coderef2text($obj->can('accessor')));
        is(
            $obj->accessor(1), 98,
            'accessor with one argument returns value at index 1'
        );

        is( exception {
            is( $obj->accessor( 1 => 97 ), 97, 'accessor returns new value' );
        }, undef, 'accessor as writer lives' );

        like(
            exception {
                $obj->accessor;
            },
            qr/number of parameters/,
            'throws an error when accessor is called without arguments'
        );

        is(
            $obj->get(1), 97,
            'accessor set value at index 1'
        );

        like( exception { $obj->accessor( 1, 96, 42 ) }, qr/number of parameters/, 'throws an error when accessor is called with three arguments' );

        is(
            $obj->accessor_curried_1, 97,
            'accessor_curried_1 returns expected value when called with no arguments'
        );

        is( exception { $obj->accessor_curried_1(95) }, undef, 'accessor_curried_1 as writer lives' );

        is(
            $obj->get(1), 95,
            'accessor_curried_1 set value at index 1'
        );

        like( exception { $obj->accessor_curried_1( 96, 42 ) }, qr/number of parameters/, 'throws an error when accessor_curried_1 is called with two arguments' );

        is( exception { $obj->accessor_curried_2 }, undef, 'accessor_curried_2 as writer lives' );

        is(
            $obj->get(1), 90,
            'accessor_curried_2 set value at index 1'
        );

        like( exception { $obj->accessor_curried_2(42) }, qr/number of parameters/, 'throws an error when accessor_curried_2 is called with one argument' );

        is( exception { $obj->clear }, undef, 'clear lives' );

        ok( $obj->is_empty, 'values is empty after call to clear' );

        is( exception {
            is( $obj->shift, undef,
                'shift returns undef on an empty array' );
        }, undef, 'shifted from an empty array and lived' );

        $obj->set( 0 => 42 );

        like( exception { $obj->clear(50) }, qr/number of parameters/, 'throws an error when clear is called with an argument' );

        ok(
            !$obj->is_empty,
            'values is not empty after failed call to clear'
        );

        like( exception { $obj->is_empty(50) }, qr/number of parameters/, 'throws an error when is_empty is called with an argument' );

        $obj->clear;
        is(
            $obj->push( 1, 5, 10, 42 ), 4,
            'pushed 4 elements, got number of elements in the array back'
        );

        is( exception {
            is( $obj->delete(2), 10, 'delete returns deleted value' );
        }, undef, 'delete lives' );

        is_deeply(
            $obj->_values, [ 1, 5, 42 ],
            'delete removed the specified element'
        );

        like( exception { $obj->delete( 2, 3 ) }, qr/number of parameters/, 'throws an error when delete is called with two arguments' );

        is( exception { $obj->delete_curried }, undef, 'delete_curried lives' );

        is_deeply(
            $obj->_values, [ 1, 42 ],
            'delete removed the specified element'
        );

        like( exception { $obj->delete_curried(2) }, qr/number of parameters/, 'throws an error when delete_curried is called with one argument' );

        is( exception { $obj->insert( 1, 21 ) }, undef, 'insert lives' );

        is_deeply(
            $obj->_values, [ 1, 21, 42 ],
            'insert added the specified element'
        );

        like( exception { $obj->insert( 1, 22, 44 ) }, qr/number of parameters/, 'throws an error when insert is called with three arguments' );

        is( exception {
            is_deeply(
                [ $obj->splice( 1, 0, 2, 3 ) ],
                [],
                'return value of splice is empty list when not removing elements'
            );
        }, undef, 'splice lives' );

        is_deeply(
            $obj->_values, [ 1, 2, 3, 21, 42 ],
            'splice added the specified elements'
        );

        is( exception {
            is_deeply(
                [ $obj->splice( 1, 2, 99 ) ],
                [ 2, 3 ],
                'splice returns list of removed values'
            );
        }, undef, 'splice lives' );

        is_deeply(
            $obj->_values, [ 1, 99, 21, 42 ],
            'splice added the specified elements'
        );

        like( exception { $obj->splice() }, qr/number of parameters/, 'throws an error when splice is called with no arguments' );

        like( exception { $obj->splice( 1, 'foo', ) }, qr/did not pass type constraint/, 'throws an error when splice is called with an invalid length' );

        is( exception { $obj->splice_curried_1( 2, 101 ) }, undef, 'splice_curried_1 lives' );

        is_deeply(
            $obj->_values, [ 1, 101, 42 ],
            'splice added the specified elements'
        );

        is( exception { $obj->splice_curried_2(102) }, undef, 'splice_curried_2 lives' );

        is_deeply(
            $obj->_values, [ 1, 102 ],
            'splice added the specified elements'
        );

        is( exception { $obj->splice_curried_all }, undef, 'splice_curried_all lives' );

        is_deeply(
            $obj->_values, [ 1, 3, 4, 5 ],
            'splice added the specified elements'
        );

        is_deeply(
            scalar $obj->splice( 1, 2 ),
            4,
            'splice in scalar context returns last element removed'
        );

        is_deeply(
            scalar $obj->splice( 1, 0, 42 ),
            undef,
            'splice in scalar context returns undef when no elements are removed'
        );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        is_deeply(
            [ $obj->sort ], [ 11, 22, 3, 5, 9 ],
            'sort returns sorted values'
        );

        is(scalar($obj->sort), 5, 'sort accessor in scalar context returns the number of elements in the list');

        is_deeply(
            [ $obj->sort( sub { $_[0] <=> $_[1] } ) ], [ 3, 5, 9, 11, 22 ],
            'sort returns values sorted by provided function'
        );

        is(scalar($obj->sort( sub { $_[0] <=> $_[1] } )), 5, 'sort accessor with sort sub in scalar context returns the number of elements in the list');

        like( exception { $obj->sort(1) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to sort' );

        like( exception {
            $obj->sort( sub { }, 27 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to sort' );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        $obj->sort_in_place;

        is_deeply(
            $obj->_values, [ 11, 22, 3, 5, 9 ],
            'sort_in_place sorts values'
        );

        $obj->sort_in_place( sub { $_[0] <=> $_[1] } );

        is_deeply(
            $obj->_values, [ 3, 5, 9, 11, 22 ],
            'sort_in_place with function sorts values'
        );

        like( exception {
            $obj->sort_in_place( 27 );
        }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to sort_in_place' );

        like( exception {
            $obj->sort_in_place( sub { }, 27 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to sort_in_place' );

        $obj->_values( [ 3, 9, 5, 22, 11 ] );

        $obj->sort_in_place_curried;

        is_deeply(
            $obj->_values, [ 22, 11, 9, 5, 3 ],
            'sort_in_place_curried sorts values'
        );

        like( exception { $obj->sort_in_place_curried(27) }, qr/number of parameters/, 'throws an error when passing one argument passed to sort_in_place_curried' );

        $obj->_values( [ 1 .. 5 ] );

        is_deeply(
            [ $obj->map( sub { $_ + 1 } ) ],
            [ 2 .. 6 ],
            'map returns the expected values'
        );

        like( exception { $obj->map }, qr/number of parameters/, 'throws an error when passing no arguments to map' );

        like( exception {
            $obj->map( sub { }, 2 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to map' );

        like( exception { $obj->map( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to map' );

        $obj->_values( [ 1 .. 5 ] );

        is_deeply(
            [ $obj->map_curried ],
            [ 2 .. 6 ],
            'map_curried returns the expected values'
        );

        like( exception {
            $obj->map_curried( sub { } );
        }, qr/number of parameters/, 'throws an error when passing one argument passed to map_curried' );

        $obj->_values( [ 2 .. 9 ] );

        is_deeply(
            [ $obj->grep( sub { $_ < 5 } ) ],
            [ 2 .. 4 ],
            'grep returns the expected values'
        );

        like( exception { $obj->grep }, qr/number of parameters/, 'throws an error when passing no arguments to grep' );

        like( exception {
            $obj->grep( sub { }, 2 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to grep' );

        like( exception { $obj->grep( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to grep' );

#        my $overloader = Overloader->new( sub { $_ < 5 } );
#        is_deeply(
#            [ $obj->grep($overloader) ],
#            [ 2 .. 4 ],
#            'grep works with obj that overload code dereferencing'
#        );

        is_deeply(
            [ $obj->grep_curried ],
            [ 2 .. 4 ],
            'grep_curried returns the expected values'
        );

        like( exception {
            $obj->grep_curried( sub { } );
        }, qr/number of parameters/, 'throws an error when passing one argument passed to grep_curried' );

        $obj->_values( [ 2, 4, 22, 99, 101, 6 ] );

        is(
            $obj->first( sub { $_ % 2 } ),
            99,
            'first returns expected value'
        );

        like( exception { $obj->first }, qr/number of parameters/, 'throws an error when passing no arguments to first' );

        like( exception {
            $obj->first( sub { }, 2 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to first' );

        like( exception { $obj->first( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to first' );

        is(
            $obj->first_curried,
            99,
            'first_curried returns expected value'
        );

        like( exception {
            $obj->first_curried( sub { } );
        }, qr/number of parameters/, 'throws an error when passing one argument passed to first_curried' );


        is(
            $obj->first_index( sub { $_ % 2 } ),
            3,
            'first_index returns expected value'
        );

        like( exception { $obj->first_index }, qr/number of parameters/, 'throws an error when passing no arguments to first_index' );

        like( exception {
            $obj->first_index( sub { }, 2 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to first_index' );

        like( exception { $obj->first_index( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to first_index' );

        is(
            $obj->first_index_curried,
            3,
            'first_index_curried returns expected value'
        );

        like( exception {
            $obj->first_index_curried( sub { } );
        }, qr/number of parameters/, 'throws an error when passing one argument passed to first_index_curried' );


        $obj->_values( [ 1 .. 4 ] );

        is(
            $obj->join('-'), '1-2-3-4',
            'join returns expected result'
        );

        is(
            $obj->join(q{}), '1234',
            'join returns expected result when joining with empty string'
        );

        is(
            $obj->join(0), '1020304',
            'join returns expected result when joining with 0 as number'
        );

        is(
            $obj->join("0"), '1020304',
            'join returns expected result when joining with 0 as string'
        );

#        is(
#            $obj->join( OverloadStr->new(q{}) ), '1234',
#            'join returns expected result when joining with object with string overload'
#        );
#
#        is(
#            $obj->join( OverloadNum->new(0) ), '1020304',
#            'join returns expected result when joining with object with numify overload'
#        );

#        like( exception { $obj->join }, qr/number of parameters/, 'throws an error when passing no arguments to join' );

        like( exception { $obj->join( '-', 2 ) }, qr/number of parameters/, 'throws an error when passing two arguments to join' );

        like( exception { $obj->join( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non string to join' );

        is_deeply(
            [ sort $obj->shuffle ],
            [ 1 .. 4 ],
            'shuffle returns all values (cannot check for a random order)'
        );

        like( exception { $obj->shuffle(2) }, qr/number of parameters/, 'throws an error when passing an argument passed to shuffle' );

        $obj->_values( [ 1 .. 4, 2, 5, 3, 7, 3, 3, 1 ] );

        is_deeply(
            [ $obj->uniq ],
            [ 1 .. 4, 5, 7 ],
            'uniq returns expected values (in original order)'
        );

        like( exception { $obj->uniq(2) }, qr/number of parameters/, 'throws an error when passing an argument passed to uniq' );

        $obj->_values( [ 1 .. 5 ] );

        is(
            $obj->reduce( sub { $_[0] * $_[1] } ),
            120,
            'reduce returns expected value'
        );

        like( exception { $obj->reduce }, qr/number of parameters/, 'throws an error when passing no arguments to reduce' );

        like( exception {
            $obj->reduce( sub { }, 2 );
        }, qr/number of parameters/, 'throws an error when passing two arguments to reduce' );

        like( exception { $obj->reduce( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non coderef to reduce' );

        is(
            $obj->reduce_curried,
            120,
            'reduce_curried returns expected value'
        );

        like( exception {
            $obj->reduce_curried( sub { } );
        }, qr/number of parameters/, 'throws an error when passing one argument passed to reduce_curried' );

        $obj->_values( [ 1 .. 6 ] );

        my $it = $obj->natatime(2);
        my @nat;
        while ( my @v = $it->() ) {
            push @nat, \@v;
        }

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime returns expected iterator'
        ) or diag(explain(\@nat));

        @nat = ();
        $obj->natatime( 2, sub { push @nat, [@_] } );

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime with function returns expected value'
        );

        like( exception { $obj->natatime( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non integer to natatime' );

        like( exception { $obj->natatime( 2, {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non code ref to natatime' );

        $it = $obj->natatime_curried();
        @nat = ();
        while ( my @v = $it->() ) {
            push @nat, \@v;
        }

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime_curried returns expected iterator'
        );

        @nat = ();
        $obj->natatime_curried( sub { push @nat, [@_] } );

        is_deeply(
            [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
            \@nat,
            'natatime_curried with function returns expected value'
        );

        like( exception { $obj->natatime_curried( {} ) }, qr/did not pass type constraint/, 'throws an error when passing a non code ref to natatime_curried' );

        if ( $class->meta->get_attribute('_values')->is_lazy ) {
            my $obj = $class->new;

            is( $obj->count, 2, 'count is 2 (lazy init)' );

            $obj->_clear_values;

            is_deeply(
                [ $obj->elements ], [ 42, 84 ],
                'elements contains default with lazy init'
            );

            $obj->_clear_values;

            $obj->push(2);

            is_deeply(
                $obj->_values, [ 42, 84, 2 ],
                'push works with lazy init'
            );

            $obj->_clear_values;

            $obj->unshift( 3, 4 );

            is_deeply(
                $obj->_values, [ 3, 4, 42, 84 ],
                'unshift works with lazy init'
            );
        }
    }
    $class;
}

done_testing;
