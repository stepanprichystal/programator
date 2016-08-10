#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::JobHelper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#


# Return base cu thick by layer
sub GetBaseCuThick{
	my $self = shift;
	my $jobId = shift;
	my $layerName = shift;
	
	
	my $cuThick;
	
	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new( $jobId );

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {
		
		$cuThick = HegMethods->GetOuterCuThick($jobId, $layerName);
	}
	
	return $cuThick;
}

#return final thick of pcb in µm
sub GetFinalPcbThick{
	my $self = shift;
	my $jobId = shift;
	
	my $thick;
	
	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new( $jobId );

		$thick = $stackup->GetFinalThick();
	}
	else {
		
		$thick = HegMethods->GetPcbMaterialThick($jobId);	
		$thick = $thick*1000;
	}
	
	return $thick;
}


#Return 1 if stackup for pcb exist
sub StackupExist{
	my $self = shift;
	my $jobId = shift;
	
	unless ( FileHelper->ExistsByPattern( EnumsPaths->Jobs_STACKUPS, $jobId . "_" ) ) {
		
		return 0;
	}else{
		
		return 1;
	}
	
}

sub GetJobArchive{
	my $self = shift;
	my $jobId = shift;
	
	return EnumsPaths->Jobs_ARCHIV . substr( $jobId, 0, 3 ) . "\\" . $jobId . "\\";
	
}

sub GetJobOutput{
	my $self = shift;
	my $jobId = shift;
	
	
	return EnumsPaths->InCAM_jobs.$jobId."\\output\\";
	
}



 


 #-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Helpers::JobHelper';
		 
			 
	print	 JobHelper->GetFinalPcbThick("F13608");
 	#print JobHelper->GetBaseCuThick("F13608", "v3");
	 
print "\n1";
}

1;
 







1;
