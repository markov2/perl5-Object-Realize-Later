#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Object::Realize::Later;

use Log::Report 'object-release-later';

use Scalar::Util qw/weaken/;

use warnings;
use strict;
no strict 'refs';

#--------------------
=chapter NAME

Object::Realize::Later - Delayed creation of objects

=chapter SYNOPSIS

  package MyLazyObject;

  use Object::Realize::Later
     becomes => 'MyRealObject',
     realize => 'load';

=chapter DESCRIPTION

The C<Object::Realize::Later> class helps with implementing transparent
on demand realization of object data.  This is related to the tricks
on autoloading of data, the lesser known cousin of autoloading of
functionality.

This module versions 4.0 and up is not fully compatible with older releases:
mainly the exception handling has changed.  When you need to upgrade, please
read F<https://github.com/markov2/perl5-Mail-Box/wiki/>
B<Version 3 is still maintained> and may see new releases as well.

On demand realization is all about performance gain.  Why should you
spent costly time on realizing an object, when the data on the object is
never (or not yet) used?  In interactive programs, postponed realization
may boost start-up: the realization of objects is triggered by the
use, so spread over time.

=chapter METHODS

=section Construction

=function use Object::Realize::Later %options
When you invoke (C<use>) the C<Object::Realize::Later> package, it will
add a set of methods to your package (see section L</Added to YOUR class>).

=requires becomes $class
Which type will this object become after realization.

=requires realize $method|CODE
How will transform.  If you specify a CODE reference, then this will be
called with the lazy-object as first argument, and the requested $method
as second.

After realization, you may still have your hands on the lazy object
on various places.  Be sure that your realization method is coping
with that, for instance by using L<Memoize>.  See examples below.

=option  source_module $class
=default source_module <becomes>
if the $class (a package) is included in a file (module) with a different
name, then use this argument to specify the file name. The name is
expected to be the same as in the C<require> call which would load it.

=option  warn_realization BOOLEAN
=default warn_realization false
Print a warning message when the realization starts.  This is for
debugging purposes.

=option  warn_realize_again BOOLEAN
=default warn_realize_again false
When an object is realized, the original object -which functioned
as a stub- is reconstructed to work as proxy to the realized object.
This option will issue a warning when that proxy is used, which means
that somewhere in your program there is a variable still holding a
reference to the stub.  This latter is not problematic at all, although
it slows-down each method call.

=option  believe_caller BOOLEAN
=default believe_caller false
When a method is called on the un-realized object, the AUTOLOAD
checks whether this resolves the need.  If not, the realization is
not done.  However, when realization may result in an object that
extends the functionality of the class specified with P<becomes>,
this check must be disabled.  In that case, specify true for
this option.
=cut

#------------
=section Added to YOUR class
=cut

my $named  = 'ORL_realization_method';
my $helper = 'ORL_fake_realized';

=c_method isa $class
Is this object a (sub-)class of the specified $class or can it become a
(sub-)class of $class.

=examples

  MyLazyObject->isa('MyRealObject')      # true
  MyLazyObject->isa('SuperClassOfLazy'); # true
  MyLazyObject->isa('SuperClassOfReal'); # true

  my $lazy = MyLazyObject->new;
  $lazy->isa('MyRealObject');            # true
  $lazy->isa('SuperClassOfLazy');        # true
  $lazy->isa('SuperClassOfReal');        # true

=cut

sub init_code($)
{	my $args    = shift;

	<<INIT_CODE;
  package $args->{class};
  require $args->{source_module};

  my \$$helper = bless {}, '$args->{becomes}';
INIT_CODE
}

sub isa_code($)
{	my $args    = shift;

	<<ISA_CODE;
  sub isa(\$)
  {   my (\$thing, \$what) = \@_;
      return 1 if \$thing->SUPER::isa(\$what);  # real dependency?
      \$$helper\->isa(\$what);
  }
ISA_CODE
}

=ci_method can $method
Is the specified $method available for the lazy or the realized version
of this object?  It will return the reference to the code.
=examples

  MyLazyObject->can('lazyWork')      # true
  MyLazyObject->can('realWork')      # true

  my $lazy = MyLazyObject->new;
  $lazy->can('lazyWork');            # true
  $lazy->can('realWork');            # true

=cut

sub can_code($)
{	my $args = shift;
	my $becomes = $args->{becomes};

	<<CAN_CODE;
  sub can(\$)
  {   my (\$thing, \$method) = \@_;
      my \$func;
      \$func = \$thing->SUPER::can(\$method)
         and return \$func;

      \$func = \$$helper\->can(\$method)
         or return;

      # wrap func() to trigger load if needed.
      sub { ref \$thing
            ? \$func->(\$thing->forceRealize, \@_)
            : \$func->(\$thing, \@_)
          };
  }
CAN_CODE
}

=method AUTOLOAD
When a method is called which is not available for the lazy object, the
AUTOLOAD is called.
=cut

