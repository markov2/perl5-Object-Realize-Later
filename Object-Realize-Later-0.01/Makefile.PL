use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Object::Realize::Later',
    'VERSION_FROM'	=> 'Later.pm',
    'PREREQ_PM'		=> {},
    'AUTHOR'            => 'Mark Overmeer <realize@overmeer.net>',
    'ABSTRACT'          => 'Delayed realization of objects'
);
