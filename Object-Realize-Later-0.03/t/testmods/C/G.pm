package C::G;
use base 'C';

use Object::Realize::Later
  ( becomes          => 'A::B'
  , realize          => sub { bless(shift, 'A::B') }
  , warn_realization => 1
  );

sub c_g()     {'c_g'}

1;
