#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: test.pl,v 1.5 2001/12/06 21:44:58 eserte Exp $
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
use Tk::CanvasFig;
use FindBin;
use strict;

my $top=new MainWindow;
my $c = $top->Canvas(-width => 350, -height => 350)->pack;
for (1..10) {
    $c->createLine(0, $_*10, 100, $_*10);
}
$c->createLine(0,0,100,100);
$c->createRectangle(100,100,150,150, -fill => "red", -outline => "blue");
$c->createPolygon(120,120,140,140,120,200,80,110, -fill => "green");

$c->createArc(30,200,130,300, -start => 0, -extent => 135);
$c->createArc(40,210,140,310, -start => 0, -extent => -135);
$c->createArc(50,220,150,320, -start => 90, -extent => 135);

$c->createOval(150,200,250,300, -fill => "red");
$c->createOval(150,230,250,270, -fill => "green", -outline => "white");

{
    my $p = $c->Photo(-file => Tk->findINC("Xcamel.gif"));
    my($x,$y) = (280,70);
    $c->createImage($x,$y,-image => $p, -anchor => "n");
    $c->createImage($x,$y,-image => $p, -anchor => "s");
    $c->createImage($x,$y,-image => $p, -anchor => "w");
    $c->createImage($x,$y,-image => $p, -anchor => "e");
    $c->createImage(20,180, -image => $p);
}
{
    my $p2 = $c->Pixmap(-file => Tk->findINC("Camel.xpm"));
    my($x,$y) = (280,210);
    $c->createImage($x,$y,-image => $p2, -anchor => "ne");
    $c->createImage($x,$y,-image => $p2, -anchor => "nw");
    $c->createImage($x,$y,-image => $p2, -anchor => "se");
    $c->createImage($x,$y,-image => $p2, -anchor => "sw");
}

$c->createText(100,100, -anchor => 'w', -text => 'rjkrge');

my $testimagesdir = "$FindBin::RealBin/test-images";
mkdir $testimagesdir, 0755;
$c->fig(-file => "$FindBin::RealBin/test.fig",
	-imagedir => $testimagesdir);

my $f = $top->Frame->pack;
if (is_in_path("xfig")) {
    $f->Button(-text => "Start xfig",
	       -command => sub {
		   system("xfig $FindBin::RealBin/test.fig &");
	       })->pack(-side => "left");
}
my $okb = $f->Button(-text => "Ok",
		     -command => sub { $top->destroy })->pack(-side => "left");

if ($ENV{BATCH}) {
    $top->after(1000, sub { $okb->invoke });
}
MainLoop;

ok(1);

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/src/repository 
# REPO MD5 1b42243230d92021e6c361e37c9771d1

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my($prog) = @_;
    return $prog if (file_name_is_absolute($prog) and -f $prog and -x $prog);
    require Config;
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    return "$_\\$prog"
		if (-x "$_\\$prog.bat" ||
		    -x "$_\\$prog.com" ||
		    -x "$_\\$prog.exe");
	} else {
	    return "$_/$prog" if (-x "$_/$prog");
	}
    }
    undef;
}
# REPO END

# REPO BEGIN
# REPO NAME file_name_is_absolute /home/e/eserte/src/repository 
# REPO MD5 a77759517bc00f13c52bb91d861d07d0

=head2 file_name_is_absolute($file)

=for category File

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

sub file_name_is_absolute {
    my $file = shift;
    my $r;
    eval {
        require File::Spec;
        $r = File::Spec->file_name_is_absolute($file);
    };
    if ($@) {
	if ($^O eq 'MSWin32') {
	    $r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	} else {
	    $r = ($file =~ m|^/|);
	}
    }
    $r;
}
# REPO END

__END__
