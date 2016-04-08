#!/usr/bin/perl
$hiddev = "/dev/hidraw2";
sysopen(SCAN, $hiddev, O_RDWR | O_EXCL) or die "cannot open $hiddev";
my $h = select(SCAN);
$| = 1;
select($h);

my $buf;
while (sysread(SCAN, $buf, 1) == 1)
{
    printf "[$buf]\n";
}
