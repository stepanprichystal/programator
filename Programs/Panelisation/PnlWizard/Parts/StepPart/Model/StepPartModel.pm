
#-------------------------------------------------------------------------------------------#
# Description: Coupon layout
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Model::StepPartModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::CpnSingleLayout';
#use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout';

use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::UserDefinedModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::AutopartModel';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => 'PnlCreEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"creators"} = [];
	$self->{"selected"} = PnlCreEnums->StepPnlCreator_AUTOPART;

	push( @{ $self->{"creators"} }, UserDefinedModel->new() );
	push( @{ $self->{"creators"} }, AutopartModel->new() );

	return $self;
}

sub SetSelectedCreator {
	my $self = shift;

	$self->{"selected"} = shift;

}

sub GetSelectedCreator {
	my $self = shift;

	return $self->{"selected"};

}

sub SetCreators {
	my $self = shift;

	$self->{"creators"} = shift;

}

sub GetCreators {
	my $self = shift;

	return $self->{"creators"};

}

sub SetCreatorModelByKey {
	my $self         = shift;
	my $modelKey     = shift;
	my $creatorModel = shift;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"creators"} } ) ; $i++ ) {

		if ( $self->{"creators"}->[$i]->GetModelKey() eq $modelKey ) {

			$self->{"creators"}->[$i] = $creatorModel;
			last;
		}
	}
}

sub GetCreatorModelByKey {
	my $self     = shift;
	my $modelKey = shift;

	my $creatorModel = first { $_->GetModelKey() eq $modelKey } @{ $self->{"creators"} };

	return $creatorModel;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

