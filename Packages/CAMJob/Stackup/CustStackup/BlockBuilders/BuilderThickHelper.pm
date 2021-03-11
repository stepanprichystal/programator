
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderThickHelper;

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"stackupMngr"} = shift;
	$self->{"sectionMngr"} = shift;

	return $self;
}

sub GetComputedThick {
	my $self    = shift;
	my $section = shift;

	my $t = undef;

	if ( $section eq Enums->Sec_A_MAIN ) {

		$t = $self->{"stackupMngr"}->GetThickness();

	}
	elsif ( $section eq Enums->Sec_B_FLEX || $section eq Enums->Sec_D_FLEXTAIL ) {

		# Only Rigid flex
		$t = $self->{"stackupMngr"}->GetThicknessFlex(0);

	}
	elsif ( $section eq Enums->Sec_E_STIFFENER ) {

		$t = $self->{"stackupMngr"}->GetThicknessStiffener("top");

	}
	elsif ( $section eq Enums->Sec_F_STIFFENER ) {

		$t = $self->{"stackupMngr"}->GetThicknessStiffener("bot");
	}

	return $t;
}

sub GetRequiredThick {
	my $self    = shift;
	my $section = shift;

	my $t = undef;

	if ( $section eq Enums->Sec_A_MAIN ) {

		$t = $self->{"stackupMngr"}->GetNominalThickness();

	}
	elsif ( $section eq Enums->Sec_E_STIFFENER){
 
		my @allThickness = $self->{"stackupMngr"}->GetAllRequestedStiffThick("top");

		if (  scalar(@allThickness) == 1 ) {

			$t = $allThickness[0];
		}
		else {

			$t = "*";
		}
	}elsif ( $section eq Enums->Sec_F_STIFFENER){
 
		my @allThickness = $self->{"stackupMngr"}->GetAllRequestedStiffThick("bot");

		if (  scalar(@allThickness) == 1 ) {

			$t = $allThickness[0];
		}
		else {

			$t = "*";
		}
	}

	return $t;
}

1;

