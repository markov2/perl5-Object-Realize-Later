package RealizedScalar;
our $VERSION = 2.0;

sub new($) {my ($class, $scalar) = @_; bless \$scalar, $class}
sub set($) {my $self = shift; $$self = shift}
sub get()  {my $self = shift; $$self}
sub AUTOLOAD() {"AUTOLOAD called"}

use overload
  ( '@{}'    => sub { [42] }
  , '%{}'    => sub { {a=>18} }
  , '&{}'    => sub { sub {17} }
  , '0+'     => sub { ${(shift)} }
  , fallback => 1
  );

