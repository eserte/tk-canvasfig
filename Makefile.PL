#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: Makefile.PL,v 1.4 2003/10/22 20:49:29 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'	   => 'Tk::CanvasFig',
   'VERSION_FROM'  => 'CanvasFig.pm',
   'PREREQ_PM'     => { Tk => 0 },

   'dist' => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},

   'ABSTRACT_FROM' => '',
   'AUTHOR'        => 'Slaven Rezic (slaven@rezic.de)',
  );

sub MY::postamble {
    my $postamble = "";

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte') {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}

__END__
