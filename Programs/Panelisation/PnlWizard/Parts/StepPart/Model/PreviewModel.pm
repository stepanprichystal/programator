#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Model::PreviewModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"}    = PnlCreEnums->StepPnlCreator_PREVIEW ;
	 
	$self->{"settings"}->{"srcJobId"}              = undef;
	$self->{"settings"}->{"panelJSON"}             = undef;
	$self->{"settings"}->{"manualPlacementJSON"}   = undef;
	$self->{"settings"}->{"manualPlacementStatus"} = EnumsGeneral->ResultType_NA;
	 

	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

sub SetSrcJobId {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobId"} = $val;
}

sub GetSrcJobId {
	my $self = shift;

	return $self->{"settings"}->{"srcJobId"};
}

sub SetPanelJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"panelJSON"} = $val;
}

sub GetPanelJSON {
	my $self = shift;

	return $self->{"settings"}->{"panelJSON"};
}

sub SetManualPlacementJSON {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementJSON"} = $val;

}

sub GetManualPlacementJSON {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementJSON"};

}

sub SetManualPlacementStatus {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"manualPlacementStatus"} = $val;

}

sub GetManualPlacementStatus {
	my $self = shift;

	return $self->{"settings"}->{"manualPlacementStatus"};

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

