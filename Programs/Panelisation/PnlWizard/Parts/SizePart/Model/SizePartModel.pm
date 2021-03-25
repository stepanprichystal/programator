
#-------------------------------------------------------------------------------------------#
# Description: Part model, contain all creator model settings plus part settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::SizePart::Model::SizePartModel;
use base('Programs::Panelisation::PnlWizard::Core::WizardModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::UserModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::HEGModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::MatrixModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::ClassUserModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::ClassHEGModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::Model::PreviewModel';
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
	$self->{"selected"} = undef;

	push( @{ $self->{"creators"} }, UserModel->new() );
	push( @{ $self->{"creators"} }, HEGModel->new() );
	#push( @{ $self->{"creators"} }, MatrixModel->new() );
	push( @{ $self->{"creators"} }, ClassUserModel->new() );
	push( @{ $self->{"creators"} }, ClassHEGModel->new() );
#	push( @{ $self->{"creators"} }, PreviewModel->new() );
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  GET/SET model methods
#-------------------------------------------------------------------------------------------#

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

