#! /usr/bin/env perl

use strict;
use warnings;

use iCal::Parser;
use DateTime;

##### ARGS #####

my ($ical_file, $start_day, $categories_file) = @ARGV;

##### CONFIG #####

my $paper_w = 210;
my $paper_h = 297;

my %page_margins = (
	left => 5,
	right => 5,
	top => 5,
	bottom => 5
);

my $hour_width = 15;
my $day_height = 10;

my $num_days = 4;

##### CODE #####

my $hash = iCal::Parser->new()->parse($ical_file);

sub get_first_day {
	my ($str) = @_;
	
	my ($year, $mon, $day) = map { int } ($str =~ /(\d+)-(\d+)-(\d+)/);
	return DateTime->new(year => $year, month => $mon, day => $day);
}

my $cur_day = get_first_day($start_day);

my %categories;
if($categories_file) {
	open(my $fh, '<', $categories_file) or die "$!";
	while(<$fh>) {
		my ($cat, $stroke, $fill) = /(\S+) (\S+) (\S+)/;
		$categories{$cat} = [$stroke, $fill];
	}
	close($fh);
}

sub get_stroke_fill {
	my ($cat) = @_;

	if($cat && exists($categories{$cat})) {
		return @{$categories{$cat}}
	} else {
		return qw/black gray/;
	}
}

sub get_hash_key_for_day {
	my ($date) = @_;

	return $hash->{events}->{$date->year}->{$date->mon}->{$date->day};
}

print <<EOS;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${paper_w}mm" height="${paper_h}mm" viewBox="0 0 $paper_w $paper_h">
EOS

sub text {
	my ($x, $y, $text, $bold) = @_;

	my $wgt = '';
	if($bold) {
		$wgt = 'font-weight="bold" ';
	}

	print "<text x=\"$x\" y=\"$y\" font-size=\"4\" font-family=\"sans-serif\" $wgt text-anchor=\"middle\" dominant-baseline=\"middle\">$text</text>\n";
}

sub rect {
	my ($x, $y, $w, $h, $stroke, $fill, $opacity) = @_;

	print "<rect width=\"$w\" height=\"$h\" x=\"$x\" y=\"$y\" stroke-width=\"0.2\" stroke=\"$stroke\" fill=\"$fill\" opacity=\"$opacity\"/>\n";
}

sub escape_things {
	my ($text) = @_;

	$text =~ s/\\(.)/$1/g; # iCal::Parser seems buggy and doesn't do it
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;

	return $text;
}

my $first_minute_y = $page_margins{top} + $day_height;
my $last_minute_y = $paper_h - $page_margins{bottom};
my $minute_height = ($last_minute_y - $first_minute_y) / (24 * 60);

sub time_to_y {
	my ($h, $m) = @_;

	return $first_minute_y + $minute_height * ($h * 60 + $m);
}

foreach my $h (0 .. 24) {
	text($page_margins{left} + $hour_width / 2, time_to_y($h, 0), sprintf("%02d:00", $h), 1);
}

my $first_day_left = $page_margins{left} + $hour_width;
my $last_day_right = $paper_w - $page_margins{right};
my $daybox_width = ($last_day_right - $first_day_left) / $num_days;

for my $i (0 .. $num_days - 1) {
	my $day = get_hash_key_for_day($cur_day);

	my $x = $first_day_left + $i * $daybox_width;

	text($x + $daybox_width / 2,
		$page_margins{top} + $day_height / 2,
		$cur_day->day_name, 1);

	foreach my $ev (values %$day) {
		my ($start, $end) = map { $ev->{$_}->hour * 60 + $ev->{$_}->minute } qw/DTSTART DTEND/;
		$end = 24 * 60 if($ev->{DTEND}->day != $ev->{DTSTART}->day);

		my $start_y = time_to_y(0, $start);
		my $dur = $end - $start;
		my $box_height = $minute_height * $dur;
		
		rect($x, $start_y,
			$daybox_width, $box_height, 
			get_stroke_fill($ev->{CATEGORIES}), 0.2);
		text($x + $daybox_width/2, $start_y + $box_height / 2, escape_things($ev->{SUMMARY}), 0);
	}

	$cur_day->add(days => 1);
}

print <<EOS;
</svg>
EOS
