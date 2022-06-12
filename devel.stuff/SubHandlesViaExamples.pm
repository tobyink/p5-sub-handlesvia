package SubHandlesViaExamples;
use strict;
use warnings;

our %EG;
sub add {
	my $category = shift;
	push @{ $EG{$category} ||= [] }, [ @_ ];
}

add(
  'String',
  'Using eq for Enum',
  tail => 'See also L<MooX::Enumeration> and L<MooseX::Enumeration>.',
  <<'EG' );
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

1;
