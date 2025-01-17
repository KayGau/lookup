#!/usr/bin/perl -I /home/audris/lib64/perl5 -I /home/audris/lib/x86_64-linux-gnu/perl -I /home/audris/lookup
use strict;
use warnings;
use Error qw(:try);
use cmt;
use Compress::LZF;

my $debug = 0;
$debug = $ARGV[0]+0 if defined $ARGV[0];
my $sections = 128;
my $sec = -1;
$sec = $ARGV[1]+0 if defined $ARGV[1];
my $tail = 0;
$tail = $ARGV[2]+0 if defined $ARGV[2];
my $fbase="/data/All.blobs/commit_";
for my $s (0..($sections-1)){
  next if $sec >= 0 && $sec != $s;
  open A, "$fbase$s.idx";
  if ($tail){
    open A, "tail -$tail $fbase$s.idx|";
  }
  open FD, "$fbase$s.bin";
  binmode(FD);
  while (<A>){
    chop();
    my ($nn, $of, $len, $hash) = split (/\;/, $_, -1);
    my $h = fromHex ($hash);
    #seek (FD, $bof, 2);
    seek (FD, $of, 0) if $tail;
    my $codeC = "";
    my $rl = read (FD, $codeC, $len);
    if ($debug >= 0){
      cleanCmt ($codeC, $hash, $debug);
    }else{
      my ($ta, $tc) = getTime ($codeC, $hash);
      $ta =~ s/ .*//;
      print "$hash\;$ta\n";
    }
  }
}

1;
