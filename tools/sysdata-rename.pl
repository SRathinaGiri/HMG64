#!/usr/bin/perl
# sysdata-rename.pl - rewrite _HMG_SYSDATA[ <number> ] to _HMG_SYSDATA[ <NAME> ] (PHASE3-DESIGN.md S1)
#
#   perl tools/sysdata-rename.pl [--dry-run] <files...>
#
# Names come from INCLUDE/hmg_sysdata.ch (#define HMG_xxx <n>), so adding names there and
# re-running renames the next batch. Only the number inside the brackets changes; spacing,
# case and line breaks are kept, so line numbers (part of the generated code) do not move.
# Files that do not include hmg.ch / minigui.ch are skipped: the names would be undefined.
# Verify afterwards with tools/pcode-snapshot.ps1 (generated C must be byte-identical).
use strict; use warnings;
use File::Basename qw(dirname);

my $dry = 0;
if (@ARGV && $ARGV[0] eq '--dry-run') { $dry = 1; shift @ARGV; }

my $hdr = dirname(__FILE__) . '/../INCLUDE/hmg_sysdata.ch';
open my $h, '<', $hdr or die "cannot read $hdr: $!\n";
my %name;
while (<$h>) { $name{$2} = $1 if /^#define\s+(HMG_(?:CTL|FRM)_\w+)\s+(\d+)\b/; }
close $h;
die "no names found in $hdr\n" unless %name;

my ($files, $changed, $total) = (0, 0, 0);
for my $f (@ARGV) {
   open my $in, '<:raw', $f or die "cannot read $f: $!\n";
   local $/; my $src = <$in>; close $in;
   # Rename only below the include: above it the names do not exist yet.
   next unless $src =~ /#\s*include\s*["'<](?:hmg|minigui)\.ch["'>][^\n]*\n/i;
   my $cut = $+[0];
   my ($head, $body) = (substr($src, 0, $cut), substr($src, $cut));
   $files++;
   $body =~ s{(_HMG_SYSDATA\s*\[\s*)(\d+)(\s*\])}{ exists $name{$2} ? "$1$name{$2}$3" : "$1$2$3" }gie;
   $src = $head . $body;
   # count only real renames
   my $real = () = $src =~ /_HMG_SYSDATA\s*\[\s*HMG_(?:CTL|FRM)_\w+\s*\]/gi;
   next unless $real;
   $changed++; $total += $real;
   next if $dry;
   open my $out, '>:raw', $f or die "cannot write $f: $!\n";
   print $out $src; close $out;
}
printf "%s%d files scanned, %d changed, %d named references\n", ($dry ? '[dry run] ' : ''), $files, $changed, $total;
