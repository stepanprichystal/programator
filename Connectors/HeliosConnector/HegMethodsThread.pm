
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
 use aliased 'Packages::SystemCall::SystemCall';
 
 use aliased 'Connectors::EnumsErrors';

use aliased 'Packages::Exceptions::HeliosException';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub Do {
	my $self       = shift;
	my $methodName = shift;
	my @params     = @_;



   my $script =  GeneralHelper->Root() . "\\Connectors\\HeliosConnector\\UpdateScript.pl";
	
	my $systemCall = SystemCall->new($script, $methodName,  @params);
	my $result = $systemCall->Run();

	unless($result){
		
		my $out = $systemCall->GetOutput();
		die HeliosException->new( EnumsErrors->HELIOSDBREADERROR, "no details" )
	}


 
	return $result;
 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::HeliosConnector::HegMethodsThread';

	my $res = HegMethodsThread->Do("1UpdateNCInfo", "00f52456", "test" );

	 

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

