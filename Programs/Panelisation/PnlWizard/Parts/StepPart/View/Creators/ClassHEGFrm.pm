
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::ClassHEGFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::PnlStepAutoBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_CLASSHEG, $parent, $inCAM, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	
	my $indicator = $self->_SetLayoutISMultipl("HEG multiplicity fileld");
	$self->_EnableLayoutAmount(0);

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT

	# SAVE REFERENCES
	
	$self->{"ISMultiplFilled"} = $indicator;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetISMultiplFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"ISMultiplFilled"}->SetStatus( ( $val ? EnumsGeneral->ResultType_OK : EnumsGeneral->ResultType_FAIL ) );

}

sub GetISMultiplFilled {
	my $self = shift;

	my $stat = $self->{"ISMultiplFilled"}->GetStatus();

	if ( $stat eq EnumsGeneral->ResultType_OK ) {

		return 1;
	}
	else {

		return 0;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

