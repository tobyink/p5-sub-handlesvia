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
  'Curried match',
  <<'EG' );
use strict;
use warnings;

package My::Component {
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard qw( Str Int );
  
  has id => (
    is => 'ro',
    isa => Int,
    required => 1,
  );
  
  has name => (
    is => 'ro',
    isa => Str,
    required => 1,
    handles_via => 'String',
    handles => {
      name_is_safe_filename => [ match => qr/\A[A-Za-z0-9]+\z/ ],
      _lc_name => 'lc',
    },
  );
  
  sub config_filename {
    my $self = shift;
    if ( $self->name_is_safe_filename ) {
      return sprintf( '%s.ini', $self->_lc_name );
    }
    return sprintf( 'component-%d.ini', $self->id );
  }
}

my $foo = My::Component->new( id => 42, name => 'Foo' );
say $foo->config_filename; ## ==> 'foo.ini'

my $bar4 = My::Component->new( id => 99, name => 'Bar #4' );
say $bar4->config_filename; ## ==> 'component-99.ini'
EG

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

add(
  'Array',
  'Using for_each',
  <<'EG' );
use strict;
use warnings;

package My::Plugin {
  use Moo::Role;
  sub initialize {}
  sub finalize {}
}

package My::Processor {
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard qw( ArrayRef ConsumerOf );
  
  has plugins => (
    is => 'ro',
    isa => ArrayRef[ ConsumerOf['My::Plugin'] ],
    handles_via => 'Array',
    handles => {
      add_plugin => 'push',
      plugin_do => 'for_each',
    },
    default => sub { [] },
  );
  
  sub _do_stuff {
    return;
  }
  
  sub run_process {
    my ( $self, @args ) = @_;
    $self->plugin_do( sub {
      my $plugin = shift;
      $plugin->initialize( $self, @args );
    } );
    $self->_do_stuff( @args );
    $self->plugin_do( sub {
      my $plugin = shift;
      $plugin->finalize( $self, @args );
    } );
  }
}

my $p = My::Processor->new();

package My::Plugin::Noisy {
  use Moo; with 'My::Plugin';
  sub initialize {
    my ( $self, $processor, @args ) = @_;
    say "initialize @args"; #::# ==> 'initialize 1 2 3'
  }
  sub finalize {
    my ( $self, $processor, @args ) = @_;
    say "finalize @args"; #::# ==> 'finalize 1 2 3'
  }
}

$p->add_plugin( My::Plugin::Noisy->new );

$p->run_process( 1, 2, 3 );
EG

##############################################################################

1;
