use strict;
use warnings;

package Object::Realize::Proxy::SCALAR;
use base 'Object::Realize::Proxy';

=head1 NAME

 Object::Realize::Proxy::SCALAR - proxy from Scalar to a realized object.

=head1 SYNOPSIS

 Object::Realize::Proxy->ORL_proxy_create($stub, $realized);

=head1 DESCRIPTION

See L<Object::Realize::Proxy> and L<Object::Realize::Later>.

This class handles proxy requests from a scalar stub object to some
realized object.  The stub-object is a scalar, so where can we store
the information about the realized object?  Well: overwrite the scalar
value, of course.

=cut

#-------------------------------------------

sub ORL_proxy_create($$)
{   my ($class, $stub, $realized) = @_;
    $$stub = $realized;
    bless $stub, $class;
}

#-------------------------------------------

use overload  # do not overload ${}: that's already working!
  ( '@{}' => sub { ${(shift)} }
  , '%{}' => sub { ${(shift)} }
  , '&{}' => sub { ${(shift)} }
  );

#-------------------------------------------
# Stub UNIVERSAL

sub isa($)     { my $self = shift; $$self->isa(@_) }
sub can($)     { my $self = shift; $$self->can(@_) }
sub VERSION($) { my $self = shift; $$self->VERSION(@_) }

#-------------------------------------------
# Stub AUTOLOAD

our $AUTOLOAD;
sub AUTOLOAD(@)
{   my $self = shift;
    my @path = split /\:\:/, $AUTOLOAD;
    my $call = $path[-1];

    $$self->$call(@_);
}
 
#-------------------------------------------

=head1 SEE ALSO

L<Object::Realize::Later>
L<Object::Realize::Proxy>

=head1 AUTHOR

Mark Overmeer (F<Mark@Overmeer.net>).
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
