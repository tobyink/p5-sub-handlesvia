use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
## skip Test::Tabs

{ package Local::Dummy1; use Test::Requires { 'Moo' => '1.006' } };

use constant { true => !!1, false => !!0 };

BEGIN {
  package My::Class;
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard 'CodeRef';
  has attr => (
    is => 'rwp',
    isa => CodeRef,
    handles_via => 'Code',
    handles => {
      'my_execute' => 'execute',
      'my_execute_method' => 'execute_method',
    },
    default => sub { sub {} },
  );
};

## execute

can_ok( 'My::Class', 'my_execute' );

subtest 'Testing my_execute' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # $coderef->( 1, 2, 3 )
    $object->my_execute( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute example' );
};

## execute_method

can_ok( 'My::Class', 'my_execute_method' );

subtest 'Testing my_execute_method' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # $coderef->( $object, 1, 2, 3 )
    $object->my_execute_method( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute_method example' );
};

done_testing;
