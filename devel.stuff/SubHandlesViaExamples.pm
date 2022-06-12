use strict;
use warnings;

package SubHandlesViaExamples;

our %EG;

sub add {
	my $category = shift;
	push @{ $EG{$category} ||= [] }, [ @_ ];
}

##############################################################################

add(
  'String',
  'Using eq for Enum',
  tail => 'See also L<MooX::Enumeration> and L<MooseX::Enumeration>.',
  <<'EG' );
use strict;
use warnings;

package My::Person {
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard qw( Str Enum );
  
  has name => (
    is => 'ro',
    isa => Str,
    required => 1,
  );
  
  has status => (
    is => 'rwp',
    isa => Enum[ 'alive', 'dead' ],
    handles_via => 'String',
    handles => {
      is_alive => [ eq  => 'alive' ],
      is_dead  => [ eq  => 'dead' ],
      kill     => [ set => 'dead' ],
    },
    default => 'alive',
  );
}

my $bob = My::Person->new( name => 'Robert' );
say $bob->is_alive; ## ==> true
say $bob->is_dead;  ## ==> false
$bob->kill;
say $bob->is_alive; ## ==> false
say $bob->is_dead;  ## ==> true
EG

##############################################################################

add(
  'Code',
  'Using execute_method',
  head => 'The execute_method handler allows a class to effectively provide certain methods which can be overridden by parameters in the constructor.',
  <<'EG' );
use strict;
use warnings;
use Data::Dumper;

package My::Processor {
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard qw( Str CodeRef );
  
  has name => (
    is => 'ro',
    isa => Str,
    default => 'Main Process',
  );
  
  my $NULL_CODEREF = sub {};
  
  has _debug => (
    is => 'ro',
    isa => CodeRef,
    handles_via => 'Code',
    handles => { debug => 'execute_method' },
    default => sub { $NULL_CODEREF },
    init_arg => 'debug',
  );
  
  sub _do_stuff {
    my $self = shift;
    $self->debug( 'continuing process' );
    return;
  }
  
  sub run_process {
    my $self = shift;
    $self->debug( 'starting process' );
    $self->_do_stuff;
    $self->debug( 'ending process' );
  }
}

my $p1 = My::Processor->new( name => 'First Process' );
$p1->run_process; # no output

my @got;
my $p2 = My::Processor->new(
  name => 'Second Process',
  debug => sub {
    my ( $processor, $message ) = @_;
    push @got, sprintf( '%s: %s', $processor->name, $message );
  },
);
$p2->run_process; # logged output

my @expected = (
  'Second Process: starting process',
  'Second Process: continuing process',
  'Second Process: ending process',
);
say Dumper( \@got ); ## ==> \@expected
EG

##############################################################################

1;
