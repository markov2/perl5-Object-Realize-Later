package RealizedScalar;
our $VERSION = 2.0;

sub new()  {my $scalar = 42; bless \$scalar, shift}
sub set($) {my $self = shift; $$self = shift}
sub get()  {my $self = shift; $$self}
sub AUTOLOAD() {"AUTOLOAD called"}

use overload
  ( '@{}'    => sub { [42] }
  , '%{}'    => sub { {a=>18} }
  , '&{}'    => sub { sub {17} }
  , fallback => 1
  );

