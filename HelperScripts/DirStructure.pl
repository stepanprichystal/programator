#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsPaths';

# Script create tmp structure on client PC
# Paths for log
#Client_INCAMTMPNC        => "c:\\tmp\\InCam\\scripts\\nc_export\\",
#  Client_INCAMTMPCHECKER => "c:\\tmp\\InCam\\scripts\\export_checker\\",
#  Client_INCAMTMPOTHER   => "c:\\tmp\\InCam\\scripts\\other\\",
#  Client_INCAMTMPSCRIPTS => "c:\\tmp\\InCam\\scripts\\",

unless ( -e EnumsPaths->Client_EXPORTFILES ) {
	mkdir( EnumsPaths->Client_EXPORTFILES ) or die "Can't create dir: " . EnumsPaths->Client_EXPORTFILES . $_;
}

unless ( -e EnumsPaths->Client_INCAMTMPNC ) {
	mkdir( EnumsPaths->Client_INCAMTMPNC ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPNC . $_;
}

unless ( -e EnumsPaths->Client_INCAMTMPCHECKER ) {
	mkdir( EnumsPaths->Client_INCAMTMPCHECKER ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPCHECKER . $_;
}

unless ( -e EnumsPaths->Client_INCAMTMPOTHER ) {
	mkdir( EnumsPaths->Client_INCAMTMPOTHER ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPOTHER . $_;
}

unless ( -e EnumsPaths->Client_INCAMTMPSCRIPTS ) {
	mkdir( EnumsPaths->Client_INCAMTMPSCRIPTS ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPSCRIPTS . $_;
}
