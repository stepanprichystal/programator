
#-------------------------------------------------------------------------------------------#
# Description: Class, cover whole logic for exporting, merging, staging nc layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::ExportMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::NCExport::Enums';
use aliased 'Packages::Export::NCExport::Helpers::Helper';

use aliased 'Packages::Export::NCExport::ExportPanelAllMngr';
use aliased 'Packages::Export::NCExport::ExportPanelSingleMngr';
use aliased 'Packages::Export::NCExport::ExportPanelCouponMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 1;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"stepName"}   = shift;
	$self->{"exportMode"} = shift;    # Enums->ExportMode_SINGLE/ Enums->ExportMode_ALL

	# Mode all
	$self->{"modeAllExportPanel"}           = shift;
	$self->{"modeAllExportPanelCoupon"}     = shift;
	$self->{"modeAllExportPanelLayersSett"} = shift;    # information about layer stretch value

	# Mode single sett
	$self->{"modeSinglePltL"}  = shift;
	$self->{"modeSingleNPltL"} = shift;

	# PROPERTIES

	$self->{"cpnStepName"} = $self->{"stepName"} . "_coupon";

	$self->{"exportPanelAllMngr"} =
	  ExportPanelAllMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"modeAllExportPanelLayersSett"} );
	$self->{"exportPanelAllMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	$self->{"exportPanelSingleMngr"} =
	  ExportPanelSingleMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"}, $self->{"modeSinglePltL"}, $self->{"modeSingleNPltL"} );
	$self->{"exportPanelSingleMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	$self->{"exportPanelCouponMngr"} =
	  ExportPanelCouponMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cpnStepName"} );
	$self->{"exportPanelCouponMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $err = undef;
	if ( $self->{"exportMode"} eq Enums->ExportMode_SINGLE ) {

		$self->{"exportPanelSingleMngr"}->Run();

	}
	elsif ( $self->{"exportMode"} eq Enums->ExportMode_ALL ) {

		# If exist coupon depth steps, copy main panel and separate coupn steps
		my $cpnName = EnumsGeneral->Coupon_ZAXIS;
		my @zAxisCpn = grep { $_ =~ /^${cpnName}\d+$/i } CamStep->GetAllStepNames( $inCAM, $jobId );

		my $separatedCnt = 0;
		if ( scalar(@zAxisCpn) ) {
			$separatedCnt = Helper->SeparateCouponZaxis( $inCAM, $jobId, $self->{"stepName"}, $self->{"cpnStepName"} );
		}

		if ( $self->{"modeAllExportPanel"} ) {

			$self->{"exportPanelAllMngr"}->Run();
		}

		if ( $self->{"modeAllExportPanelCoupon"} ) {

			$self->{"exportPanelCouponMngr"}->Run();
		}

		# Restore coupon steps
		if ($separatedCnt) {
			Helper->RestoreCouponZaxis( $inCAM, $jobId, $self->{"stepName"}, $self->{"cpnStepName"}, $separatedCnt );
		}

	}
	else {

		die "Unknow export mode:" . $self->{"exportMode"};
	}

	die $err if ($err);

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	if ( $self->{"exportSingle"} ) {

		$totalCnt += $self->{"exportPanelSingleMngr"}->TaskItemsCount();

	}
	else {

		$totalCnt += $self->{"exportPanelAllMngr"}->TaskItemsCount();

	}
	return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::NCExport::ExportMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d317363";

	my $step  = "panel";
	my $inCAM = InCAM->new();

	# Exportovat jednotlive vrstvy nebo vsechno
	my $exportSingle = 1;

	# Vrstvy k exportovani, nema vliv pokud $exportSingle == 0
	my @pltLayers = ();

	#my @npltLayers = ();

	# Pokud se bude exportovat jednotlive po vrstvach, tak vrstvz dotahnout nejaktakhle:
	#@pltLayers = CamDrilling->GetPltNCLayers( $inCAM, $jobId );
	#my @npltLayers = ( "ftapes", "ftapebr" );

	my $export = ExportMngr->new( $inCAM, $jobId, $step, Enums->ExportMode_ALL, 0, 1, [], [], [] );

	$export->Run();
	die;

}

1;

