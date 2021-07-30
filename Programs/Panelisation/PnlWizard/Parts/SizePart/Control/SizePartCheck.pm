
#-------------------------------------------------------------------------------------------#
# Description: Check class for checking before processing panel creator
# Class should contain OnItemResult event
# Class must implement ICheckClass
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Control::SizePartCheck;
use base 'Programs::Panelisation::PnlWizard::Parts::PartCheckBase';

use Class::Interface;

&implements('Packages::InCAMHelpers::AppLauncher::PopupChecker::ICheckClass');

#3th party library
use utf8;
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Stackup::StackupCode';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'Packages::ProductionPanel::StandardPanel::Enums' => 'StdPnlEnums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	# PROPERTIES

	return $self;
}

# Do check of creator settings and part settings
sub Check {
	my $self      = shift;
	my $pnlType   = shift;    # Panelisation type
	my $partModel = shift;    # Part model
 
	if ( $pnlType eq PnlCreEnums->PnlType_CUSTOMERPNL ) {

		$self->__CheckCustomerPanel($partModel);

	}
	elsif ( $pnlType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$self->__CheckProductionPanel($partModel);
	}

}

# Check only customer panel errors
sub __CheckCustomerPanel {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $creator      = $partModel->GetSelectedCreator();
	my $creatorModel = $partModel->GetCreatorModelByKey($creator);

	my $w = $creatorModel->GetWidth();
	my $h = $creatorModel->GetHeight();

	# X) Check customer min/max dimension
	{
		my $custInfo = HegMethods->GetCustomerInfo($jobId);
		my $custNote = CustomerNote->new( $custInfo->{"reference_subjektu"} );

		my ( $minA, $minB ) = $custNote->MinCustPanelDim();

		if ( defined $minA && defined $minB ) {

			if ( min( $w, $h ) < min( $minA, $minB ) || max( $w, $h ) < max( $minA, $minB ) ) {
				$self->_AddWarning(
									"Minimální velikost mpanelu",
									"Zákazník požaduje minimální velikost panelu pro osazování: "
									  . $minA . "mm x "
									  . $minB
									  . "mm. Panel má aktuálně: "
									  . $w . "mm x "
									  . $h
				);
			}
		}

		my ( $maxA, $maxB ) = $custNote->MaxCustPanelDim();

		if ( defined $maxA && defined $maxB ) {

			if ( min( $w, $h ) > min( $maxA, $maxB ) || max( $w, $h ) > max( $maxA, $maxB ) ) {

				$self->_AddWarning(
									"Maximální velikost mpanelu",
									"Zákazník požaduje maximální velikost panelu pro osazování: "
									  . $minA . "mm x "
									  . $minB
									  . "mm. Panel má aktuálně: "
									  . $w . "mm x "
									  . $h
				);
			}
		}

	}

}

# Check only production panel errors
sub __CheckProductionPanel {
	my $self      = shift;
	my $partModel = shift;    # Part model

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $creator      = $partModel->GetSelectedCreator();
	my $creatorModel = $partModel->GetCreatorModelByKey($creator);

	# X) Check if production panel has strandradr dimension
	{

		my $w  = $creatorModel->GetWidth();
		my $h  = $creatorModel->GetHeight();
		my $bL = $creatorModel->GetBorderLeft();
		my $bR = $creatorModel->GetBorderRight();
		my $bT = $creatorModel->GetBorderTop();
		my $bB = $creatorModel->GetBorderBot();

		my $profLim = { "xMin" => 0, "xMax" => $w, "yMin" => 0, "yMax" => $h };
		my $areaLim = { "xMin" => $bL, "xMax" => $w - $bR, "yMin" => $bB, "yMax" => $h - $bT };

		my $stdPnl = StandardBase->new( $inCAM, $jobId, undef, undef, 0, $profLim, $areaLim );

		my @candidates     = ();
		my $isStdCandidate = $stdPnl->IsStandardCandidate( \@candidates );

		if ( !$isStdCandidate
			 || ( $isStdCandidate && $stdPnl->GetStandardType() eq StdPnlEnums->Type_NONSTANDARD ) )
		{
			my $txt = "Výrobní panel nemá standardní rozměr. Možné varianty standardního panelu pro tuto DPS:\n";
			foreach my $s (@candidates) {

				$txt .= "Název standardu: " . $s->Name() . "\n";
				$txt .= "- typ desky: " . $s->PcbType() . "\n";
				$txt .= "- materiál: " . $s->PcbMat() . "\n";
				$txt .= "- rozměr: " . $s->W() . "x" . $s->H() . "mm\n";
				$txt .= "- okolí: " . $s->BorderL() . "+" . $s->BorderR() . "+" . $s->BorderT() . "+" . $s->BorderB() . "mm\n\n";

			}
			my $pcbType = JobHelper->GetPcbType($jobId);

			if (    $pcbType eq EnumsGeneral->PcbType_NOCOPPER
				 || $pcbType eq EnumsGeneral->PcbType_1V
				 || $pcbType eq EnumsGeneral->PcbType_2V )
			{
				$self->_AddWarning( "Nestandardní rozměr", $txt );
			}
			else {

				$self->_AddError( "Nestandardní rozměr", $txt );
			}

		}

	}
}

1;
