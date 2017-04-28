#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: This script only run exporter utility in tray mode
# Author:SPR
#-------------------------------------------------------------------------------------------#

use strict;
use warnings;

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;
#
#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';

print STDERR "Su yze3e";

my $output = shift(@_); # save here output message
my $methodName = shift(@_);

my @params = ();
while ( my $p = shift(@_) ) {

	push( @params, $p );
	print STDERR $p."\n";
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

}elsif ( $methodName eq "UpdateSilkScreen" ) {

	$result = HegMethods->UpdateSilkScreen(@params);

	if ( $result =~ /success/i ) {
		$result = 0;
	}
	else {
		$result = 1;
	}

}elsif ( $methodName eq "UpdateSolderMask" ) {

	$result = HegMethods->UpdateSolderMask(@params);

	if ( $result =~ /success/i ) {
		$result = 0;
	}
	else {
		$result = 1;
	}
	
} 
 
 
 
 
 

1;

#unlink $infoStrPath;

