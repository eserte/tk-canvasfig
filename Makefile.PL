#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: Makefile.PL,v 1.1 2001/04/26 00:17:21 eserte Exp $
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
   'NAME'	   => 'Tk::Fig',
   'VERSION_FROM'  => 'Fig.pm',
   'PREREQ_PM'     => { Tk => undef },

   'dist' => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},

   'ABSTRACT_FROM' => '',
   'AUTHOR'        => 'Slaven Rezic (eserte@onlineoffice.de)',
  );

__END__
