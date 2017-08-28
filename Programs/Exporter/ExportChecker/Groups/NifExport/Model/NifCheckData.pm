
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
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::Tooling::PressfitOperation';
use aliased 'Packages::CAMJob::Marking::Marking';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";

	# 1) datacode
	my $datacodeLayer = $self->__CheckDataCodeIS( $jobId, $groupData );

	unless ( defined $datacodeLayer ) {
		$dataMngr->_AddErrorResult( "Data code", "Nesedí zadaný datacode v heliosu s datacodem v exportu." );
	}
	
	my @errLayers= ();
	unless($self->__CheckDataCodeJob($inCAM, $jobId, $defaultInfo, $groupData->GetDatacode(), \@errLayers)){
		$dataMngr->_AddWarningResult( "Data code", "V zaškrtnutých vrstvách : \'".join(", ", @errLayers)."\' nebyl nalezen dynamický datakód. Zkontroluj to.");
	}

	# 2) ul logo
	my $ulLogoLayer = $self->__CheckUlLogoIS( $jobId, $groupData );

	unless ( defined $ulLogoLayer ) {
		$dataMngr->_AddErrorResult( "Ul logo", "Nesedí zadané Ul logo v heliosu s datacodem v exportu." );
	}

	# 3) mask control
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

	# 4) Control mask colour
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

	# 5) silk
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

	# 6) Control silk colour
	my %silkColorIS        = HegMethods->GetSilkScreenColor($jobId);
	my $silkColorTopExport = $groupData->GetC_silk_screen_colour();
	my $silkColorBotExport = $groupData->GetS_silk_screen_colour();

	if ( !defined $silkColorIS{"top"} ) {
		$silkColorIS{"top"} = "";
	}

	if ( !defined $silkColorIS{"bot"} ) {
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

	# 7) Check if dps should be pattern, if tenting is realz unchecked

	my $tenting = $self->__IsTentingCS( $inCAM, $jobId, $defaultInfo );
	my $tentingForm = $groupData->GetTenting();

	if ( !$tenting && $tentingForm ) {

		$dataMngr->_AddWarningResult( "Pattern", "Dps by mìla jít do výroby jako pattern, ale ve formuláši máš zaškrknutý tenting." );
	}

	# 8) Check if goldfinger exist, if area is greater than 10mm^2

	if ( $defaultInfo->LayerExist("c") && $defaultInfo->GetTypeOfPcb() ne "Neplatovany" ) {

		my %histC = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", "c" );
		my %histS = ();

		if ( $defaultInfo->LayerExist("s") ) {
			%histS = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", "s" );
		}

		if ( $histC{".gold_plating"} || $histS{".gold_plating"} ) {

			my $cuThickness = $defaultInfo->GetBaseCuThick("c");
			my $pcbThick    = JobHelper->GetFinalPcbThick($jobId);

			my %result = CamGoldArea->GetGoldFingerArea( $cuThickness, $pcbThick, $inCAM, $jobId, "panel" );

			if ( $result{"exist"} && $result{"area"} < 10 ) {

				my $area = sprintf( "%.2f", $result{"area"} );
				$dataMngr->_AddErrorResult( "Gold area",
											"Gold finger area must be greater then 10 cm2 (now area = $area cm2).\n Add more gold area." );
			}
		}
	}

	# 9) Control if exist customer panel and customer set in a same time

	my $custPnlExist = $defaultInfo->GetJobAttrByName("customer_panel");
	my $custSetExist = $defaultInfo->GetJobAttrByName("customer_set");
	if ( $custPnlExist eq "yes" &&  $custSetExist eq "yes" ) {
 
			$dataMngr->_AddErrorResult( "Panelisation",
								  "V atributech jobu je aktivní 'zákaznický panel' i 'zákaznické sady'. Zvol pouze jednu možnost panelizace." );
	}
	
	# Check all necessary attributes when customer panel
	if($custPnlExist eq "yes"){
		
		my $custPnlX = $defaultInfo->GetJobAttrByName("cust_pnl_singlex");
		my $custPnlY = $defaultInfo->GetJobAttrByName("cust_pnl_singley");
		
		if( !defined $custPnlX || !defined $custPnlY || $custPnlX == 0 || $custPnlY == 0 ){
			$dataMngr->_AddErrorResult( "Panelisation",
								  "V atributech jobu je aktivní 'zákaznický panel', ale informace není kompletní (atributy jobu: \"cust_pnl_singlex\", \"cust_pnl_singley\")");
		}
	}
	
	# Check all necessary attributes when customer set
	if($custSetExist eq "yes"){
		
		my $multipl = $defaultInfo->GetJobAttrByName("cust_set_multipl");
		
		if( !defined $multipl || $multipl == 0 ){
			$dataMngr->_AddErrorResult( "Panelisation",
								  "V atributech jobu je aktivní 'zákaznická sada', ale informace není kompletní (atribut jobu: \"cust_set_multipl\")");
		}
	}
	

	# 10) Check if exist pressfit, if is checked in nif
	if ( $defaultInfo->GetPressfitExist() && !$groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult( "Pressfit", "Nìkteré nástroje v dps jsou typu 'pressfit', možnost 'Pressfit' by mìla být použita." );
	}
	
	 # 11) Check if exist pressfit, if is checked in nif
	if ( $defaultInfo->GetMeritPressfitIS() && !$groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult( "Pressfit", "V IS je u dps požadavek na 'pressfit', volba 'Pressfit' by mìla být použita." );
	}

	# 12) if pressfit is checked, but is not in data
	if ( !$defaultInfo->GetPressfitExist() && $groupData->GetPressfit() ) {

		$dataMngr->_AddErrorResult(
			"Pressfit",
			"Volba 'Pressfit' je použita, ale žádné otvory typu pressfit nebyly nalezeny."
			  . " Prosím zruš volbu nebo pøidej pressfit otvory (ppomocí Drill Tool Manageru)."
		);
	}
 
	# 13) If exist pressfit, check if finsh size and tolerances are set
	if ( $groupData->GetPressfit() ) {

		$self->__CheckPressfitTools($dataMngr);
	}

}

