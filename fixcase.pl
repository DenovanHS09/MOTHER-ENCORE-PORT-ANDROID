#!/usr/bin/perl
# Arregla diferencias de mayusculas/minusculas entre las rutas res:// que piden
# los archivos del juego y los nombres reales de los archivos (Linux/Android
# distinguen mayusculas; Windows no).
use strict;
use warnings;
use File::Find;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Copy qw(move copy);

my (%idx, @text, %refs);

find({ no_chdir => 1, wanted => sub {
	my $p = $File::Find::name;
	$p =~ s{^\./}{};
	return if $p eq '.';
	return if $p =~ m{^\.git(/|$)} or $p =~ m{^\.import(/|$)} or $p =~ m{^\.github(/|$)};
	return unless -f $p;
	$idx{lc $p} //= $p;
	push @text, $p if $p =~ /\.(tscn|tres|gd|cfg|godot)$/i;
}}, '.');

for my $f (@text) {
	open(my $fh, '<', $f) or next;
	while (my $l = <$fh>) {
		while ($l =~ m{res://([^"'\)\r\n]+)}g) { $refs{$1} = 1; }
	}
	close $fh;
}

my $fixed = 0;
for my $ref (sort keys %refs) {
	next if -e $ref;
	my $actual = $idx{lc $ref};
	next unless defined $actual and $actual ne $ref and -e $actual;
	make_path(dirname($ref));
	if ($refs{$actual}) { copy($actual, $ref); }
	else { move($actual, $ref); unlink "$actual.import" if -e "$actual.import"; }
	$idx{lc $ref} = $ref;
	$fixed++;
	print "fix: $actual -> $ref\n";
}
print "fixcase: $fixed archivos corregidos\n";
