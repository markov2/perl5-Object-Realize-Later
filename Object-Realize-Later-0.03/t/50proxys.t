#!/usr/bin/perl -w

#
# Proxy as a scalar: the stub is a SCALAR reference, and the target
# object anything.
#

use strict;
use Test;

use lib 't', '.';
use Object::Realize::Proxy::SCALAR;

BEGIN { plan tests => 31 }

#
# Test from scalar to scalar
#

use StubScalar;
use RealizedScalar;
use RealizedArray;
use RealizedHash;

my $stub      = StubScalar->new;
my $scalarobj = RealizedScalar->new(42);

Object::Realize::Proxy::SCALAR->ORL_proxy_create($stub, $scalarobj);
ok(ref $stub eq 'Object::Realize::Proxy::SCALAR');

ok($stub->isa(ref $scalarobj));
ok(!$stub->isa('StubScalar'));
my $set = $stub->can('set');
ok(defined $set);
ok($stub->can('AUTOLOAD') eq \&RealizedScalar::AUTOLOAD);
ok($stub->VERSION(1.5));   # should not complain

ok($stub->set(43) == 43);
ok($stub->get == 43);
ok($stub->non_existent eq "AUTOLOAD called");

ok($$stub eq $scalarobj);  # scalar deref

ok($stub->[0] == 42);      # via overload
ok($stub->{a} == 18);      # via overload
ok($stub->()  == 17);      # via overload

#
# Test from scalar to array
#

my $arrayobj = RealizedArray->new;

Object::Realize::Proxy::SCALAR->ORL_proxy_create($stub, $arrayobj);
ok(ref $stub eq 'Object::Realize::Proxy::SCALAR');

ok($stub->isa(ref $arrayobj));
ok(!$stub->isa('StubScalar'));
ok($stub->set(2,44) == 44);
ok($stub->get(1) == 43);
ok($stub->[1] == 43);

ok(@$stub     ==  3);      # via overload
ok($stub->{a} == 18);      # via overload
ok($stub->()  == 17);      # via overload

#
# Test from scalar to hash
#

my $hashobj = RealizedHash->new;

Object::Realize::Proxy::SCALAR->ORL_proxy_create($stub, $hashobj);
ok(ref $stub eq 'Object::Realize::Proxy::SCALAR');

ok($stub->isa(ref $hashobj));
ok(!$stub->isa('StubScalar'));
ok($stub->set(c => 44) == 44);
ok($stub->get('b') == 43);
ok($stub->{b} == 43);

ok(@$stub     ==  4);      # via overload
ok($stub->[3] == 45);      # via overload
ok($stub->()  == 17);      # via overload
