#!/usr/bin/perl
#
# RPi: PoC: ISBN Barcode Scanner Sample w/ USB UVC camera
#
# Usage 1: laser scanner mode
#   Attach the laser scanner and run:
#   $ hidscan/hidscan
#   Once it reads a barcode, it launches this script with the 1st
#   argument being the barcode string.
#
#   Once this script obtains a valid ISBN code, this script then sends
#   a request to NDL OpenSearch API to retrieve book data from the
#   ISBN code.
#       http://iss.ndl.go.jp/api/opensearch?isbn=[ISBN_CODE]
#
#   The book data is then stored in a KVS (kvs.gdbm) as a hash like this.
#   {
#      ISBN_code => 'serialized_book_data',
#   };
#
#   You can dump out the KVS contents by dump.pl.
#
# Usage 2: image recognition mode with official RPi camera module
#   $ apt-get install zbar-tools
#
#   Hack your camera module to shorten focual length to 5cm or so.
#   Make sure zbarimg can preview the video.
#   Put your barcode in front of the camera.
#   Once this script obtains a valid ISBN code, the remaining part is
#   the same as above.
#   This achieves good frame rate (~30fps) but requires physical hack
#   that may break your camera module.
#
# Usage 3: image recognition mode with USB UVC camera (diabled)
#   $ apt-get install zbar-tools
#
#   Attach a USB UVC web cam on RPi3 and run this script.
#   Make sure zbarimg can preview the video.
#   Put your barcode in front of the camera.
#   Once this script obtains a valid ISBN code, the remaining part is
#   the same as above.
#   A drawback is low frame rate (1-2fps).
#

use strict;
use GDBM_File;
use Data::Dumper;
local $Data::Dumper::Indent = 4;
local $Data::Dumper::Terse = 1;

my %kvs;
tie %kvs, 'GDBM_File', 'kvs.gdbm', &GDBM_WRCREAT, 0600;
my $num = 0;

my ($isbn) = @ARGV;

if ($isbn =~ /^(9\d{12})/) # laser scanner mode
{
    print "Find: ISBN: $isbn\n";
    ProcessISBN($isbn);
}
else # image recognition (camera) mode
{
    system("v4l2-ctl --overlay=1");
    open ZBAR, "zbarcam -v --nodisplay --prescale=640x480 |"  or die "cannot open zbarimg";
    my $isbn = "";
    while (<ZBAR>)
    {
	print;
	if (/^EAN-13:(9\d{12})/)
	{
	    $isbn = $1;
	    ProcessISBN($isbn);
	}
    }
    close ZBAR;
    system("v4l2-ctl --overlay=0");
}

sub ProcessISBN
{
    my ($isbn) = @_;
    my $request = "curl http://iss.ndl.go.jp/api/opensearch?isbn=$isbn";
    print "OK: request=$request\n";
    open CURL, "$request|" or die "cannot open curl";
    my @curl = <CURL>;
    close CURL;

    # parse API response and create a concise hash, then store it in a KVS
    my $entry = ParseResponse(@curl);
    $kvs{$isbn} = $entry;
}

# Parse NDL API response and create a concise hash
# (Very quick&easy XML parsing code)
sub ParseResponse
{
    my @curl = @_;
    my %entry = ();
    my %wants = (
	'author' => 'author',
	'pubDate' => 'pubDate',
	'dc:title' => 'title',
	'dcndl:titleTranscription' => 'titleTranscription',
	'dc:publisher' => 'publisher',
	'dcterms:issued' => 'issued',
	);
    
    while ($_ = shift @curl)
    {
	my ($key,$value) = /\<(\S+).*\>(.*)\<\/.*\>/;
	if (defined $wants{$key})
	{
	    $entry{$wants{$key}} =$value;
	}
    }

    my $text = Dumper \%entry;
    print $text;
    return $text;
}

__END__

cf. examples

This code creates following hash from good1.jpg

9784274067846 = \{
    'title' => '武蔵野電波のブレッドボーダーズ : 誰でも作れる!遊べる電子工作',
    'titleTranscription' => 'ムサシノ デンパ ノ ブレッド ボーダーズ : ダレ デモ ツクレル アソベル デンシ コウサク',
    'author' => 'スタパ齋藤, 船田戦闘機 共著,',
    'pubDate' => 'Fri, 15 Jan 2010 09:00:00 +0900',
    'publisher' => 'オーム社',
    'issued' => '2009'
  }

