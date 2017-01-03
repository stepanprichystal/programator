
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::HeliosConnector::HegMethodsThread;

#STATIC class

#3th party library

use strict;
use warnings;

# Local library
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub Do {
	my $self       = shift;
	my $methodName = shift;
	my @params     = @_;

	my @files = ();

	foreach my $p (@params) {
		my $file = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	 
		my $f;
		open( $f, ">", $file );
		print $f $p;
		close($f);
		
		push (@files, $file);
	}

	my $path = GeneralHelper->Root() . "\\Connectors\\HeliosConnector\\UpdateScript.pl";

	my $filesStr = join(" ", @files);
 

	my $result = system("perl $path $methodName $filesStr");
	
	if($result == 0){
		return 1;
	}else{
		return 0;
	}
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::HeliosConnector::HegMethodsThread';

	my $res = HegMethodsThread->Do("1UpdateNCInfo", "f52456", "test" );

	 

	#my $test = HegMethods->GetPcbName("f52456");

	#
	#	HegMethods->GetPcbOrderNumber("f52456");
	#	my $test = HegMethods->UpdatePcbOrderState("f52456-01", "HOTOVO-123");

	#	use aliased 'Connectors::HeliosConnector::HegMethods';
	#
	#	my $nc_info = "test";
	#
	#	my $test =  HegMethods->GetTpvCustomerNote("d06224");
	#

}

1;

