
#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::PreviewModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"modelKey"} = PnlCreEnums->SizePnlCreator_PREVIEW;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"width"}            = undef;
	$self->{"settings"}->{"height"}           = undef;
	$self->{"settings"}->{"borderLeft"}       = undef;
	$self->{"settings"}->{"borderRight"}      = undef;
	$self->{"settings"}->{"borderTop"}        = undef;
	$self->{"settings"}->{"borderBot"}        = undef;
	$self->{"settings"}->{"srcJobId"}         = undef;
	$self->{"settings"}->{"srcJobListByName"} = [];
	$self->{"settings"}->{"srcJobListByNote"} = [];
	$self->{"settings"}->{"panelJSON"}      = undef;

	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"width"} = $val;
}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"width"};
}

sub SetHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"height"} = $val;
}

sub GetHeight {
	my $self = shift;

	return $self->{"settings"}->{"height"};
}

sub SetBorderLeft {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderLeft"} = $val;
}

sub GetBorderLeft {
	my $self = shift;

	return $self->{"settings"}->{"borderLeft"};
}

sub SetBorderRight {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderRight"} = $val;
}

sub GetBorderRight {
	my $self = shift;

	return $self->{"settings"}->{"borderRight"};
}

sub SetBorderTop {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderTop"} = $val;
}

sub GetBorderTop {
	my $self = shift;

	return $self->{"settings"}->{"borderTop"};
}

sub SetBorderBot {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"borderBot"} = $val;
}

sub GetBorderBot {
	my $self = shift;

	return $self->{"settings"}->{"borderBot"};
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

sub SetSrcJobListByName {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobListByName"} = $val;
}

sub GetSrcJobListByName {
	my $self = shift;

	return $self->{"settings"}->{"srcJobListByName"};
}

sub SetSrcJobListByNote {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"srcJobListByNote"} = $val;
}

sub GetSrcJobListByNote {
	my $self = shift;

	return $self->{"settings"}->{"srcJobListByNote"};
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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
