use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME           => 'Object::Realize::Later'
  , VERSION_FROM   => 'Later.pm'
  , PMLIBDIRS      => [ 'Proxy' ]
  , PREREQ_PM      => { Scalar::Util => 0.0 }
  , AUTHOR         => 'Mark Overmeer <realize@overmeer.net>'
  , ABSTRACT       => 'Delayed realization of objects'
  );
