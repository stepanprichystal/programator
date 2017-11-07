#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::EXPORT;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";
use aliased 'Programs::Exporter::ExportChecker::Enums'                       => 'CheckerEnums';

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

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	unless ($jobExist) {
		return 0;
	}

	my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

	if ( $isPool && !$pnlExist ) {
		return 0;
	}

	my $units = UnitHelper->PrepareUnits( $inCAM, $jobId );

	my @activeOnUnits = grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $units->{"units"} };

	foreach my $unit (@activeOnUnits) {

		my $resultMngr = -1;
		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		if ( $resultMngr->GetErrorsCnt() ) {

			my $txt = "Kontrola před exportem - " . UnitEnums->GetTitle( $unit->GetUnitId() ) . "\n";
			$txt .= $resultMngr->GetErrorsStr(1);
			$self->_AddChange( $txt, 0 );
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

