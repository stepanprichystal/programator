
#-------------------------------------------------------------------------------------------#
# Description: Creator model
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SchemePart::Model::LibraryModel;
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

	$self->{"modelKey"}    = PnlCreEnums->SchemePnlCreator_LIBRARY;
	 
	$self->{"settings"}->{"stdSchemeList"}      = [];
	$self->{"settings"}->{"specSchemeList"}     = [];
	$self->{"settings"}->{"schemeType"}         = undef;
	$self->{"settings"}->{"scheme"}             = undef;    # standard/special
	$self->{"settings"}->{"signalLayerSpecFill"} = {};
	 

	return $self;
}

sub GetModelKey {
	my $self = shift;

	return $self->{"modelKey"};

}



sub SetStdSchemeList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stdSchemeList"} = $val;

}

sub GetStdSchemeList {
	my $self = shift;

	return $self->{"settings"}->{"stdSchemeList"};

}

sub SetSpecSchemeList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"specSchemeList"} = $val;

}

sub GetSpecSchemeList {
	my $self = shift;

	return $self->{"settings"}->{"specSchemeList"};

}

sub SetSchemeType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"schemeType"} = $val;

}

sub GetSchemeType {
	my $self = shift;

	return $self->{"settings"}->{"schemeType"};

}

sub SetScheme {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"scheme"} = $val;

}

sub GetScheme {
	my $self = shift;

	return $self->{"settings"}->{"scheme"};

}

sub SetSignalLayerSpecFill {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"signalLayerSpecFill"} = $val;

}

sub GetSignalLayerSpecFill {
	my $self = shift;

	return $self->{"settings"}->{"signalLayerSpecFill"};

}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

