use strict;
use warnings;

package Object::Realize::Proxy::ARRAY;
use base 'Object::Realize::Proxy';

=head1 NAME

 Object::Realize::Proxy::ARRAY - proxy from array to a realized object.

=head1 SYNOPSIS

 Object::Realize::Proxy->ORL_proxy_create($stub, $realized);

=head1 DESCRIPTION

See L<Object::Realize::Proxy> and L<Object::Realize::Later>.

This class handles proxy requests from an array stub object to some
realized object.  The stub-object will store a reference to the realized
object as first (and only) element in the array.

=cut

#-------------------------------------------

sub ORL_proxy_create($$)
{   my ($class, $stub, $realized) = @_;
    @$stub = ($realized);
    bless $stub, $class;
}

#-------------------------------------------

use overload  # do not overload @{}: that's already working!
  ( '${}' => sub { shift->[0] }
  , '@{}' => sub { no overload '@{}'; shift->[0] }
  , '%{}' => sub { shift->[0] }
  , '&{}' => sub { shift->[0] }
  );

#-------------------------------------------
# Stub UNIVERSAL

sub isa($)     { my $self = shift; $self->[0]->isa(@_) }
sub can($)     { my $self = shift; $self->[0]->can(@_) }
sub VERSION($) { my $self = shift; $self->[0]->VERSION(@_) }

#-------------------------------------------
# Stub AUTOLOAD

our $AUTOLOAD;
sub AUTOLOAD(@)
{   my $self = shift;
    my @path = split /\:\:/, $AUTOLOAD;
    my $call = $path[-1];

    $self->[0]->$call(@_);
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
