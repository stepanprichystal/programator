#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::PANEL_DIM;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardExt';
use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';

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
	my $self     = shift;
	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $jobExist = $self->{"jobExist"};    # (in InCAM db)
	my $isPool   = $self->{"isPool"};

	unless ($jobExist) {

		return 0;
	}

	# 1) if job exist, recognize if pcb has standard panel parameters.
	# If so, check if dimenison are smaller than actual smallest standard for given type of pcb and material
	my $pnl = StandardExt->new( $inCAM, $jobId );
	if ( $pnl->IsStandardCandidate() ) {

		my $smallest = "";
		if ( $pnl->SmallerThanStandard( \$smallest ) ) {

			$self->_AddChange(   "Dps má parametry standardu, ale přířez je menší než náš aktuálně nejmenší standard ($smallest). "
							   . "Předělej desku na standard." );
		}
	}

	# 2) check if border in panel are standard. If not check if it possible change border to standard
	# without overlap existing steps in panel step by new area border

	my $area = ActiveArea->new( $inCAM, $jobId );

	unless ( $area->IsBorderStandard() ) {

		my %b = $area->GetStandardBorder();

		# check if active area will be bigger after change borders
		if ( $area->BorderL() < $b{"bl"} || $area->BorderR() < $b{"br"} || $area->BorderT() < $b{"bt"} || $area->BorderB() < $b{"bb"} ) {

			$self->_AddChange(   "Panel nemá standardní šířku okolí aktivní plochy. "
							   . "Při změně na standard by se zmenšila aktivní plocha. Předělej na standard ručně a zkontroluj" );
		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::INCAM_JOB' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d10355";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

