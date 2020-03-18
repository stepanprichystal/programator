#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::STACKUP;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Scoring::ScoreFlatten';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardExt';
use aliased 'Packages::Reorder::Enums';
use aliased 'Packages::CAMJob::Material::MaterialInfo';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if exist new version of nif, if so it means it is from InCAM
sub Run {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	if ( $reorderType eq Enums->ReorderType_STD ) {

		my $materialKind = HegMethods->GetMaterialKind($jobId);

		# If multilayer
		if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 && $materialKind ) {

			my $stackup = Stackup->new( $inCAM, $jobId );

			# 1) Test id material in helios, match material in stackup
			my $stackKind = $stackup->GetStackupType();

			#exception DE 104 eq FR4
			if ( $stackKind =~ /DE 104/i ) {
				$stackKind = "FR4";
			}

			$stackKind =~ s/[\s\t]//g;

			unless ( $materialKind =~ /$stackKind/i || $stackKind =~ /$materialKind/i ) {

				$self->_AddChange( "Materiál složení ($stackKind) není stejný jako materiál v IS ($materialKind). Oprav to.", 1 );
			}

			# 2) Test if 4vv have old default stackup with 900µm core (if it is standard dimension)
			my $pnl = StandardExt->new( $inCAM, $jobId );

			if ( $pnl->IsStandardCandidate() && $stackup->GetCuLayerCnt() == 4 && $stackup->GetStackupType() =~ /DE 104/i ) {

				my @cores = $stackup->GetAllCores();

				if ( $cores[0]->GetText() =~ /900\s*/i ) {

					$self->_AddChange(
									   "Vypadá to, že se jedná o staré defaultní složení FR4 s jádrem 900µm. "
										 . "Pokud je to pravda (není to vyložený požadavek zákazníka!), "
										 . "předělej na nové standardní složení IS400.",
									   0
					);
				}
			}

			# 3) Test if stackup material is on stock
			my $inf           = HegMethods->GetInfoAfterStartProduce( $self->{"orderId"} );
			my %dimsPanelHash = JobDim->GetDimension( $inCAM, $jobId );
			my %lim           = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );
			my $pArea         = ( $lim{"xMax"} - $lim{"xMin"} ) * ( $lim{"yMax"} - $lim{"yMin"} ) / 1000000;
			my $area          = $inf->{"kusy_pozadavek"} / $dimsPanelHash{"nasobnost"} * $pArea;

			my $errMes = "";

			my $matOk = MaterialInfo->StackupMatInStock( $inCAM, $jobId, $stackup, $area, \$errMes );

			unless ($matOk) {
				$self->_AddChange( "Materiál, který je obsažen ve složení nelze použít. Detail chyby: $errMes", 1 );
			}

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

