use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::HandlerLibrary::Scalar;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.018';

use Sub::HandlesVia::HandlerLibrary;
our @ISA = 'Sub::HandlesVia::HandlerLibrary';

use Sub::HandlesVia::Handler qw( handler );
our @METHODS = qw( scalar_reference );

sub scalar_reference {
	handler
		name      => 'Scalar:scalar_reference',
		args      => 0,
		template  => '$GET;\\($SLOT)',
		documentation => "Returns a scalar reference to the attribute value's slot within its object.",
		_examples => sub {
			my ( $class, $attr, $method ) = @_;
			return CORE::join "",
				"  my \$object = $class\->new( $attr => 10 );\n",
				"  my \$ref = \$object->$method;\n",
				"  \$\$ref++;\n",
				"  say \$object->$attr; ## ==> 11\n",
				"\n";
		},
}

1;
