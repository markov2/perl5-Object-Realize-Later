package RealizedArray;
our $VERSION = 2.0;

sub new()   { bless [42, 43], shift}
sub set($$) {my ($self, $index, $value) = @_; $self->[$index] = $value}
sub get($)  {my ($self, $index) = @_; $self->[$index]}

use overload
  ( '${}'    => sub { shift->[1] }
  , '%{}'    => sub { {a=>18} }
  , '&{}'    => sub { sub {17} }
  , fallback => 1
  );

