#!/usr/bin/perl -w

# This script is used for copy greenshot image to specific directory
# 1) Script has to be converted to exe file by perl module
# cmd:
# pp -o snapshot.exe snapshot.pl
# 2) Then import to GreenShot through "external command"


#3th party library
use strict;
use warnings;
use File::Copy;
#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );
use lib qw( \\\\incam\\InCAM\\server\\site_data\\scripts);
use aliased 'Enums::EnumsPaths';


#input parameters

my $img = shift; 
 
my $p = EnumsPaths->Client_INCAMTMPOTHER . "snapshot".".png";
unlink($p);
copy( $img, $p ) or die "Copy failed: $!";
unlink($img);
 
exit(1);