#!/usr/bin/perl -I /home/audris/lib64/perl5 -I /da3_data/lookup

use strict;
use warnings;
use Error qw(:try);
use cmt;
use TokyoCabinet;
use Compress::LZF;


my %b2c;
my $sec;
my $nsec = 8;
$nsec = $ARGV[1] if defined $ARGV[1];


my (%c2p, %c2p1);
my $lines = 0;
my $f0 = "";
while (<STDIN>){
  chop();
  $lines ++;
  if (!($lines%15000000000)){
    output ();
    %c2p1 = ();
  }    
  my ($hsha, $f, $p, $b) = split (/\;/, $_, -1);
  next if defined $badCmt{$hsha};
  #print "$.;$hsha;$f;\n";
  my $sha = fromHex ($hsha);
  $f =~ s/;/SEMICOLON/g;
  $f =~ s|^/*||;
  $c2p1{$sha}{$f}++;
  print STDERR "$lines done\n" if (!($lines%100000000));
}

for $sec (0..($nsec -1)){
  my $fname = "$ARGV[0].$sec.tch";
  $fname = "$ARGV[0]" if $nsec == 1;
  tie %{$c2p{$sec}}, "TokyoCabinet::HDB", "$fname", TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT,   
        16777213, -1, -1, TokyoCabinet::TDB::TLARGE, 100000
     or die "cant open $fname\n";
}

output ();

for $sec (0..($nsec -1)){
  untie %{$c2p{$sec}};
}

sub output { 
  while (my ($k, $v) = each %c2p1){
    my $str = join ';', sort keys %{$v};
    my $sec = (unpack "C", substr ($k, 0, 1))%$nsec;
    $c2p{$sec}{$k} = safeComp ($str);
  }
}


