use strict;
use warnings;

package Object::Realize::Later;

our $VERSION = '0.01';
use Carp;
use Scalar::Util;
no strict 'refs';

=head1 NAME

Object::Realize::Later - Delayed creation of objects

=head1 SYNOPSIS

  package MyLazyObject;

  use Object::Realize::Later
     becomes => 'MyRealObject',
     realize => 'load';

=head1 DESCRIPTION

The C<Object::Realize::Later> class helps with implementing transparent
on demand realization of object data.  This is related to the tricks
on autoloading of data, the lesser known cousin of autoloading of
functionality.

On demand realization is all about performance gain.  Why should you
spent costly time on realizing an object, when the data on the object is
never (or not yet) used?  In interactive programs, postponed realization
may boost start-up: the realization of objects is triggered by the
use, so spread over time.

Now there are two ways to implement lazy behaviour: you may choose to check
whether you have realized the data in each method which accesses the data,
or use the autoloading of data trick.

An implementation of the C<first solution> is:

    sub realize {
        my $self = shift;
        return $self unless $self->{_is_realized};

        # read the data from file, or whatever
        $self->{data} = ....;

        $self->{_is_realized} = 1;
        $self;
    }

    sub getData() {
        my $self = shift;
        return $self->realize->{data};
    }

The above implementation is error-prone, where you can easily forget to
call C<realize>.  The tests cannot cover all ordenings of method-calls to
detect the mistakes.

The I<second approach> uses autoloading, and is supported by this package.
First we create a stub-object, which will be transformable into a
realized object later.  This transformation is triggered by AUTOLOAD.

This stub-object may contain some methods from the realized object,
to reduce the need for realization.  The stub will also contain some
information which is required for the creation of the real object.

C<Object::Realize::Later> solves the inheritance problems (especially
the C<isa()> and C<can()> methods) and supplies the AUTOLOAD method.

=head1 USE

When you invoke (C<use>) the C<Object::Realize::Later> package, it will
add set of methods to your package (see the EXPORTS section below).

Specify the following arguments:

=over 4

=item * becomes =E<gt> CLASS

(required) Which type will this object become after realization.

=item * realize =E<gt> METHOD|CODE

(required) How will transform.  If you specify a CODE-reference, then
this will be called with the lazy-object as first argument, and the
requested method as second.

After realization, you may still have your hands on the lazy object
on various places.  Be sure that your realization method is coping
with that, for instance by using C<Memoize>.  See examples below.

=item * warn =E<gt> BOOLEAN

Print a warning message when the realization starts.  This is for
debugging purposes.  By default, this will be false.

=back

See further down in this manual-page about EXAMPLES.

=cut


=head1 EXPORTS

The following methods are added to your package:

=over 4

=cut

#-------------------------------------------

=item isa CLASS

(Class and instance method)  Is this object a (sub-)class of the specified
CLASS or can it become a (sub-)class of CLASS.

Examples:

   MyLazyObject->isa('MyRealObject')      # true
   MyLazyObject->isa('SuperClassOfLazy'); # true
   MyLazyObject->isa('SuperClassOfReal'); # true

   my $lazy = MyLazyObject->new;
   $lazy->isa('MyRealObject');            # true
   $lazy->isa('SuperClassOfLazy');        # true
   $lazy->isa('SuperClassOfReal');        # true

=cut

sub init_code($)
{   my $args    = shift;

    <<INIT_CODE;
  package $args->{class};
  require $args->{becomes};

  my \$ORL_helper_fake = bless {}, '$args->{becomes}';
INIT_CODE
}

sub isa_code($)
{   my $args    = shift;
    my $becomes = $args->{becomes};

    <<ISA_CODE;
  sub isa(\$)
  {   my (\$thing, \$what) = \@_;
      return 1 if \$thing->SUPER::isa(\$what);  # real dependency?
      \$ORL_helper_fake->isa('$becomes');
  }
ISA_CODE
}

#-------------------------------------------

=item can METHOD

(Class and instance method) Is the specified METHOD available for the
lazy or the realized version of this object?  It will return the reference
to the code.

Examples:

   MyLazyObject->can('lazyWork')      # true
   MyLazyObject->can('realWork')      # true

   my $lazy = MyLazyObject->new;
   $lazy->can('lazyWork');            # true
   $lazy->can('realWork');            # true

=cut

sub can_code($)
{   my $args = shift;
    my $becomes = $args->{becomes};

    <<CAN_CODE;
  sub can(\$)
  {   my (\$thing, \$method) = \@_;
      my \$func;
      \$func = \$thing->SUPER::can(\$method)
         and return \$func;

      \$func = \$ORL_helper_fake->can(\$method)
         or return;

      # wrap func() to trigger load if needed.
      sub {\$func->(\$thing->forceRealize, \@_)}
  }
CAN_CODE
}

#-------------------------------------------

=item AUTOLOAD

When a method is called which is not available for the lazy object, the
AUTOLOAD is called.

=cut

sub AUTOLOAD_code($)
{   my $args   = shift;

    <<AUTOLOAD_CODE;
  our \$AUTOLOAD;
  sub AUTOLOAD(\@)
  {  my \$object = shift;
     (my \$call = \$AUTOLOAD) =~ s/.*\:\://;
     return if \$call eq 'DESTROY';

     forceRealize(\$object)->\$call(\@_);
  }
AUTOLOAD_CODE
}

#-------------------------------------------

=item forceRealize

You can force the load by calling this method on your object.  It returns
the realized object.

=cut

