use ExtUtils::MakeMaker;

require 5.005_57;   # for weaken

WriteMakefile
  ( NAME      => 'Object::Realize::Later'
  , VERSION   => '0.17'
  , PREREQ_PM => { Scalar::Util => 0.0 }
  , AUTHOR    => 'Mark Overmeer <perl@overmeer.net>'
  , ABSTRACT  => 'Delayed realization of objects'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/orl/raw
DISTDIR         = ../public_html/orl/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2001-2004,2007
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/orl/

# for HTML
HTML_OUTPUT     = ../public_html/orl/html
HTML_DOCROOT    = /orl/html

__POSTAMBLE
