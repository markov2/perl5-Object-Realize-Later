package RealizedHash;
our $VERSION = 2.0;

sub new()      {bless {a=>42, b=>43}, shift}
sub set($$)    {my ($self, $key, $value) = @_; $self->{$key} = $value}
sub get($)     {my ($self, $key) = @_; $self->{$key}}

use overload
  ( '${}'    => sub { shift->{a} }
  , '@{}'    => sub { [keys %{(shift)}, 45] }
  , '&{}'    => sub { sub {17} }
  , fallback => 1
  );

