package StubScalar;
our $VERSION = 1.0;

use overload '@{}' => sub { die "this is wrong\n" };

sub new() {my $a = 3; bless \$a, shift};

1;
