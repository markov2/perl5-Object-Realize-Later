use ExtUtils::MakeMaker;

require 5.005_57;   # for weaken

WriteMakefile
  ( NAME           => 'Object::Realize::Later'
  , VERSION_FROM   => 'lib/Object/Realize/Later.pm'
  , PREREQ_PM      => { Scalar::Util => 0.0 }
  , AUTHOR         => 'Mark Overmeer <realize@overmeer.net>'
  , ABSTRACT       => 'Delayed realization of objects'
  );