sub AUTOLOAD_code($)
{	my $args   = shift;

	<<'CODE1' . ($args->{believe_caller} ? '' : <<NOT_BELIEVE) . <<CODE2;
  our $AUTOLOAD;
  sub AUTOLOAD(@)
  {  my $call = substr $AUTOLOAD, rindex($AUTOLOAD, ':')+1;
     return if $call eq 'DESTROY';
CODE1

     unless(\$$helper->can(\$call) || \$$helper->can('AUTOLOAD'))
     {   use Carp;
         croak "Unknown method \$call called";
     }
NOT_BELIEVE
    # forward as class method if required
    shift and return $args->{becomes}->\$call( \@_ ) unless ref \$_[0];

     \$_[0]->forceRealize;
     my \$made = shift;
     \$made->\$call(\@_);
  }
CODE2
}

=method forceRealize
You can force the load by calling this method on your object.  It returns
the realized object.
=cut

sub realize_code($)
{	my $args    = shift;
	my $pkg     = __PACKAGE__;
	my $argspck = join "'\n         , '", %$args;

	<<REALIZE_CODE .($args->{warn_realization} ? <<'WARN' : '') . <<REALIZE_CODE;
  sub forceRealize(\$)
  {
REALIZE_CODE
	require Carp;
	Carp::carp("Realization of $_[0]");
WARN
	${pkg}->realize(
		ref_object => \\\${_[0]},
		caller     => [ caller 1 ],
		'$argspck'
	);
  }
REALIZE_CODE
}

=method willRealize
Returns which class will be the realized to follow-up this class.
=cut

sub will_realize_code($)
{	my $args = shift;
	my $becomes = $args->{becomes};
	<<WILL_CODE;
sub willRealize() {'$becomes'}
WILL_CODE
}

#--------------------
=section Object::Realize::Later internals

