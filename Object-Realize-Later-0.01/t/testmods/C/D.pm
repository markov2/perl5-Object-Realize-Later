package C::D;
use base 'C';

use Object::Realize::Later
  ( becomes => 'A::B'
  , realize => 'rebless'
  , warn    => 1
  );

sub rebless() { bless(shift, 'A::B') }
sub c_d()     {'c_d'}

1;
