
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrVV;
use base('Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stackup"} = Stackup->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub GetLayerCnt {
	my $self = shift;

	return $self->{"stackup"}->GetCuLayerCnt();

}

sub GetExistCvrl {
	my $self = shift;
	my $side = shift;    # top/bot
	my $info = shift;    # reference for storing info

	my $exist = 0;

	my @l = $self->{"stackup"}->GetAllLayers();
	@l = reverse(@l) if ( $side eq "bot" );

	for ( my $i = 0 ; $i < scalar(@l) ; $i++ ) {

		if (    $l[$i]->GetType() eq StackEnums->MaterialType_COVERLAY
			 && defined $l[ $i + 1 ]
			 && $l[ $i + 1 ]->GetType() eq StackEnums->MaterialType_COPPER
			 && $l[ $i + 1 ]->GetCopperName() eq ( $side eq "top" ? "c" : "s" ) )
		{
			$exist = 1;

			if ( defined $info ) {

				$info->{"adhesiveText"}  = "";
				$info->{"adhesiveThick"} = $l[$i]->GetAdhesiveThick();
				$info->{"cvrlText"}      = $l[$i]->GetText();
				$info->{"cvrlThick"}     = $l[$i]->GetThick();

			}
			last;
		}
	}

	return $exist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

