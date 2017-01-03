#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';

my $methodName = shift(@_);

my @paramFiles = ();
while ( my $p = shift(@_) ) {

	push( @paramFiles, $p );

}

# convert file to variale
my @params = ();
foreach my $f (@paramFiles) {

	if ( -e $f ) {

		push( @params, FileHelper->ReadAsString($f) );
		unlink($f);
	}
}

my $result = 1;

if ( $methodName eq "UpdateNCInfo" ) {

	$result = HegMethods->UpdateNCInfo(@params);

	if ( $result =~ /success/i ) {
		$result = 0;
	}
	else {
		$result = 1;
	}

}
elsif ( $methodName eq "UpdatePcbOrderState" ) {

	$result = HegMethods->UpdatePcbOrderState(@params);

	if ( $result =~ /success/i ) {
		$result = 0;
	}
	else {
		$result = 1;
	}

}

exit($result);

#unlink $infoStrPath;