sub realize_code($)
{   my $args   = shift;
    my $pkg    = __PACKAGE__;
    my $argspck= join "'\n         , '", %$args;

    <<REALIZE_CODE . ($args->{warn} ? <<'WARN' : '') . <<REALIZE_CODE;
  sub forceRealize(\$)
  {
REALIZE_CODE
      warn "Realization of $_[0]\n";
WARN
      ${pkg}->realize
        ( ref_object => \\\${_[0]}
        , '$argspck'
        );
  }
REALIZE_CODE
}

# This is the only code which stays in this module.
sub realize(@)
{   my ($class, %args) = @_;
    my $object = ${$args{ref_object}};
    my $realize = $args{realize};
    my $loaded  = ref $realize ? $realize->($object) : $object->$realize;

    warn "Load produces a ".ref($loaded)
       . " where a $args{becomes} is expected.\n"
           unless $loaded->isa($args{becomes});

    $loaded;
} 

#-------------------------------------------

sub import(@)
{   my ($class, %args) = @_;

    confess "Require 'becomes'" unless $args{becomes};
    confess "Require 'realize'" unless $args{realize};

    $args{class}   = caller;
    $args{warn}  ||= 0;

    my $args = \%args;
    my $eval
       = init_code($args)
       . isa_code($args)
       . can_code($args)
       . AUTOLOAD_code($args)
       . realize_code($args)
       ;
#   warn $eval;

    eval $eval;
    die $@ if $@;

    1;
}

1;

__END__

#-------------------------------------------

=back

=head1 EXAMPLES

=head2 Example 1

In the first example, we delay-load a message.  On the moment the
message is defined, we only take the location.  When the data of the
message is taken (header or body), the data is autoloaded.

  use Mail::Message::Delayed;
  use Memoize;

  use Object::Realize::Later
    ( becomes => 'Mail::Message::Real'
    , realize => 'loadMessage'
    );

  sub new($) {
      my ($class, $file) = @_;
      bless { filename => $file }, $class;
  }

  sub loadMessage() {
      my $self = shift;
      Mail::Message::Real->new($self->{filename});
  }
  memorize('loadMessage');

In the main program:

  package main;
  use Mail::Message::Delayed;

  my $msg = Mail::Message::Delayed->new('/home/user/mh/1');
  $msg->body->print;   # this will trigger autoload.

The C<Memoize> module will catch a second call to C<loadMessage> for the
same message.  Remember that you create a new object, and the old
object may still be laying around.  The C<Memorize> has as disadvantage
that the created objects will stay in your program for ever.


=head2 Example 2

Your realization may also be done by reblessing.  In that case to change the
type of your object into a different type which stores the same information.
Is that right?  Are you sure?  For simple cases, this may be possible:

  package Alive;
  use Object::Realize::Later
       becomes => 'Dead',
       realize => 'kill';

  sub new()         {my $class = shift; bless {@_}, $class}
  sub jump()        {print "Jump!\n"}
  sub showAntlers() {print "Fight!\n"}
  sub kill()        {bless(shift, 'Dead')}

  package Dead;
  sub takeAntlers() {...}

In the main program:

  my $deer   = Alive->new(Animal => 'deer');
  my $trophy = $deer->takeAntlers();

In this situation, the object (reference) is not changed but is I<reblessed>.
There is no danger that the un-realized version of the object is kept
somewhere: all variable which know about this partical I<deer> see the
change.


=head2 Example 3

This module is especially usefull for larger projects, which there is
a need for speed or memory reduction. In this case, you may have an
extra overview on which objects have been realized (transformed), and
which not.  This example is taken from the C<Mail::Box> modules:

The C<Mail::Box> module tries to boost the access-time to a folder.
If you only need the messages of the last day, why shall all be read?
So, C<Mail::Box> only creates an invertory of messages at first.  It
takes the headers of all messages, but leaves the body (content) of
the message in the file.

In C<Mail::Box>' case, the C<Mail::Message>-object has the choice
between a number of C<Mail::Message::Body>'s, one of which has only
be prepared to read the body when needed.  A code snippet:

  package Mail::Message;
  sub new($$)
  {   my ($class, $head, $body) = @_;
      bless {head => $head, body => $body}, $class;
  }
  sub head()     { shift->{head} }
  sub body()     { shift->{body} }

  sub loadBody()
  {   my $self = shift;
      my $body = $self->body;

      # Catch re-invocations of the loading.  If anywhere was still
      # a reference to the old (unrealized) body of this message, we
      # return the new-one directly.
      return $body unless $body->can('forceRealize');

      # Load the body (change it to anything which really is of
      # the promised type, or a sub-class of it.
      my ($lines, $size) = .......;    # get the data
      $self->{body} = Mail::Message::Body::Lines->new($lines, $size);

      # Return the realized object.
      return $self->{body};
  }


  package Mail::Message::Body::Lines;
  use base 'Mail::Message::Body';

  sub new($$)
  {   my ($class, $lines, $size) = @_;
      bless { lines => $lines, size => $size }, $class;
  }
  sub size()  { shift->{size} }
  sub lines() { shift->{lines} }


  package Mail::Message::Body::Delayed;
  use Object::Realize::Later
      becomes => 'Mail::Message::Body',
      realize => sub {shift->message->loadBody};

  sub new() {
      my ($class, $message, $size) = @_;
      bless {message => $message, size => $size}, $class;
  }
  sub size() { shift->{size} }


  package main;
  use Mail::Message;
  use Mail::Message::Body::Delayed;

  my $body    = Mail::Message::Body::Delayed->new(42);
  my $message = Mail::Message->new($head, $body);

  print $message->size;         # will not trigger realization!
  print $message->can('lines'); # true, but no realization
  print $message->lines;        # realizes automatically.


=head1 AUTHOR

Mark Overmeer (F<Mark@Overmeer.net>).
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
