#!/usr/bin/perl -w

#
# Test the releaze()
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 13 }

my $warntxt;
sub catchwarn {$warntxt = "@_"};

my $obj = C::D->new;
ok($obj);
ok(ref $obj eq 'C::D');

ok(not defined $warntxt);
my $new;

{   local $SIG{__WARN__} = \&catchwarn;
    $new = $obj->forceRealize;
}
ok($new);
ok($warntxt eq "Realization of C::D\n");
ok(ref $obj eq 'A::B');

$obj = C::D::E->new;
ok($obj);

undef $warntxt;
{   local $SIG{__WARN__} = \&catchwarn;
    $new = $obj->forceRealize;
}
ok($new);
ok($warntxt eq "Realization of C::D::E\n");
ok(ref $obj eq 'A::B');

ok(not defined $obj->can('C::D::E'));
ok(not defined $obj->can('C::D'));
ok(not defined $obj->can('C'));
