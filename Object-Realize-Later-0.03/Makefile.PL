use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME           => 'Object::Realize::Later'
  , VERSION_FROM   => 'Later.pm'
  , PMLIBDIRS      => [ 'Proxy' ]
  , PREREQ_PM      => {}
  , AUTHOR         => 'Mark Overmeer <realize@overmeer.net>'
  , ABSTRACT       => 'Delayed realization of objects'
  );
