
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::DataMngr::StencilDataMngr::StencilDataMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::StencilCreator::Enums';

use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::PasteProfile';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::PasteData';
use aliased 'Programs::StencilCreator::DataMngr::StencilDataMngr::Schema';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"dataMngr"} = shift;

	$self->{"w"} = undef;
	$self->{"h"} = undef;
	$self->{"topProf"}     = undef;
	$self->{"botProf"}     = undef;
	$self->{"schema"}      = undef;
 

	$self->{"init"} = 0;

	return $self;
}

sub Update {
	my $self = shift;
	my $val  = shift;

	$self->__Update();
	
	
	 

}

sub GetTopProfilePos {
	my $self = shift;

	my %pos = ( "x" => 0, "y" => 0 );

	$pos{"x"} = $self->__GetTopProfilePosX();
	$pos{"y"} = $self->__GetTopProfilePosY();

	return %pos;
}

sub GetBotProfilePos {
	my $self = shift;

	my %pos = ( "x" => 0, "y" => 0 );

	$pos{"x"} = $self->__GetBotProfilePosX();
	$pos{"y"} = $self->__GetBotProfilePosY();

	return %pos;
}

sub GetTopDataPos {
	my $self = shift;

	my %pos = $self->GetTopProfilePos();

	$pos{"x"} += $self->{"topProf"}->GetPDOrigin->{"x"};
	$pos{"y"} += $self->{"topProf"}->GetPDOrigin->{"y"};

	return \%pos;
}

sub GetBotDataPos {
	my $self = shift;

	my %pos = $self->GetTopProfilePos();

	$pos{"x"} += $self->{"botProf"}->GetPDOrigin->{"x"};
	$pos{"y"} += $self->{"botProf"}->GetPDOrigin->{"y"};

	return \%pos;
}
 
# Return width and height of stencil active area
# Active area depand on choosed schema
# if standard - area limited by holes
# if vlepeni do ramu - konstant border
# other - area is same siye as stencil
sub GetStencilActiveArea {
	my $self = shift;

	my $sch  = $self->GetSchema();
	my $schT = $self->{"dataMngr"}->GetSchemaType();

	my %size = ( "w" => 0, "h" => 0 );

	if ( $schT eq Enums->Schema_STANDARD ) {

		$size{"h"} = $self->{"dataMngr"}->GetHoleDist2();
		$size{"w"} = $self->GetWidth();

	}
	elsif ( $schT eq Enums->Schema_FRAME ) {

		$size{"h"} = $self->GetHeight() - 50;
		$size{"w"} = $self->GetWidth() - 50;

	}
	elsif ( $schT eq Enums->Schema_INCLUDED ) {

		$size{"h"} = $self->GetHeight();
		$size{"w"} = $self->GetWidth();

	}
	
	return %size;

}

#-------------------------------------------------------------------------------------------#
#  Set Layout properties
#-------------------------------------------------------------------------------------------#
 
 
 

sub GetTopProfile {
	my $self = shift;

	return $self->{"topProf"};
}
 

sub GetBotProfile {
	my $self = shift;

	return $self->{"botProf"};
}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};
}
 

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

 
sub GetSchema {
	my $self = shift;

	return $self->{"schema"};
}
 

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __Update {
	my $self     = shift;
 
	my $dataMngr    = $self->{"dataMngr"};
 
	my $stencilType = $dataMngr->GetStencilType();

	# 2) update profile data
	my $stencilStep = $dataMngr->GetStencilStep();

	if ( $dataMngr->{"topExist"} ) {

		my $pd =
		  PasteData->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"h"} );
		my $pp = PasteProfile->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"h"} );

		$pp->SetPasteData( $pd, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"x"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"top"}->{"y"} );

		$self->{"topProf"} = $pp;
	}

	if ( $dataMngr->{"botExist"} ) {

		my $botKye = $stencilType eq Enums->StencilType_BOT ? "bot" : "botMirror";

		my $pd =
		  PasteData->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"h"} );
		my $pp = PasteProfile->new( $dataMngr->{"stepsSize"}->{$stencilStep}->{"w"}, $dataMngr->{"stepsSize"}->{$stencilStep}->{"h"} );

		$pp->SetPasteData( $pd,
						   $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"x"},
						   $dataMngr->{"stepsSize"}->{$stencilStep}->{$botKye}->{"y"} );

		$self->{"botProf"} = $pp;
	}

	# 3)update stencil size

	$self->{"w"} =  $dataMngr->GetStencilSizeX();
	$self->{"h"} =  $dataMngr->GetStencilSizeY() ;

	# 4) Update schema

	my $schema = Schema->new( $dataMngr, $dataMngr->GetSchemaType());
 
	$self->{"schema"} = $schema;
 
	$self->__RotateStencil();
  
}


