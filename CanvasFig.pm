# -*- perl -*-

#
# $Id: CanvasFig.pm,v 1.3 2001/04/26 00:17:31 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Tk::Fig;

use Tk::Canvas;
use strict;
use vars qw($VERSION %capstyle %joinstyle %figcolor @figcolor
	    $usercolorindex);

$VERSION = '0.01';

%capstyle = ('butt' => 0,
	     'projecting' => 2,
	     'round' => 1);
%joinstyle = ('bevel' => 1,
	      'miter' => 0,
	      'round' => 2);

sub col2rgb {
    my($c, $color) = @_;
    if ($color !~ /^\#/) {
	my($r,$g,$b) = $c->rgb($color);
	if (defined $r) {
	    return sprintf("#%02x%02x%02x",
			   $r/256, $g/256, $b/256);
	}
    }
    $color;
}

sub initcolor {
    my $c = shift;
    undef %figcolor;
    @figcolor =
      (
       "black",   "blue",    "green",   "cyan",
       "red",     "magenta", "yellow",  "white",
       "#000090", "#0000b0", "#0000d0", "#87ceff",
       "#009000", "#00b000", "#00d000", "#009090",
       "#00b0b0", "#00d0d0", "#900000", "#b00000",
       "#d00000", "#900090", "#b000b0", "#d000d0",
       "#803000", "#a04000", "#c06000", "#ff8080",
       "#ffa0a0", "#ffc0c0", "#ffe0e0", "gold",
      );
    for(my $i=0; $i<=$#figcolor; $i++) {
	$figcolor[$i] = col2rgb($c, $figcolor[$i]);
	$figcolor{$figcolor[$i]} = $i;
    }
    $usercolorindex = 32;
}

sub newusercolor {
    my($color) = @_;
    if ($usercolorindex > 543) {
	warn "Too many colors, using default";
	-1;
    } else {
	my $ci = $usercolorindex;
	$usercolorindex++;
	$figcolor[$ci] = $color;
	$figcolor{$color} = $ci;
	$ci;
    }
}

my $coeff;

sub init {
    my $c = shift;
    $coeff = int ( 1200 / (($c->screenwidth/$c->screenmmwidth)*25.4) );
    initcolor($c);
}

sub transpose {
    my $x = shift;
    int($x*$coeff);
}

