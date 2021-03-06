
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::Helpers::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStep';

use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::HEGSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::UserSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::MatrixSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::ClassUserSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::ClassHEGSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::PreviewSize';

use aliased 'Programs::Panelisation::PnlCreator::StepsPnlCreator::ClassUserSteps';
use aliased 'Programs::Panelisation::PnlCreator::StepsPnlCreator::ClassHEGSteps';
use aliased 'Programs::Panelisation::PnlCreator::StepsPnlCreator::MatrixSteps';
use aliased 'Programs::Panelisation::PnlCreator::StepsPnlCreator::SetSteps';
use aliased 'Programs::Panelisation::PnlCreator::StepsPnlCreator::PreviewSteps';

use aliased 'Programs::Panelisation::PnlCreator::CpnPnlCreator::SemiautoCpn';

use aliased 'Programs::Panelisation::PnlCreator::SchemePnlCreator::LibraryScheme';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetPnlCreatorByKey {
	my $self       = shift;
	my $jobId      = shift;
	my $pnlType    = shift;
	my $creatorKey = shift;

	my $creator = undef;

	if ( $creatorKey eq PnlCreEnums->SizePnlCreator_USER ) {
		$creator = UserSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_HEG ) {
		$creator = HEGSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {
		$creator = MatrixSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {
		$creator = ClassUserSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {
		$creator = ClassHEGSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {
		$creator = PreviewSize->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSUSER ) {
		$creator = ClassUserSteps->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {
		$creator = ClassHEGSteps->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {
		$creator = MatrixSteps->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_SET ) {
		$creator = SetSteps->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {
		$creator = PreviewSteps->new( $jobId, $pnlType );

	}
	elsif ( $creatorKey eq PnlCreEnums->CpnPnlCreator_SEMIAUTO ) {
		$creator = SemiautoCpn->new( $jobId, $pnlType );
	}
	elsif ( $creatorKey eq PnlCreEnums->SchemePnlCreator_LIBRARY ) {
		$creator = LibraryScheme->new( $jobId, $pnlType );
	}
	else {

		die "Creator was not defined  for key: $creatorKey";
	}

	return $creator;
}

# Return all edit steps
# This steps are steps with suffix +1, except some special cases
sub GetEditSteps {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	
	my @editSteps = grep { $_ =~ /^\w+\+\d$/ } CamStep->GetAllStepNames( $inCAM, $jobId );
	@editSteps = grep { $_ !~ /^et_panel.*\+\d$/ } @editSteps;
	
	return @editSteps;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