sub __GetTopProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"topProf"}->GetPDOrigin()->{"x"};
	}

	return $posX;
}

sub __GetTopProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     =  $self->{"dataMngr"}->GetSpacing();
	my $spacingType =  $self->{"dataMngr"}->GetSpacingType();

	# Single paste data
	if ( $self->{"dataMngr"}->GetStencilType() ne Enums->StencilType_TOPBOT ) {

		# Center by profile
		if ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYPROF ) {

			$posY = ( $self->{"h"} - $self->{"topProf"}->GetHeight() ) / 2;

		}

		# Center by data
		elsif ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYDATA ) {

			$posY = ( $self->{"h"} - $self->{"topProf"}->GetPasteData()->GetHeight() ) / 2 - $self->{"topProf"}->GetPDOrigin->{"y"};
		}
	}

	# Merged paste data
	elsif ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY = $spacing / 2 + $self->{"h"} / 2;
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY = $spacing / 2 - $self->{"topProf"}->GetPDOrigin->{"y"} + $self->{"h"} / 2;
		}
	}

	return $posY;
}

sub __GetBotProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"botProf"}->GetPDOrigin->{"x"};
	}

	return $posX;
}

sub __GetBotProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     = $self->{"dataMngr"}->GetSpacing();
	my $spacingType = $self->{"dataMngr"}->GetSpacingType();

	# Single paste data
	if ( $self->{"dataMngr"}->GetStencilType() ne Enums->StencilType_TOPBOT ) {

		# Center by profile
		if ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYPROF ) {

			$posY = ( $self->{"h"} - $self->{"botProf"}->GetHeight() ) / 2;

		}

		# Center by data
		elsif ( $self->{"dataMngr"}->GetHCenterType() eq Enums->HCenter_BYDATA ) {

			$posY = ( $self->{"h"} - $self->{"botProf"}->GetPasteData()->GetHeight() ) / 2 - $self->{"botProf"}->GetPDOrigin->{"y"};
		}
	}

	# Merged paste data
	elsif ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY = $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetHeight();
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY =
			  $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetPasteData()->GetHeight() - $self->{"botProf"}->GetPDOrigin()->{"y"};
		}
	}

	return $posY;
}

# Find new roattion of paste profile
sub __RotateStencil {
	my $self = shift;
 

	# difference of length in percentage between profile height and width
	my $diffTop = abs( $self->{"topProf"}->GetHeight() - $self->{"topProf"}->GetWidth() ) / $self->{"topProf"}->GetHeight();

	# difference of length in percentage between profile height and width
	my $diffBot = abs( $self->{"botProf"}->GetHeight() - $self->{"botProf"}->GetWidth() ) / $self->{"botProf"}->GetHeight();

	if ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOP ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth() ? "h" : "w";
		if ( $lSide ne $lProfSide && $diffTop > 0.1 ) {
			$self->{"topProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_BOT ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth() ? "h" : "w";

		if ( $lSide ne $lProfSide && $diffBot > 0.1 ) {
			$self->{"botProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"dataMngr"}->GetStencilType() eq Enums->StencilType_TOPBOT ) {

		if ( $self->{"topProf"} ) {

			my $lSide = $self->GetHeight() / 2 > $self->GetWidth() ? "h" : "w";
			my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth() ? "h" : "w";

			if ( $lSide ne $lProfSide && $diffTop > 0.1 ) {
				$self->{"topProf"}->SwitchDim();
				print STDERR "switch profile\n";
			}
		}

		if ( $self->{"botProf"} ) {

			my $lSide = $self->GetHeight() / 2 > $self->GetWidth() ? "h" : "w";
			my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth() ? "h" : "w";

			if ( $lSide ne $lProfSide && $diffBot > 0.1 ) {
				$self->{"botProf"}->SwitchDim();
				print STDERR "switch profile\n";
			}
		}

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

