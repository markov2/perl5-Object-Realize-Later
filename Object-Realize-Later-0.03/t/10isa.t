#!/usr/bin/perl -w

#
# Test the isa() relations
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 21 }

my $obj = C::D->new;
ok($obj);

ok($obj->isa('C'));
ok($obj->isa('C::D::E'));  # Also extentions will be accepted.
ok($obj->isa('A::B'));
ok($obj->isa('A'));

ok(C::D::E->isa('C::D::E'));
ok(C::D::E->isa('C::D'));
ok(C::D::E->isa('C'));
ok(C::D->isa('C::D'));
ok(C::D->isa('C'));
ok(C->isa('C'));

ok(C::D::E->isa('A::B'));
ok(C::D::E->isa('A'));
ok(C::D->isa('A::B'));
ok(C::D->isa('A'));
ok(not C->isa('A::B'));
ok(not C->isa('A'));

ok(not A::B->isa('C::D'));
ok(not A::B->isa('C'));
ok(not A->isa('C::D'));
ok(not A->isa('C'));
