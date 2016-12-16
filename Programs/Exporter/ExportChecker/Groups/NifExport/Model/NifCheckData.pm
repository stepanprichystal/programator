
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
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';
use aliased 'Helpers::ValueConvertor';
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
sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";


	#datacode
	my $datacodeLayer = $self->__GetDataCode( $jobId, $groupData );

	unless ( defined $datacodeLayer ) {
		$dataMngr->_AddErrorResult( "Data code", "Nesedí zadaný datacode v heliosu s datacodem v exportu." );
	}

	#datacode
	my $ulLogoLayer = $self->__GetUlLogo( $jobId, $groupData );

	unless ( defined $ulLogoLayer ) {
		$dataMngr->_AddErrorResult( "Ul logo", "Nesedí zadané Ul logo v heliosu s datacodem v exportu." );
	}

	#mask
	my %masks = CamLayer->ExistSolderMasks( $inCAM, $jobId );
	my $topMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "mc" );
	my $botMaskExist = CamHelper->LayerExists( $inCAM, $jobId, "ms" );

	# Control mask existence
	if ( $masks{"top"} != $topMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska TOP", "Nesedí maska top v metrixu jobu a ve formuláøi Heliosu" );
	}
	if ( $masks{"bot"} != $botMaskExist ) {

		$dataMngr->_AddErrorResult( "Maska BOT", "Nesedí maska bot v metrixu jobu a ve formuláøi Heliosu" );
	}

	# Control mask colour
	my %masksColorIS        = HegMethods->GetSolderMaskColor($jobId);
	my $masksColorTopExport = $groupData->GetC_mask_colour();
	my $masksColorBotExport = $groupData->GetS_mask_colour();

	if ( $masksColorIS{"top"} ne $masksColorTopExport ) {

		$dataMngr->_AddErrorResult(
									"Maska TOP",
									"Nesedí barva masky top. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorTopExport)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColorIS{"top"} ) . "."
		);
	}
	if ( $masksColorIS{"bot"} ne $masksColorBotExport ) {

		$dataMngr->_AddErrorResult(
									"Maska BOT",
									"Nesedí barva masky bot. Export =>"
									  . ValueConvertor->GetMaskCodeToColor($masksColorBotExport)
									  . ", Helios => "
									  . ValueConvertor->GetMaskCodeToColor( $masksColorIS{"bot"} ) . "."
		);
	}

	#silk
	my %silk = CamLayer->ExistSilkScreens( $inCAM, $jobId );
	my $topSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "pc" );
	my $botSilkExist = CamHelper->LayerExists( $inCAM, $jobId, "ps" );

	# Control silk existence
	if ( $silk{"top"} != $topSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk TOP", "Nesedí potisk top v metrixu jobu a ve formuláøi Heliosu" );
	}
	if ( $silk{"bot"} != $botSilkExist ) {

		$dataMngr->_AddErrorResult( "Potisk BOT", "Nesedí potisk bot v metrixu jobu a ve formuláøi Heliosu" );
	}

	# Control silk colour
	my %silkColorIS        = HegMethods->GetSilkScreenColor($jobId);
	my $silkColorTopExport = $groupData->GetC_silk_screen_colour();
	my $silkColorBotExport = $groupData->GetS_silk_screen_colour();
	
	
	if(!defined $silkColorIS{"top"}){
		$silkColorIS{"top"} = "";
	}
	
	 if(!defined $silkColorIS{"bot"}){
		$silkColorIS{"bot"} = "";
	}
	

	if ( $silkColorIS{"top"} ne $silkColorTopExport ) {

		$dataMngr->_AddErrorResult(
									"Potisk TOP",
									"Nesedí barva potisku top. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorTopExport)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColorIS{"top"} ) . "."
		);
	}
	if ( $silkColorIS{"bot"} ne $silkColorBotExport ) {

		$dataMngr->_AddErrorResult(
									"Potisk BOT",
									"Nesedí barva potisku bot. Export =>"
									  . ValueConvertor->GetSilkCodeToColor($silkColorBotExport)
									  . ", Helios => "
									  . ValueConvertor->GetSilkCodeToColor( $silkColorIS{"bot"} ) . "."
		);
	}
}

# check if datacode exist
sub __GetDataCode {
	my $self      = shift;
	my $jobId     = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetDatacodeLayer($jobId);
	my $layerExport = $groupData->GetDatacode();

	return $self->__CheckMarkingLayer( $layerExport, $layerIS );
}

# check if ul logo exist
sub __GetUlLogo {
	my $self      = shift;
	my $jobId     = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetUlLogoLayer($jobId);
	my $layerExport = $groupData->GetUlLogo();

	return $self->__CheckMarkingLayer( $layerExport, $layerIS );
}

sub __CheckMarkingLayer {
	my $self        = shift;
	my $layerExport = shift;
	my $layerIS     = shift;

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