sub save {
    my($c, $filename) = @_;

    init($c);

    my(@items) = $c->find('all');

    my($figobjstr, $figcolstr) = ('','');

    open(FIG, ">$filename") or die $!;
    print FIG "#FIG 3.2\n";
    print FIG "Landscape\n"; # XXX
    print FIG "Center\n"; # XXX
    print FIG "Metric\n"; # XXX
    print FIG "A4\n"; # XXX
    print FIG "100.00\n"; # XXX
    print FIG "Single\n"; # XXX
    print FIG "-2\n"; # XXX
    print FIG "1200 2\n"; # XXX

    foreach my $item (@items) {
	my $type = $c->type($item);
	if ($type eq 'arc') {
	} elsif ($type eq 'oval') {
	} elsif ($type =~ /^(polygon|line|rectangle)$/) {
	    my $filled = 0;
	    $figobjstr .= "2 ";
	    if ($type eq 'polygon') {
		$figobjstr .= "3 ";
	    } elsif ($type eq 'line') {
		$figobjstr .= "1 ";
	    } elsif ($type eq 'rectangle') {
		$figobjstr .= "2 ";
	    } else {
		die;
	    }
	    $figobjstr .= "-1 "; # line style
	    my $width = $c->itemcget($item, '-width');
	    $figobjstr .= "$width ";
	    if ($type eq 'line') {
		my $pen = col2rgb($c, $c->itemcget($item, '-fill'));
		if (exists $figcolor{$pen}) {
		    $figobjstr .= "$figcolor{$pen} ";
		} else {
		    $pen = newusercolor($pen);
		    $figobjstr .= "$pen ";
		    $figcolstr .= "0 $pen $figcolor[$pen]\n";
		}
		$figobjstr .= "-1 "; # fill color
	    } else {
		# XXX pen = fill, wenn pen nicht definiert
		my $pen = $c->itemcget($item, '-outline');
		if ($pen ne '') {
		    $pen = col2rgb($c, $pen);
		    if (exists $figcolor{$pen}) {
			$figobjstr .= "$figcolor{$pen} ";
		    } else {
			$pen = newusercolor($pen);
			$figobjstr .= "$pen ";
			$figcolstr .= "0 $pen $figcolor[$pen]\n";
		    }
		} else {
		    $figobjstr .= "0 ";
		}
		my $fill = $c->itemcget($item, '-fill');
		if ($fill ne '') {
		    $fill = col2rgb($c, $fill);
		    if (exists $figcolor{$fill}) {
			$figobjstr .= "$figcolor{$fill} ";
		    } else {
			$fill = newusercolor($fill);
			$figobjstr .= "$fill ";
			$figcolstr .= "0 $fill $figcolor[$fill]\n";
		    }
		    $filled = 1;
		} else {
		    $figobjstr .= "-1 ";
		}
	    }
	    $figobjstr .= "0 "; # depth
	    $figobjstr .= "0 "; # pen style
	    $figobjstr .= ($filled ? '20' : '-1') . " "; # area fill
	    $figobjstr .= "0.000 "; #style val
	    if ($type eq 'line') {
		my $join = $c->itemcget($item, '-joinstyle');
		$figobjstr .= $joinstyle{$join} . " ";
		my $cap = $c->itemcget($item, '-capstyle');
		$figobjstr .= $capstyle{$cap} . " ";
	    } else {
		$figobjstr .= "0 0 ";
	    }
	    $figobjstr .= "-1 "; # radius
	    if ($type eq 'line') {
		my $arrow = $c->itemcget($item, '-arrow');
		# forward arrow
		$figobjstr .= ($arrow =~ /^(both|last)$/ ? "1" : "0") . " ";
		# backward arrow
		$figobjstr .= ($arrow =~ /^(both|first)$/ ? "1" : "0") . " ";
	    } else {
		$figobjstr .= "0 0 ";
	    }
	    my(@coords) = $c->coords($item);
	    $figobjstr .= (scalar @coords)/2 . " \n\t";
	    for(my $i=0; $i<$#coords; $i+=2) {
		$figobjstr .= transpose($coords[$i]) . " " . transpose($coords[$i+1]) . " ";
	    }
	    $figobjstr .= "\n";
	} elsif ($type eq 'text') {
	    $figobjstr .= "4 ";
	    my $anchor = $c->itemcget($item, '-anchor');
	    if ($anchor =~ /w/) {
		$figobjstr .= "0 ";
	    } elsif ($anchor =~ /e/) {
		$figobjstr .= "2 ";
	    } else { 
		$figobjstr .= "1 "; # justification
	    }
	    my $pen = col2rgb($c, $c->itemcget($item, '-fill'));
	    if (exists $figcolor{$pen}) {
		$figobjstr .= "$figcolor{$pen} ";
	    } else {
		$pen = newusercolor($pen);
		$figobjstr .= "$pen ";
		$figcolstr .= "0 $pen $figcolor[$pen]\n";
	    }
#	    $figobjstr .= "-1 "; # color
	    $figobjstr .= "0 "; # depth
	    $figobjstr .= "0 "; # pen style
	    $figobjstr .= "1 "; # font
	    $figobjstr .= "10 "; # font size
	    $figobjstr .= "0.000 "; # angle
	    $figobjstr .= "4 "; # font flags
	    my(@bbox) = $c->bbox($item);
	    $figobjstr .= transpose(abs($bbox[1]-$bbox[3])) . " ";
	    $figobjstr .= transpose(abs($bbox[0]-$bbox[2])) . " ";
	    my(@coords) = $c->coords($item);
	    $figobjstr .= transpose($coords[0]). " ".transpose($coords[1])." ";
	    my $text = $c->itemcget($item, '-text') . "\\001";
	    $figobjstr .= $text;
	    $figobjstr .= "\n";
	} elsif ($type eq 'image') {
	    warn "Image is not supported yet...\n";
	} else {
	    warn "Unknown type: $type";
	}
    }
    print FIG $figcolstr, $figobjstr;
    close FIG;
}

return 1 if caller();

{
    no strict;
    package main;
    use Tk;
    $top=new MainWindow;
    $c = $top->Canvas->pack;
    for (1..10) {
	$c->createLine(0, $_*10, 100, $_*10);
    }
    $c->createText(100,100,-anchor => 'nw', -text => 'rjkrge');
    save($c, "/tmp/test.fig");
    MainLoop;
}
