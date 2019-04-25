#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::CUSTOMERS;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::NifFile::NifFile';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# check if pcb is
sub Run {
	my $self = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $orderId  = $self->{"orderId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	my $needChange = 0;

	my $custInfo = HegMethods->GetCustomerInfo($jobId);

	# 1) Kadlec customer
	if ( $custInfo->{"reference_subjektu"} eq "04174" || $custInfo->{"reference_subjektu"} eq "04175" ) {

		my $custPnlExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, 'customer_panel' );
		my $custSetExist = CamAttributes->GetJobAttrByName( $inCAM, $jobId, 'customer_set' );

		if ( !CamHelper->StepExists( $inCAM, $jobId, "mpanel" ) && $custPnlExist ne "yes" && $custSetExist ne "yes" ) {

			$self->_AddChange("Zákazník Kadlec si přeje veškeré dps dodávat v panelu. Předělej na panel.");
		}
	}

	# 2)Pickering

	if (    $custInfo->{"reference_subjektu"} eq "06544"
		 || $custInfo->{"reference_subjektu"} eq "06545"
		 || $custInfo->{"reference_subjektu"} eq "06546" )
	{

		$self->_AddChange("Zákazník Pickering si přeje upravit číslo objednávek na deskách dle OneNotu");

	}

	# 2) Meatest

	if ( $custInfo->{"reference_subjektu"} eq "05052" ) {

		#test if no UL in Heg
		my $ul = HegMethods->GetUlLogoLayer($jobId);

		if ( !defined $ul || $ul eq "" ) {

			$self->_AddChange("Zákazník si přeje vkládat do všech desek UL logo (14.8.2017)");

		}

	}

	# 3) Multi PCB
	if ( $custInfo->{"reference_subjektu"} eq '05626' ) {

		if ( !$isPool && CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

			# Check if there is good panel ussage (at least 40%) in reorder (if reorder amount is more than one panel)
			
			my %inf = HegMethods->GetAllByOrderId($orderId);
			my @inProduc = HegMethods->GetOrdersByState( $jobId, 4 );    # Orders on Ve vyrobe

			if ( scalar(@inProduc) == 0 && $inf{"pocet_prirezu"} > 1 ) {

				# Compute panel active area
				my $pnl = StandardBase->new( $inCAM, $jobId );
				my $pnlArea = $pnl->WArea() * $pnl->HArea();

				# Compute area of all nested step in panel
				my $stepArea = 0;
				foreach my $s ( CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId ) ) {

					my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $s->{"stepName"} );
					$stepArea += $s->{"totalCnt"} * ( $lim{"xMax"} - $lim{"xMin"} ) * ( $lim{"yMax"} - $lim{"yMin"} );
				}

				# compute final panel ussage
				my $minUsage = 0.4;
				if ( ($stepArea / $pnlArea) < $minUsage ) {

					$self->_AddChange(   "U opakované zakázky je malé využití panelu ("
									   . sprintf("%d", $stepArea / $pnlArea * 100) . "%."
									   . " Zkontroluj jestli nelze dosáhnout vyššího využití (pokud možno alespoň 40%)" );
				}
			}

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::KADLEC_PANEL' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

