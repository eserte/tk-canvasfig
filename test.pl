#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.2 2001/05/20 09:36:02 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Test;

BEGIN { plan tests => 1 }

use Tk;
use Tk::Fig;
use FindBin;

my $top=new MainWindow;
my $c = $top->Canvas->pack;
for (1..10) {
    $c->createLine(0, $_*10, 100, $_*10);
}
$c->createText(100,100,-anchor => 'nw', -text => 'rjkrge');
Tk::Fig::save($c, "$FindBin::RealBin/test.fig");

my $f = $top->Frame->pack;
$f->Button(-text => "Start xfig",
	   -command => sub {
	       system("xfig $FindBin::RealBin/test.fig &");
	   })->pack(-side => "left");
my $okb = $f->Button(-text => "Ok",
		     -command => sub { $top->destroy })->pack(-side => "left");

if ($ENV{BATCH}) {
    $top->after(1000, sub { $okb->invoke });
}
MainLoop;

ok(1);

__END__
