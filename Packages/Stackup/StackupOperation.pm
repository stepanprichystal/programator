#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupOperation;

#3th party library

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#



#Return final thickness of pcb base on Cu layer number
sub GetThickByLayer {
	my $self     = shift;
	my $pcbId    = shift;    #pcb id
	my $layer    = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers
	my $noResist = shift;    #indicate id add resit

	my $thick = 0;           #total thick

	if ( HegMethods->GetTypeOfPcb($pcbId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($pcbId);

		$thick = $stackup->GetThickByLayerName($layer );
		
		my $cuLayer = $stackup->GetCuLayer($layer);
		
		#test by Mira, add 80um (except cores)
		if ( $cuLayer->GetType() eq EnumsGeneral->Layers_TOP || $cuLayer->GetType() eq EnumsGeneral->Layers_BOT ) {
			$thick += 0.080;
		}

	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($pcbId);
		
		#test by Mira, add 80um (except cores)
		$thick += 0.080;
	}


	

	#there are two resist from top and bottom. Top resis 40um + bottom 20um
	if ( !$noResist ) {
		$thick += 0.080;

	}

	return ( sprintf "%3.2f", ($thick) );
}


# If stackup contains core topmost or very bottom (Cu-core-cu-prepreg-Cu-core-cu)
# Return 1, else 0
sub OuterCore {
	my $self     = shift;
	my $pcbId    = shift;    #pcb id
	 
 	my $result = 0;
 
	if ( HegMethods->GetTypeOfPcb($pcbId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($pcbId);
		my @cores = $stackup->GetAllCores();
		
		my $firstC = $cores[0];
		my $lastC = $cores[scalar(@cores) -1];
		
		my $topCopper = $firstC->GetTopCopperLayer()->GetCopperName() ;
		
		my $botCopper = $lastC->GetBotCopperLayer()->GetCopperName();
		
		if($topCopper  eq "c" ||  $botCopper  eq "s"){
			
			$result = 1;
		}
		
	}
	
	return $result;
}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


	#use aliased 'Packages::Stackup::StackupOperation';

	#my $test = StackupOperation->OuterCore("f13610");

	 

	#print $test;

}

1;