# check if datacode exist
sub __CheckDataCodeIS {
	my $self      = shift;
	my $jobId     = shift;
	my $groupData = shift;

	my $layerIS     = HegMethods->GetDatacodeLayer($jobId);
	my $layerExport = $groupData->GetDatacode();

	return $self->__CheckMarkingLayer( $layerExport, $layerIS );
}

# Check when dynamic datacode exist in job
sub __CheckDataCodeJob {
	my $self      = shift;
	my $inCAM 	  = shift;
	my $jobId     = shift;
	my $defaultInfo = shift;
	my $dataCodes = shift;
	my $errLayers = shift;

	my $step = $defaultInfo->IsPool() ? "o+1" : "panel";

	 foreach my $layer (split(",", $dataCodes)){
	 	
	 		$layer = lc($layer);	 	
	 		unless(Marking->DatacodeExists($inCAM, $jobId, $step, $layer)){
	 			push(@{$errLayers}, $layer);
	 		}
	 }

	return scalar(@{$errLayers}) ? 0 : 1 ;
}

# check if ul logo exist
sub __CheckUlLogoIS {
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

	# convert to lower
	$layerExport = lc($layerExport);
	$layerIS     = lc($layerIS);

	# remove whitespaces
	$layerExport =~ s/\s//g;
	$layerIS     =~ s/\s//g;

	my $res = "";

	if ( $layerExport && $layerExport ne "" ) {

		$res = $layerExport;
	}
	elsif ( $layerIS && $layerIS ne "" ) {

		$res = $layerIS;
	}

	# case when marking in helios exist but in export no
	if ( $layerExport eq "" && $layerIS ne "" ) {
		$res = undef;    #error
	}

	# case, when marking is in IS and set in export too
	if ( defined $layerExport && defined $layerIS && ( $layerExport ne "" && $layerIS ne "" ) ) {

		$res = $layerIS;

		#test if marking are both same, as $layerExport as $layerIS

		# mraking is in format.: MC, C or as single value: MC
		my @exportLayers = split( ",", $layerExport );
		@exportLayers = sort { $a cmp $b } @exportLayers;

		my @isLayers = split( ",", $layerIS );
		@isLayers = sort { $a cmp $b } @isLayers;

		# if arrays are different, error
		unless ( @exportLayers ~~ @isLayers ) {
			$res = undef;    #error
		}

	}

	if ($res) {
		$res = uc($res);
	}

	return $res;
}

sub __IsTentingCS {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $defaultInfo = shift;

	unless ($defaultInfo) {
		return 1;
	}

	my $tenting = 0;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

		my $etch = $defaultInfo->GetEtchType("c");

		if ( $etch eq EnumsGeneral->Etching_TENTING ) {

			$tenting = 1;
		}

	}

	return $tenting;
}

# check if tool has finis size and tolerance
sub __CheckPressfitTools {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my @layers = PressfitOperation->GetPressfitLayers( $inCAM, $jobId, "panel", 1 );

	foreach my $l (@layers) {

		my @tools = CamDTM->GetDTMToolsByType( $inCAM, $jobId, "panel", $l, "press_fit", 1 );

		foreach my $t (@tools) {

			# test on finish size
			if (    !defined $t->{"gTOOLfinish_size"}
				 || $t->{"gTOOLfinish_size"} == 0
				 || $t->{"gTOOLfinish_size"} eq ""
				 || $t->{"gTOOLfinish_size"} eq "?" )
			{
				$dataMngr->_AddErrorResult( "Pressfit", "Tool: " . $t->{"gTOOLdrill_size"} . "µm has no finish size (layer: '" . $l . "'). Complete it.\n" );
			}

			if ( $t->{"gTOOLmin_tol"} == 0 && $t->{"gTOOLmax_tol"} == 0 ) {

				$dataMngr->_AddErrorResult( "Pressfit",
											"Tool: " . $t->{"gTOOLdrill_size"} . "µm hasn't defined tolerance (layer: '" . $l . "'). Complete it.\n" );
			}
		}
	}
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

