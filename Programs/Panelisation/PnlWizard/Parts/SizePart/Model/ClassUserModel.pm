
#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::ClassUserModel;
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

	$self->{"modelKey"} = PnlCreEnums->SizePnlCreator_CLASSUSER;

	# Setting values necessary for procesing panelisation
	$self->{"settings"}->{"width"}       = undef;
	$self->{"settings"}->{"height"}      = undef;
	$self->{"settings"}->{"borderLeft"}  = undef;
	$self->{"settings"}->{"borderRight"} = undef;
	$self->{"settings"}->{"borderTop"}   = undef;
	$self->{"settings"}->{"borderBot"}   = undef;
	
	$self->{"settings"}->{"pnlClasses"}   = undef;
	$self->{"settings"}->{"defPnlBorder"}   = undef;
	$self->{"settings"}->{"defPnlSize"}   = undef;
	$self->{"settings"}->{"defPnlClass"}   = undef;

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

sub SetPnlClasses {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"pnlClasses"} = $val;
}

sub GetPnlClasses {
	my $self = shift;

	return $self->{"settings"}->{"pnlClasses"};
}

sub SetDefPnlClass {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlClass"} = $val;
}

sub GetDefPnlClass {
	my $self = shift;

	return $self->{"settings"}->{"defPnlClass"};
}

sub SetDefPnlSize {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlSize"} = $val;
}

sub GetDefPnlSize {
	my $self = shift;

	return $self->{"settings"}->{"defPnlSize"};
}

sub SetDefPnlBorder {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"defPnlBorder"} = $val;
}

sub GetDefPnlBorder {
	my $self = shift;

	return $self->{"settings"}->{"defPnlBorder"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
