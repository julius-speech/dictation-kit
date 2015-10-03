#!/usr/bin/perl

require 'getcwd.pl';

while(@ARGV) {
	$s = shift;
	if ($s !~ /^\//) {
		$s = getcwd() . "/" . $s;
	}
	print "$s\n";

}
