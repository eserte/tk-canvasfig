# -*- perl -*-

#
# $Id: CanvasFig.pm,v 1.6 2001/12/05 23:16:56 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998,2001 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven.rezic@berlin.de
# WWW:  http://bbbike.sourceforge.net/
#

package Tk::CanvasFig;

use Tk::Canvas;
use Tk::Font;

use File::Basename;

use strict;
use vars qw($VERSION %capstyle %joinstyle %figcolor @figcolor
	    $usercolorindex);

$VERSION = sprintf("%d.%03d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

%capstyle = ('butt' => 0,
	     'projecting' => 2,
	     'round' => 1);
%joinstyle = ('bevel' => 1,
	      'miter' => 0,
	      'round' => 2);

my(%font_warning, %color_warning);

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
	warn "Too many colors, using default\n"
	    unless $color_warning{'toomany'};
	$color_warning{'toomany'}++;
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
    my($c, %args) = @_;

    %font_warning = ();
    %color_warning = ();

    my $filename = $args{-filename};

    my $imagedir;
    my $imageprefix;
    my $imagecount = 0;
    my $imagedir_warning;
    my %images;
    if ($args{-imagedir} && -d $args{-imagedir} && -w $args{-imagedir}) {
	$imagedir = $args{-imagedir};
	my $filedir = basename($filename);
	if ($imagedir =~ /^(\Q$filedir\E)(.*)/) {
	    $imageprefix = $2;
	    $imageprefix =~ s|^/+||;
	} else {
	    $imageprefix = $imagedir;
	}
    }

    my $imagetype = "xpm";
    if ($args{-imagetype}) {
	$imagetype = $args{-imagetype};
    }

    init($c);

    my(@items) = $c->find('all');

    my($figobjstr, $figcolstr) = ('','');

    my $figheader = <<EOF;
#FIG 3.2
Landscape
Center
Metric
A4
100.00
Single
-3
1200 2
EOF

    foreach my $item (@items) {
	my $type = $c->type($item);

	if ($type eq 'arc') {
	    # NYI

	} elsif ($type eq 'oval') {
	    # NYI

	} elsif ($type =~ /^(polygon|line|rectangle)$/) {
	    my $filled = 0;
	    $figobjstr .= "2 ";
	    my(@coords) = $c->coords($item);
	    if ($type eq 'polygon' && @coords >= 3*2) { # to prevent xfig warnings
		$figobjstr .= "3 ";
	    } elsif ($type eq 'line' || $type eq 'polygon') {
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
		my $fill_figobjstr = "";
		my $fill = $c->itemcget($item, '-fill');
		if ($fill ne '') {
		    $fill = col2rgb($c, $fill);
		    if (exists $figcolor{$fill}) {
			$fill_figobjstr .= "$figcolor{$fill} ";
		    } else {
			$fill = newusercolor($fill);
			$fill_figobjstr .= "$fill ";
			$figcolstr .= "0 $fill $figcolor[$fill]\n";
		    }
		    $filled = 1;
		} else {
		    $fill_figobjstr .= "-1 ";
		}

		# XXX pen = fill, wenn pen nicht definiert
		my $pen = $c->itemcget($item, '-outline');
		if (defined $pen && $pen ne '') {
		    $pen = col2rgb($c, $pen);
		    if (exists $figcolor{$pen}) {
			$figobjstr .= "$figcolor{$pen} ";
		    } else {
			$pen = newusercolor($pen);
			$figobjstr .= "$pen ";
			$figcolstr .= "0 $pen $figcolor[$pen]\n";
		    }
		} else {
		    $figobjstr .= $fill_figobjstr;
		}
		$figobjstr .= $fill_figobjstr;
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
	    if ($type eq 'rectangle') {
		$figobjstr .= "5 \n\t";
		my($tx1,$ty1) = (transpose($coords[0]), transpose($coords[1]));
		my($tx2,$ty2) = (transpose($coords[2]), transpose($coords[3]));
		$figobjstr .= "$tx1 $ty1 $tx2 $ty1 $tx2 $ty2 $tx1 $ty2 $tx1 $ty1";
	    } else {
		$figobjstr .= (scalar @coords)/2 . " \n\t";
		for(my $i=0; $i<$#coords; $i+=2) {
		    $figobjstr .= transpose($coords[$i]) . " " . transpose($coords[$i+1]) . " ";
		}
	    }
	    $figobjstr .= "\n";

	} elsif ($type eq 'text') {
	    $figobjstr .= "4 ";
	    my $anchor = $c->itemcget($item, '-anchor');
	    if ($anchor =~ /w$/) {
		$figobjstr .= "0 ";
	    } elsif ($anchor =~ /e$/) {
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
	    $figobjstr .= "0 "; # depth
	    $figobjstr .= "0 "; # pen style
	    my $font = $c->itemcget($item, '-font');
	    my($fonttype, $fontsize);
	    if (defined $font) {
		($fonttype, $fontsize) = font2figfont($font);
	    } else {
		($fonttype, $fontsize) = (-1, 10);
	    }
	    $figobjstr .= "$fonttype "; # font
	    $figobjstr .= "$fontsize "; # font size
	    $figobjstr .= "0.000 "; # angle
	    $figobjstr .= "4 "; # font flags (postscript fonts)
# XXX anchor => center/south: adjust y coordinate!
	    my(@bbox) = $c->bbox($item);
	    $figobjstr .= transpose(abs($bbox[1]-$bbox[3])) . " ";
	    $figobjstr .= transpose(abs($bbox[0]-$bbox[2])) . " ";
	    my(@coords) = $c->coords($item);
	    $figobjstr .= transpose($coords[0]). " ".transpose($coords[1])." ";
	    my $text = $c->itemcget($item, '-text') . "\\001";
	    $figobjstr .= $text;
	    $figobjstr .= "\n";

	} elsif ($type eq 'image') {
	    my $image = $c->itemcget($item, '-image');
	    if ($image && $imagedir) {
		my $imagename = $images{$image};
		if (!defined $imagename) {
		    # gif/ppm are too slow, because external programs are used
		    # xpm have to be compiled into the xfig binary!
		    my $outfilebase = "$imagecount.$imagetype";
		    my $outfilename = "$imagedir/$outfilebase";
		    if ($image->type eq 'pixmap') {
			my $file = $image->cget('-file');
			my $data = $image->cget('-data');
			my $new_image;
			if (defined $data) {
			    $new_image = $c->Photo(-data => $data, -format => "xpm");
			} elsif (defined $file) {
			    $new_image = $c->Photo(-file => $file, -format => "xpm");
			} else {
			    # empty pixmap, do nothing
			    next;
			}
			$new_image->write($outfilename, -format => $imagetype);
			$new_image->delete;
		    } elsif ($image->type eq 'bitmap') {
			warn "Sorry, bitmap is not yet supported...";
			next;
		    } elsif ($image->type eq 'photo') {
			$image->write($outfilename, -format => $imagetype);
		    } else {
			warn "Sorry image type " . $image->type . " is not supported...";
			next;
		    }
		    $imagename = $images{$image} = "$imageprefix/$outfilebase";
		    $imagecount++;
		}
		$figobjstr .= "2 "; # polyline
		$figobjstr .= "5 "; # imported picture bounding box
		$figobjstr .= "-1 "; # line style
		$figobjstr .= "-1 "; # thickness
		$figobjstr .= "-1 "; # pen color
		$figobjstr .= "-1 "; # fill color
		$figobjstr .= "0 "; # depth
		$figobjstr .= "0 "; # pen style
		$figobjstr .= "-1 "; # area fill
		$figobjstr .= "0.000 "; #style val
		$figobjstr .= "0 0 "; # cap/join style
		$figobjstr .= "-1 "; # radius
		$figobjstr .= "0 0 "; # forward/backward arrow
		my(@coords) = $c->coords($item);
		$figobjstr .= "5\n\t0 $imagename\n\t";

		my $anchor = $c->itemcget($item, '-anchor');
		my $addx = -$image->width/2;
		my $addy = -$image->height/2;
		if ($anchor ne 'center') {
		    if ($anchor =~ /n/) {
			$addy = 0;
		    } elsif ($anchor =~ /s/) {
			$addy = -$image->height;
		    }
		    if ($anchor =~ /w/) {
			$addx = 0;
		    } elsif ($anchor =~ /e/) {
			$addx = -$image->width;
		    }
		}
		my($tx1,$ty1) = (transpose($coords[0]+$addx), transpose($coords[1]+$addy));
		my($tx2,$ty2) = (transpose($coords[0]+$image->width+$addx), transpose($coords[1]+$image->height+$addy));
		$figobjstr .= "$tx1 $ty1 $tx2 $ty1 $tx2 $ty2 $tx1 $ty2 $tx1 $ty1";
		$figobjstr .= "\n";
	    } elsif ($image) {
		warn "Writing images is not enabled (-imagedir not given or not writable)\n"
		    unless $imagedir_warning;
		$imagedir_warning++;
	    }

	} else {
	    warn "Unknown type: $type";
	}
    }

    if (defined $filename) {
	open(FIG, ">$filename") or die "Can't write to $filename: $!";
	print FIG $figheader, $figcolstr, $figobjstr;
	close FIG;
    } else {
	"$figheader$figcolstr$figobjstr";
    }
}

sub font2figfont {
    my($f) = @_;
    my(%a) = $f->actual;
    my $font = -1; # use default font
    my $base;
    if ($a{'-family'} =~ /(times)/i) {
	$base = 0;
    } elsif ($a{'-family'} =~ /(helvetica|arial|geneva)/i) {
	$base = 16;
    } elsif ($a{'-family'} =~ /avantgarde/i) {
	$base = 4;
    } elsif ($a{'-family'} =~ /bookman/i) {
	$base = 8;
    } elsif ($a{'-family'} =~ /courier/i) {
	$base = 12;
    } elsif ($a{'-family'} =~ /new century/i) {
	$base = 24;
    } elsif ($a{'-family'} =~ /palatino/i) {
	$base = 28;
    } else {
	warn "Unknown font family $a{'-family'}, fallback to default\n"
	    unless $font_warning{$a{'-family'}};
	$font_warning{$a{'-family'}}++;
    }
    if (defined $base) {
	if      ($a{'-weight'} eq 'normal' && $a{'-slant'} eq 'roman') {
	    $font = $base;
	} elsif ($a{'-weight'} eq 'normal' && $a{'-slant'} eq 'italic') {
	    $font = $base + 1;
	} elsif ($a{'-weight'} eq 'bold'   && $a{'-slant'} eq 'roman') {
	    $font = $base + 2;
	} elsif ($a{'-weight'} eq 'bold'   && $a{'-slant'} eq 'italic') {
	    $font = $base + 3;
	} else {
	    my $e = "$a{'-weight'} $a{'-slant'}";
	    warn "Unknown handling for $e, fallback to normal roman\n"
		unless $font_warning{$e};
	    $font_warning{$e}++;
	    $font = $base;
	}
    }
    ($font, $a{'-size'});
}

package Tk::Canvas;

sub fig {
    my($c,@args) = @_;
    Tk::CanvasFig::save($c, @args);
}

1;

__END__

=head1 NAME

Tk::CanvasFig - additional Tk::Canvas methods for dealing with figs

=head1 SYNOPSIS

    use Tk::CanvasFig;
    $canvas->fig(-file => $filename);

=head1 DESCRIPTION

This module adds another method to the Tk::Canvas namespace: C<fig>.
The C<fig> method creates a xfig compatible file from the given
canvas. The output is written to a file if the C<-file> option is
specified, otherwise it is returned as a string. The creation of
images is only supported if the C<-imagedir> option is specified. The
module will try to use relative paths for the images, if possible.

=head1 BUGS

Not all canvas items are implemented (arcs, ovals).

Not everything is perfect.

=head1 SEE ALSO

L<Tk|Tk>, L<Tk::Canvas|Tk::Canvas>, L<xfig|xfig>

=head1 AUTHOR

Slaven Rezic <slaven.rezic@berlin.de>

=head1 COPYRIGHT

Copyright (c) 1998, 2001 Slaven Rezic. All rights reserved. This
module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
