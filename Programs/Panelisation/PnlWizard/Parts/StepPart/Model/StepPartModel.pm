
#-------------------------------------------------------------------------------------------#
# Description: Part model, contain all creator model settings plus part settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::StepPart::Model::StepPartModel;
use base('Programs::Panelisation::PnlWizard::Parts::PartModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::ClassUserModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::ClassHEGModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::MatrixModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::SetModel';
use aliased 'Programs::Panelisation::PnlWizard::Parts::StepPart::Model::PreviewModel';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => 'PnlCreEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
 

	push( @{ $self->{"creators"} }, ClassUserModel->new() );
	push( @{ $self->{"creators"} }, ClassHEGModel->new() );
	push( @{ $self->{"creators"} }, MatrixModel->new() );
	push( @{ $self->{"creators"} }, SetModel->new() );
	push( @{ $self->{"creators"} }, PreviewModel->new() );
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  GET/SET model methods
#-------------------------------------------------------------------------------------------#
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

