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
sub GetBaseCuThick {
	my $self      = shift;
	my $jobId     = shift;
	my $layerName = shift;

	my $cuThick;

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($jobId);

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick( $jobId, $layerName );
	}

	return $cuThick;
}

#return final thick of pcb in µm
sub GetFinalPcbThick {
	my $self  = shift;
	my $jobId = shift;

	my $thick;

	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($jobId);

		$thick = $stackup->GetFinalThick();
	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($jobId);
		$thick = $thick * 1000;
	}

	return $thick;
}

#Return 1 if stackup for pcb exist
sub StackupExist {
	my $self  = shift;
	my $jobId = shift;

	unless ( FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $jobId . "_" ) ) {

		return 0;
	}
	else {

		return 1;
	}

}

sub GetJobArchive {
	my $self  = shift;
	my $jobId = shift;
	
 	
	# old format - D12345
	if(length($jobId) == 6){
		
		return EnumsPaths->Jobs_ARCHIV . substr( $jobId, 0, 3 ) . "\\" . $jobId . "\\";
	}
	# new format  - D123456 
	else{
		
		return EnumsPaths->Jobs_ARCHIV . substr( $jobId, 0, 4 ) . "\\" . $jobId . "\\";
	}
 
}

sub GetJobOutput {
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->InCAM_jobs . $jobId . "\\output\\";

}

sub GetPcbType {
	my $self = shift;

	my $jobId = shift;

	my $isType = HegMethods->GetTypeOfPcb($jobId);
	my $type;

	if ( $isType eq 'Neplatovany' ) {

		$type = EnumsGeneral->PcbTyp_NOCOPPER;
	}
	elsif ( $isType eq 'Jednostranny' ) {

		$type = EnumsGeneral->PcbTyp_ONELAYER;

	}
	elsif ( $isType eq 'Oboustranny' ) {

		$type = EnumsGeneral->PcbTyp_TWOLAYER;

	}
	else {

		$type = EnumsGeneral->PcbTyp_MULTILAYER;
	}

	return $type;
}

sub GetIsolationByClass {
	my $self  = shift;
	my $class = shift;

	my $isolation;

	if ( $class <= 3 ) {

		$isolation = 400;

	}
	elsif ( $class <= 4 ) {

		$isolation = 300;

	}
	elsif ( $class <= 5 ) {

		$isolation = 200;

	}
	elsif ( $class <= 6 ) {

		$isolation = 150;

	}
	elsif ( $class <= 7 ) {

		$isolation = 125;

	}
	elsif ( $class <= 8 ) {

		$isolation = 100;
	}

	return $isolation;

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Helpers::JobHelper';

	print JobHelper->GetJobArchive("d164061" );

	#print "\n1";
}

1;

