use strict;
use warnings;

package Object::Realize::Proxy;

=head1 NAME

 Object::Realize::Proxy - proxy to realized object.

=head1 SYNOPSIS

 Object::Realize::Proxy->ORL_proxy_create($stub, $realized);

=head1 DESCRIPTION

See L<Object::Realize::Later>.

C<Object::Realize::Proxy> objects are working as a proxy from
stub objects to their realized objects, to avoid that dangling references
to the stub cause damage to the program.  Example of such case:

  package A;
  use Object::Realize::Later
      becomes => 'B',
      realize => 'load';

  sub new()   {bless {}, shift}
  sub load()  {B->new}

  package B;
  sub new()   {bless {}, shift}
  sub print() {print "Hello World!\n"}

  package main;
  my $object = A->new;
  my $second = $object;
  $object->print;

Now C<$object> will be realized, but the C<$second> reference is still
refering to the original C<A>.  To avoid this, at realization the
old reference will be reblessed into a reference to an object in this
package.

One of the harder points in the implementation is that the unrealized
and the realized objects do not have to be hashes, but may as well be
a scalar or an array.  Therefore, there are three extensions to this
module:

=over 4

=item * CLASS C<Object::Realize::Proxy::SCALAR>

=item * CLASS C<Object::Realize::Proxy::ARRAY>

=item * CLASS C<Object::Realize::Proxy::HASH>

=back

=cut

#-------------------------------------------

=head1 OVERLOADING

The proxy tries to catch overloading where it can, but it is certainly
not always successful.  Consider the following situation:

 my $i = $realizedA + $unrealizedB

In this case, Perl will not call the overload methods...

Dereferencing however, can be caught perfectly.

=cut

use overload nomethod => \&ORL_proxy_operator;
use overload fallback => 0;  # no operation rewriting allowed here

#-------------------------------------------

=head1 METHODS

There is no constructor (C<new>), because these proxy objects are
created by reblessing an existing object.

=over 4

=cut

#-------------------------------------------

=item ORL_proxy_create STUB REALIZED

Create a proxy from the STUB object to the REALIZED object.  This is
called by C<Object::Realize::Later> after the realization method has
completed.  The content of the STUB will be destroyed.

=cut

sub ORL_proxy_create($$)
{  my ($class, $stub, $realized) = @_;
   my $proxy_class = __PACKAGE__ . '::' . ref $stub;
   eval "require $proxy_class";

   if($@)
   {   use Carp;
       croak "Can not proxy objects of type ".ref($stub)."\n";
   }

   ${proxy_class}->ORL_proxy_create($stub, $realized);
}

#-------------------------------------------

=item ORL_proxy_deref

Each kind of derefencing on the object is immediately passed to the
realized object.

=cut

#-------------------------------------------

sub ORL_proxy_operator
{   croak __PACKAGE__. " does not proxy overloads (yet)";
    # If anyone can figure-out how to do that...
}

#-------------------------------------------
#
# UNIVERSAL
#

=back

=head1 Stubbing UNIVERSAL

Methods in UNIVERSAL are inherited by any package.  They must behave on
the realized object not on the stub, so are re-routed explicitly.

=over 4

=cut

#-------------------------------------------

=item isa CLASS

=cut

#-------------------------------------------

=item can METHOD

=cut

#-------------------------------------------

=item VERSION

=cut


#-------------------------------------------
#
# AUTOLOAD
#

=back

=head1 Stubbing AUTOLOAD

The stub object uses AUTOLOAD to tunnel the method-calls through to
the realized object.  This must be done carefully, because the
realized object may have a real use for AUTOLOAD...

=over 4

=cut

#-------------------------------------------

=item DESTROY

Destroys shall not progress to the realized object, so is excluded from
AUTOLOADing.  There is a good chance that the realized object is
destroyed before the stub.

=cut

sub DESTROY {}

#-------------------------------------------

=back

=head1 SEE ALSO

L<Object::Realize::Later>
L<Object::Realize::Proxy::SCALAR>
L<Object::Realize::Proxy::ARRAY>
L<Object::Realize::Proxy::HASH>

=head1 AUTHOR

Mark Overmeer (F<Mark@Overmeer.net>).
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
