
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::Model::PreCheckData;

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsProducPanel';

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

	my $defaultInfo = $dataMngr->GetDefaultInfo();

	my @sig      = $defaultInfo->GetSignalLayers();
	my $layerCnt = $defaultInfo->GetLayerCnt();

	# 1) Check if pcb class is at lest 3
	my $pcbClass = $defaultInfo->GetPcbClass();
	if ( !defined $pcbClass || $pcbClass < 3 ) {

		$dataMngr->_AddErrorResult( "Pcb class",
									"Pcb class is equal to \"$pcbClass\". Check job attribute: \"PcbClass\" and set at least value \"3\".\n" );
	}

	# 1) Check if layers has set polarity
	my @layers = @{ $groupData->GetSignalLayers() };

	foreach my $lInfo (@layers) {

		unless ( defined $lInfo->{"etchingType"} ) {
			$dataMngr->_AddErrorResult( "Layer etching", "Layer " . $lInfo->{"name"} . " doesn't have set etchingType." );
		}
	}

	# 2) check if layer doesn't contain spaces
	my @allL = CamJob->GetAllLayers( $inCAM, $jobId );

	foreach my $lInfo (@allL) {

		if ( $lInfo->{"gROWname"} =~ /\s/ ) {

			$dataMngr->_AddErrorResult( "Layer check", "Layer: " . $lInfo->{"gROWname"} . " contain whitespaces. Layer can't contain whitespaces." );
		}

	}

	# 3) check if layers are in right order

	my $err = 0;

	for ( my $i = 1 ; $i <= $layerCnt ; $i++ ) {

		my $l = $sig[ $i - 1 ];

		if ( $i == 1 ) {

			if ( $l->{"gROWname"} ne "c" ) {
				$err = 1;
			}

		}
		elsif ( $i == $layerCnt ) {

			if ( $l->{"gROWname"} ne "s" ) {
				$err = 1;
			}

		}
		else {

			#inner layers
			if ( $l->{"gROWname"} !~ /^v$i$/ ) {
				$err = 1;
			}
		}
	}

	if ($err) {
		$dataMngr->_AddErrorResult( "Layer check", "Order of signal layers in matrix is wrong. Fix it." );
	}

	# 4) Check if material and pcb thickness and base cuthickness is set
	my $materialKind = $defaultInfo->GetMaterialKind();
	$materialKind =~ s/[\s\t]//g;

	my $pcbType = $defaultInfo->GetTypeOfPcb();

	my $baseCuThickHelios = HegMethods->GetOuterCuThick($jobId);
	my $pcbThickHelios    = HegMethods->GetPcbMaterialThick($jobId);

	# 5) Check if helios contain base cutthick, pcb thick
	if ( $layerCnt >= 1 && $pcbType ne "Neplatovany" ) {

		unless ( defined $baseCuThickHelios ) {

			$dataMngr->_AddErrorResult( "Base Cu", "Base Cu thickness is not defined in Helios." );
		}

		unless ( defined $pcbThickHelios ) {

			$dataMngr->_AddErrorResult( "Pcb thickness", "Pcb thickness is not defined in Helios." );
		}
	}

	# 6) Check if helios contain material kind
	unless ( defined $materialKind ) {

		$dataMngr->_AddErrorResult( "Material", "Material kind (Fr4, IS400, etc..) is not defined in Helios." );
	}

	# If multilayer
	if ( $layerCnt > 2 && $materialKind && $pcbThickHelios ) {

		# a) test id material in helios, match material in stackup
		my $stackKind = $defaultInfo->GetStackup()->GetStackupType();

		#exception DE 104 eq FR4
		if ( $stackKind =~ /DE 104/i ) {
			$stackKind = "FR4";
		}

		$stackKind =~ s/[\s\t]//g;

		unless ( $materialKind =~ /$stackKind/i || $stackKind =~ /$materialKind/i ) {

			$dataMngr->_AddErrorResult( "Stackup material",
							"Stackup material doesn't match with material in Helios. Stackup material: $stackKind, Helios material: $materialKind." );
		}

		# b) test if created stackup match thickness in helios +-5%
		my $stackThick = $defaultInfo->GetStackup()->GetFinalThick() / 1000;

		unless ( $pcbThickHelios * 0.90 < $stackThick && $pcbThickHelios * 1.10 > $stackThick ) {

			$stackThick     = sprintf( "%.2f", $stackThick );
			$pcbThickHelios = sprintf( "%.2f", $pcbThickHelios );

			$dataMngr->_AddErrorResult( "Stackup thickness",
										"Stackup thickness ($stackThick) isn't match witch thickness in Helios ($pcbThickHelios) +-10%." );

		}

	}

	# 7) Check if contain negative layers, if powerground type is set and vice versa

	my @sigLayers = $defaultInfo->GetSignalLayers();

	foreach my $l (@sigLayers) {

		if (    ( $l->{"gROWpolarity"} eq "negative" && $l->{"gROWlayer_type"} ne "power_ground" )
			 || ( $l->{"gROWpolarity"} ne "negative" && $l->{"gROWlayer_type"} eq "power_ground" ) )
		{

			$dataMngr->_AddErrorResult(
										"Negative layer",
										"Layer: "
										  . $l->{"gROWname"}
										  . " has type: '"
										  . $l->{"gROWlayer_type"}
										  . "' and polarity: '"
										  . $l->{"gROWpolarity"}
										  . "'. It is wrong. Set polarity 'negative' and type 'power_ground'."
			);
		}
	}

	# 8) check if  if positive inner layer contains theraml pads
	if ( $defaultInfo->GetLayerCnt() > 2 ) {

		my @layers = $defaultInfo->GetSignalLayers();

		foreach my $l (@layers) {

			if ( $l->{"gROWname"} =~ /^v\d$/ ) {

				my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );

				if ( $l->{"gROWpolarity"} eq "negative" ) {
					next;
				}

				my @thermalPads = grep { $_->{"sym"} =~ /th/ } @{ $symHist{"pads"} };

				if ( scalar(@thermalPads) ) {
					$dataMngr->_AddErrorResult(
												"Inner layers",
												"Layer : \""
												  . $l->{"gROWname"}
												  . "\" contains thermal pads and is type: \"positive\". Are you sure, layer shouldn't be negative?"
					);
				}

			}
		}
	}

	# 9) Check if board base layers, not contain attribute .rout_chan

	foreach my $l ( $defaultInfo->GetBoardBaseLayers() ) {

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", $l->{"gROWname"}, 1 );

		if ( $attHist{".rout_chain"} || $attHist{".comp"} ) {

			$dataMngr->_AddErrorResult( "Rout attributes",
									 "Layer : " . $l->{"gROWname"} . " contains rout attributes: '.rout_chain' or '.comp'. Delete them from layer." );
		}
	}

	# 10) Check if dimension of panel are ok, depand on finish surface
	my $surface   = $defaultInfo->GetPcbSurface($jobId);
	my $pcbThick  = $defaultInfo->GetPcbThick($jobId);
	my $panelType = $defaultInfo->GetPanelType();

	# if HAL PB , and thisck < 1.5mm => onlz small panel
	if (    $surface =~ /A/i 
		 && $pcbThick < 1500
		 && ( $panelType eq EnumsProducPanel->SIZE_MULTILAYER_BIG || $panelType eq EnumsProducPanel->SIZE_STANDARD_BIG ) )
	{
		$dataMngr->_AddErrorResult( "Panel dimension",
									"Nelze použít velký rozměr panelu protože surface je olovnatý HAL a zároveň tl. desky je menší 1,5mm");
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

