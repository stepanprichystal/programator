
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifCheckData;



#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# Checking group data before final export
# Errors, warnings are passed to <$dataMngr>
sub OnCheckGroupData{
	my $self = shift;
	my $dataMngr = shift;	#instance of GroupDataMngr

	my %groupData = $dataMngr->GetGroupData();
	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";
	
	#DELETE
	#sleep(1);
	#$dataMngr->_AddWarningResult("Test 1", "Nejake varovani 1");
	#$dataMngr->_AddWarningResult("Test 2", "Nejake varovani 2");
	
	

	
	#datacode
	my $datacodeLayer = $self->__GetDataCode($jobId, \%groupData);

	unless ( defined $datacodeLayer ) {
		$dataMngr->_AddErrorResult("Data code", "Nesedi zadany datacode v heliosu s datacodem v exportu.");
	}

	#datacode
	my $ulLogoLayer = $self->__GetUlLogo($jobId, \%groupData);

	unless ( defined $ulLogoLayer ) {
		$dataMngr->_AddErrorResult("Ul logo", "Nesedi zadane Ul logo v heliosu s datacodem v exportu.");
	}
	
	#mask
	my %masks        = CamLayer->ExistSolderMasks( $inCAM, $jobId );
	my %masks2       = HegMethods->GetSolderMaskColor($jobId);
	my $topMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "mc" );
	my $botMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "ms" );

	if ( $masks{"top"} != $topMaskExist ) {
		
		$dataMngr->_AddErrorResult("Maska TOP", "Nesedi maska top v datech a v heliosu");
	}
	if ( $masks{"bot"} != $botMaskExist ) {
		
		$dataMngr->_AddErrorResult("Maska BOT", "Nesedi maska bot v datech a v heliosu");
	}

	#silk
	my %silk         = CamLayer->ExistSilkScreens( $inCAM, $jobId );
	my %silk2        = HegMethods->GetSilkScreenColor($jobId);
	my $topSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "pc" );
	my $botSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "ps" );

	if ( $silk{"top"} != $topSilkExist ) {
		
		$dataMngr->_AddErrorResult("Potisk TOP","Nesedi potisk top v datech a v heliosu");
		
	}
	if ( $silk{"bot"} != $botSilkExist ) {
		
		$dataMngr->_AddErrorResult("Potisk BOT","Nesedi potisk bot v datech a v heliosu");

	}
}



# check if datacode exist
sub __GetDataCode {
	my $self = shift;
	my $jobId = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetDatacodeLayer($jobId);
	my $layerExport = $groupData->{"datacode"};
	
	return  $self->__CheckMarkingLayer($layerExport, $layerIS);
}
 
# check if ul logo exist
sub __GetUlLogo {
	my $self = shift;
	my $jobId = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetUlLogoLayer($jobId);
	my $layerExport = $groupData->{"ul_logo"};
	
	return  $self->__CheckMarkingLayer($layerExport, $layerIS);
} 
 
 
sub __CheckMarkingLayer {
	my $self = shift;
	my $layerExport = shift;
	my $layerIS = shift;	
	
	my $res = "";

	if ( $layerExport && $layerExport ne "" ) {

		$res = $layerExport;
	}
	elsif ( $layerIS && $layerIS ne "" ) {

		$res = $layerIS;
	}

	# case, when marking is in IS and set in export too
	if ( ( $layerExport && $layerExport ne "" ) && ( $layerIS && $layerIS ne "" ) ) {

		$res = $layerIS;

		#test if marking are both same, as $layerExport as $layerIS
		$layerExport = uc($layerExport);
		$layerIS     = uc($layerIS);

		if ( $layerIS && $layerExport ) {
			if ( $layerExport ne $layerIS ) {

				$res = undef;    #error
			}
		}

	}

	if ($res) {
		$res = uc($res);
	}

	return $res;
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

