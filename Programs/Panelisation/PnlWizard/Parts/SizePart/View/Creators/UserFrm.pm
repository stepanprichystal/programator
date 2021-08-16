
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::UserFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::Frm::PnlSizeBase);

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
	my $inCAM   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	
	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_USER, $parent, $inCAM, $jobId );

	bless($self);

	$self->{"pnlType"} = $pnlType;

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;
 
	my $pnlType = $self->{"pnlType"};

	# DEFINE CONTROLS
	
	$self->_ShowSwapSize(1) if ( $pnlType eq PnlCreEnums->PnlType_CUSTOMERPNL );
 
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