cf. more examples

pi@raspberrypi:~/src/bar $ zbarimg ~/my_photo-1.jpg 
EAN-13:1923055024007
EAN-13:9784274067846
scanned 2 barcode symbols from 1 images in 0.59 seconds

pi@raspberrypi:~/src/bar $ curl http://iss.ndl.go.jp/api/opensearch?isbn=9784274067846

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3241  100  3241    0     0   6030      0 --:--:-- --:--:-- --:--:--  6035
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dcterms="http://purl.org/dc/terms/" version="2.0" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dcndl="http://ndl.go.jp/dcndl/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
  <channel>
    <title>9784274067846 - 国立国会図書館サーチ OpenSearch</title>
    <link>http://iss.ndl.go.jp/api/opensearch?isbn=9784274067846</link>
    <description>Search results for isbn=9784274067846 </description>
    <language>ja</language>
    <openSearch:totalResults>1</openSearch:totalResults>
    <openSearch:startIndex>1</openSearch:startIndex>
    <openSearch:itemsPerPage></openSearch:itemsPerPage>
    <item>
      <title>武蔵野電波のブレッドボーダーズ : 誰でも作れる!遊べる電子工作</title>
      <link>http://iss.ndl.go.jp/books/R100000002-I000010637507-00</link>
<description>
<![CDATA[<p>オーム社,9784274067846</p>
<ul><li>タイトル： 武蔵野電波のブレッドボーダーズ : 誰でも作れる!遊べる電子工作</li>
<li>タイトル（読み）： ムサシノ デンパ ノ ブレッド ボーダーズ : ダレ デモ ツクレル アソベル デンシ コウサク</li>
<li>責任表示： スタパ齋藤, 船田戦闘機 共著,</li>
<li>NDC(9)： 549</li>
</ul>]]>
</description>
      <author>スタパ齋藤, 船田戦闘機 共著,</author>
      <category>本</category>
      <guid isPermaLink="true">http://iss.ndl.go.jp/books/R100000002-I000010637507-00</guid>
      <pubDate>Fri, 15 Jan 2010 09:00:00 +0900</pubDate>
      <dc:title>武蔵野電波のブレッドボーダーズ : 誰でも作れる!遊べる電子工作</dc:title>
      <dcndl:titleTranscription>ムサシノ デンパ ノ ブレッド ボーダーズ : ダレ デモ ツクレル アソベル デンシ コウサク</dcndl:titleTranscription>
      <dc:creator>スタパ齋藤, 船田戦闘機 共著</dc:creator>
      <dc:publisher>オーム社</dc:publisher>
      <dcterms:issued xsi:type="dcterms:W3CDTF">2009</dcterms:issued>
      <dc:identifier xsi:type="dcndl:ISBN">9784274067846</dc:identifier>
      <dc:identifier xsi:type="dcndl:JPNO">21692984</dc:identifier>
      <dc:identifier xsi:type="dcndl:NSMARCNO">104228500</dc:identifier>
      <dc:subject>電子工学</dc:subject>
      <dc:subject>工具</dc:subject>
      <dc:subject>発光ダイオード</dc:subject>
      <dc:subject xsi:type="dcndl:NDLC">ND351</dc:subject>
      <dc:subject xsi:type="dcndl:NDC9">549</dc:subject>
      <dcterms:description>索引あり</dcterms:description>
      <rdfs:seeAlso rdf:resource="http://id.ndl.go.jp/bib/000010637507"/>
      <rdfs:seeAlso rdf:resource="http://www.library.pref.fukui.jp/winj/opac/switch-detail-iccap.do?bibid=1104887286"/>
      <rdfs:seeAlso rdf:resource="http://web.oml.city.osaka.lg.jp/webopac_i_ja/0011976155"/>
      <rdfs:seeAlso rdf:resource="https://www.library.pref.osaka.jp/licsxp-opac/WOpacMsgNewListToTifTilDetailAction.do?tilcod=10020901635288"/>
    </item>
  </channel>
</rss>

