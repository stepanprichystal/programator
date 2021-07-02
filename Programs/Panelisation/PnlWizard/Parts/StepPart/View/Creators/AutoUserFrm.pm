
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::AutoUserFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::StepPart::View::Creators::Frm::PnlStepAutoBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->StepPnlCreator_AUTOUSER, $parent, $inCAM, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT

	# SAVE REFERENCES

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