The next methods are not exported to the class where the `use' took
place.  These methods implement the actual realization.

=c_method realize %options
This method is called when a C<$object->forceRealize()> takes
place.  It checks whether the realization has been done already
(is which case the realized object is returned)
=cut

sub realize(@)
{	my ($class, %args) = @_;
	my $object  = ${$args{ref_object}};
	my $realize = $args{realize};

	my $already = $class->realizationOf($object);
	if(defined $already && ref $already ne ref $object)
	{	if($args{warn_realize_again})
		{	my (undef, $filename, $line) = @{$args{caller}};
			warn "Attempt to realize object again: old reference caught at $filename line $line.\n"
		}

		return ${$args{ref_object}} = $already;
	}

	my $loaded  = ref $realize ? $realize->($object) : $object->$realize;

	$loaded->isa($args{becomes})
		or warn "Load produces a ".ref($loaded) . " where a $args{becomes} is expected.\n";

	${$args{ref_object}} = $loaded;
	$class->realizationOf($object, $loaded);
}

=c_method realizationOf $object, [$realized]
Returns the $realized version of $object, optionally after setting it
first.  When the method returns undef, the realization has not
yet taken place or the realized object has already been removed again.
=cut

my %realization;

sub realizationOf($;$)
{	my ($class, $object) = (shift, shift);
	my $unique = "$object";

	if(@_)
	{	$realization{$unique} = shift;
		weaken $realization{$unique};
	}

	$realization{$unique};
}

=c_method import %options
The %options used for C<import> are the values after the class name
with C<use>.  So this routine implements the actual option parsing.
It generates code dynamically, which is then evaluated in the
callers name-space.
=cut

sub import(@)
{	my ($class, %args) = @_;

	$args{becomes} or panic "import requires 'becomes'";
	$args{realize} or panic "import requires 'realize'";

	$args{class}                = caller;
	$args{warn_realization}   ||= 0;
	$args{warn_realize_again} ||= 0;
	$args{source_module}      ||= $args{becomes};

	# A reference to code will stringify at the eval below.  To solve
	# this, it is tranformed into a call to a named subroutine.
	if(ref $args{realize} eq 'CODE')
	{	my $named_method = "$args{class}::$named";
		*{$named_method} = $args{realize};
		$args{realize}   = $named_method;
	}

	# Produce the code

	my $args = \%args;
	my $eval
		= init_code($args)
		. isa_code($args)
		. can_code($args)
		. AUTOLOAD_code($args)
		. realize_code($args)
		. will_realize_code($args);
#warn $eval;

	# Install the code

	eval $eval;
	panic $@ if $@;

	1;
}

#--------------------
=chapter DETAILS

=section About lazy loading

There are two ways to implement lazy behaviour: you may choose to check
whether you have realized the data in each method which accesses the data,
or use the autoloading of data trick.

An implementation of the first solution is:

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
call M<realize()>.  The tests cannot cover all ordenings of method-calls to
detect the mistakes.

The I<second approach> uses autoloading, and is supported by this package.
First we create a stub-object, which will be transformable into a
realized object later.  This transformation is triggered by AUTOLOAD.

This stub-object may contain some methods from the realized object,
to reduce the need for realization.  The stub will also contain some
information which is required for the creation of the real object.

C<Object::Realize::Later> solves the inheritance problems (especially
the M<isa()> and M<can()> methods) and supplies the AUTOLOAD method.
Class methods which are not defined in the stub object are forwarded
as class methods without realization.

=section Traps

Be aware of dangerous traps in the current implementation.  These
problems appear by having multiple references to the same delayed
object.  Depending on how the realization is implemented, terrible
things can happen.

The two versions of realization:

=over 4

=item * by reblessing

This is the safe version.  The realized object is the same object as
the delayed one, but reblessed in a different package.  When multiple
references to the delayed object exists, they will all be updated
at the same, because the bless information is stored within the
refered variable.

=item * by new instance

This is the nicest way of realization, but also quite more dangerous.
Consider this:

  package Delayed;
  use Object::Realize::Later
       becomes => 'Realized',
       realize => 'load';

  sub new($)      { my($class,$v)=@_; bless {label=>$v}, $class }
  sub setLabel($) { my $self = shift; $self->{label} = shift }
  sub load()      { $_[0] = Realized->new($_[0]->{label}) }

  package Realized;  # file Realized.pm or use M<use(source_module)>
  sub new($)      { my($class,$v)=@_; bless {label=>$v}, $class }
  sub setLabel($) { my $self = shift; $self->{label} = shift }
  sub getLabel()  { my $self = shift; $self->{label} }

  package main;
  my $original = Delayed->new('original');
  my $copy     = $original;
  print $original->getLabel;     # prints 'original'
  print ref $original;           # prints 'Realized'
  print ref $copy;               # prints 'Delayed'
  $original->setLabel('changed');
  print $original->getLabel;     # prints 'changed'
  print $copy->getLabel;         # prints 'original'

=back

=section Examples

=subsection Example 1

In the first example, we delay-load a message.  On the moment the
message is defined, we only take the location.  When the data of the
message is taken (header or body), the data is autoloaded.

  package Mail::Message::Delayed;

  use Object::Realize::Later(
    becomes => 'Mail::Message::Real',
    realize => 'loadMessage'
  );

  sub new($) {
      my ($class, $file) = @_;
      bless { filename => $file }, $class;
  }

  sub loadMessage() {
      my $self = shift;
      Mail::Message::Real->new($self->{filename});
  }

In the main program:

  package main;
  use Mail::Message::Delayed;

  my $msg    = Mail::Message::Delayed->new('/home/user/mh/1');
  $msg->body->print;     # this will trigger autoload.

=subsection Example 2

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

=subsection Example 3

This module is especially useful for larger projects, which there is
a need for speed or memory reduction. In this case, you may have an
extra overview on which objects have been realized (transformed), and
which not.  This example is taken from the MailBox modules:

The L<Mail::Box> module tries to boost the access-time to a folder.
If you only need the messages of the last day, why shall all be read?
So, MailBox only creates an invertory of messages at first.  It
takes the headers of all messages, but leaves the body (content) of
the message in the file.

In MailBox' case, the L<Mail::Message>-object has the choice
between a number of L<Mail::Message::Body>'s, one of which has only
be prepared to read the body when needed.  A code snippet:

  package Mail::Message;
  sub new($$)
  {   my ($class, $head, $body) = @_;
      my $self = bless +{ head => $head, body => $body }, $class;
      $body->message($self);          # tell body about the message
  }
  sub head()     { $_[0]->{head} }
  sub body()     { $_[0]->{body} }

  sub loadBody()
  {   my $self = shift;
      my $body = $self->body;

      # Catch re-invocations of the loading.  If anywhere was still
      # a reference to the old (unrealized) body of this message, we
      # return the new-one directly.
      $body->can('forceRealize') or return $body;

      # Load the body (change it to anything which really is of
      # the promised type, or a sub-class of it.
      my ($lines, $size) = .......;    # get the data
      $self->{body} = Mail::Message::Body::Lines->new($lines, $size, $self);

      # Return the realized object.
      return $self->{body};
  }


  package Mail::Message::Body::Lines;
  use base 'Mail::Message::Body';

  sub new($$$)
  {   my ($class, $lines, $size, $message) = @_;
      bless { lines => $lines, size => $size, message => $message }, $class;
  }
  sub size()    { $_[0]->{size} }
  sub lines()   { $_[0]->{lines} }
  sub message() { $_[0]->{message} };

  package Mail::Message::Body::Delayed;
  use Object::Realize::Later
      becomes => 'Mail::Message::Body',
      realize => sub {shift->message->loadBody};

  sub new($)
  {   my ($class, $size) = @_;
      bless +{ size => $size }, $class;
  }
  sub size() { $_[0]->{size} }
  sub message(;$)
  {   my $self = shift;
      @_ ? ($self->{message} = shift) : $self->{messages};
  }

  package main;
  use Mail::Message ();
  use Mail::Message::Body::Delayed ();

  my $body    = Mail::Message::Body::Delayed->new(42);
  my $message = Mail::Message->new($head, $body);

  print $message->size;         # will not trigger realization!
  print $message->can('lines'); # true, but no realization yet.
  print $message->lines;        # realizes automatically.

=cut

1;
