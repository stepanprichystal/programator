
#-------------------------------------------------------------------------------------------#
# Description: Part model, contain all creator model settings plus part settings
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Parts::CpnPart::Model::CpnPartModel;
use base('Programs::Panelisation::PnlWizard::Parts::PartModelBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library

use aliased 'Programs::Panelisation::PnlWizard::Parts::CpnPart::Model::SemiautoModel';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => 'PnlCreEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
  
	push( @{ $self->{"creators"} }, SemiautoModel->new() );

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

