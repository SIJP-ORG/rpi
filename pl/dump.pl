#!/usr/bin/perl
#
# Utility: dumps out KVS created by barcode.pl
#
# Usage: ./dump.pl
#
use strict;
use File::Copy qw(move copy);
use File::Path qw(mkpath);
use GDBM_File;
use Data::Dumper;
local $Data::Dumper::Indent = 4;
local $Data::Dumper::Terse = 1;

my %kvs;
tie %kvs, 'GDBM_File', 'kvs.gdbm', &GDBM_WRCREAT, 0600;

foreach my $isbn (keys(%kvs))
{
    my $entry;
    my $code = $kvs{$isbn};
    $entry = eval $code;
    print "$isbn = ", Dumper \$entry;
    
}

untie %kvs;

__END__

Example Output:

pi@raspberrypi:~/src/bar $ ./dump.pl
9784885549687 = \{
    'publisher' => '電波新聞社',
    'issued' => '2008',
    'title' => '電子工作工具活用ガイド',
    'titleTranscription' => 'デンシ コウサク コウグ カツヨウ ガイド',
    'author' => '加藤芳夫 著,',
    'pubDate' => 'Mon, 20 Oct 2008 09:00:00 +0900'
  }
9784274067846 = \{
    'title' => '武蔵野電波のブレッドボーダーズ : 誰でも作れる!遊べる電子工作',
    'titleTranscription' => 'ムサシノ デンパ ノ ブレッド ボーダーズ : ダレ デモ ツクレル アソベル デンシ コウサク',
    'author' => 'スタパ齋藤, 船田戦闘機 共著,',
    'pubDate' => 'Fri, 15 Jan 2010 09:00:00 +0900',
    'publisher' => 'オーム社',
    'issued' => '2009'
  }
