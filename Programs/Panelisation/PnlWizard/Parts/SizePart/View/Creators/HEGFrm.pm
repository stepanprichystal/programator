
#-------------------------------------------------------------------------------------------#
# Description: View form for specific sreator
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::HEGFrm;
use base qw(Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::Frm::PnlSizeBase);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new( PnlCreEnums->SizePnlCreator_HEG, $parent, $jobId );

	bless($self);

	$self->__SetLayout();

	# DEFINE EVENTS

	return $self;
}

# Do specific layout settings for creator
sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS
	
	$self->_EnableLayoutSize(1);

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT

	# SAVE REFERENCES

	$self->{"ISDimensionFilled"} = $self->_SetLayoutISSize( "HEG dimensions set:",  40, 10, 50 );

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
sub SetISDimensionFilled {
	my $self = shift;
	my $val  = shift;

	$self->{"ISDimensionFilled"}->SetStatus( ( $val ? EnumsGeneral->ResultType_OK : EnumsGeneral->ResultType_FAIL ) );

}

sub GetISDimensionFilled {
	my $self = shift;

	my $stat = $self->{"ISDimensionFilled"}->GetStatus();

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

