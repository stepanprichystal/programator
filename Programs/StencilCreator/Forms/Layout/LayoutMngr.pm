
#-------------------------------------------------------------------------------------------#
# This sctructure contain information: type of layer: mask, silk, copeer etc...
# Amd Which layer merge
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::StencilCreator::Forms::Layout::LayoutMngr;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::StencilCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"w"} = undef;
	$self->{"h"} = undef;

	$self->{"stencilType"} = undef;
	$self->{"topProf"}     = undef;
	$self->{"botProf"}     = undef;
	$self->{"spacing"}     = undef;
	$self->{"spacingType"} = undef;
	$self->{"centerType"}  = undef;

	$self->{"init"} = 0;

	return $self;
}

sub Inited {
	my $self = shift;

	$self->{"init"} = 1;

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

#-------------------------------------------------------------------------------------------#
#  Set Layout properties
#-------------------------------------------------------------------------------------------#

sub SetStencilType {
	my $self = shift;
	my $type = shift;

	$self->{"stencilType"} = $type;

	$self->__RotateStencil();

}

sub GetStencilType {
	my $self = shift;
	my $type = shift;

	return $self->{"stencilType"};
}

sub SetTopProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"topProf"} = $top;
}

sub GetTopProfile {
	my $self = shift;

	return $self->{"topProf"};
}

sub SetBotProfile {
	my $self = shift;
	my $top  = shift;

	$self->{"botProf"} = $top;
}

sub GetBotProfile {
	my $self = shift;

	return $self->{"botProf"};
}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};

}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

	$self->__RotateStencil();
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};

}

sub SetHeight {
	my $self   = shift;
	my $height = shift;

	$self->{"h"} = $height;

	$self->__RotateStencil();
}

sub GetSpacing {
	my $self = shift;

	return $self->{"spacing"};
}

sub SetSpacing {
	my $self = shift;
	my $val  = shift;

	$self->{"spacing"} = $val;

	$self->__RotateStencil();

}

sub SetSpacingType {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingType"} = $val;

	$self->__RotateStencil();

}

sub GetSpacingType {
	my $self = shift;

	return $self->{"spacingType"};
}

sub SetHCenterType {

	my $self = shift;
	my $type = shift;

	$self->{"centerType"} = $type;

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __GetTopProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"centerType"} eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"centerType"} eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"topProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"topProf"}->GetPDOrigin->{"x"};
	}
	
	return $posX;
}

sub __GetTopProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();

	# Single paste data
	if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

		$posY = ( $self->{"h"} - $self->{"topProf"}->GetHeight() ) / 2;
	}

	# Merged paste data
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY =   $spacing / 2 + $self->{"h"} / 2;
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY =   $spacing / 2 - $self->{"topProf"}->GetPDOrigin->{"y"} + $self->{"h"} / 2;
		}
	}
	
	return $posY;
}

sub __GetBotProfilePosX {
	my $self = shift;

	my $posX = undef;

	# profile to profile

	if ( $self->{"centerType"} eq Enums->HCenter_BYPROF ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetWidth() ) / 2;

	}
	elsif ( $self->{"centerType"} eq Enums->HCenter_BYDATA ) {

		$posX = ( $self->{"w"} - $self->{"botProf"}->GetPasteData()->GetWidth() ) / 2;
		$posX -= $self->{"botProf"}->GetPDOrigin->{"x"};
	}
	
	return $posX;
}

sub __GetBotProfilePosY {
	my $self = shift;

	my $posY = undef;

	my $spacing     = $self->GetSpacing();
	my $spacingType = $self->GetSpacingType();

	# Single paste data
	if ( $self->{"stencilType"} ne Enums->StencilType_TOPBOT ) {

		$posY = ( $self->{"h"} - $self->{"botProf"}->GetHeight() ) / 2;
	}

	# Merged paste data
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT  ) {

		# profile 2 profile dim
		if ( $spacingType eq Enums->Spacing_PROF2PROF ) {

			$posY = $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetHeight();
		}
		elsif ( $spacingType eq Enums->Spacing_DATA2DATA ) {

			$posY =
			  $self->{"h"} / 2 - $spacing / 2 - $self->{"botProf"}->GetPasteData()->GetHeight() - $self->{"botProf"}->GetPasteData()->GetHeight();
		}
	}
	
	return $posY;
}

# Find new roattion of paste profile
sub __RotateStencil {
	my $self = shift;

	unless ( $self->{"init"} ) {
		return 0;
	}

	if ( $self->{"stencilType"} eq Enums->StencilType_TOP ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth() ? "h" : "w";

		if ( $lSide ne $lProfSide ) {
			$self->{"topProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"stencilType"} eq Enums->StencilType_BOT ) {

		my $lSide = $self->GetHeight() > $self->GetWidth() ? "h" : "w";
		my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth() ? "h" : "w";

		if ( $lSide ne $lProfSide ) {
			$self->{"botProf"}->SwitchDim();
			print STDERR "switch profile\n";
		}
	}
	elsif ( $self->{"stencilType"} eq Enums->StencilType_TOPBOT ) {

		if ( $self->{"topProf"} ) {

			my $lSide     = $self->{"topProf"}->GetWidth() > $self->{"topProf"}->GetHeight() / 2 ? "h" : "w";
			my $lProfSide = $self->{"topProf"}->GetHeight() > $self->{"topProf"}->GetWidth()     ? "h" : "w";

			if ( $lSide ne $lProfSide ) {
				$self->{"topProf"}->SwitchDim();
				print STDERR "switch profile\n";
			}
		}

		if ( $self->{"botProf"} ) {

			my $lSide     = $self->{"botProf"}->GetWidth() > $self->{"botProf"}->GetHeight() / 2 ? "h" : "w";
			my $lProfSide = $self->{"botProf"}->GetHeight() > $self->{"botProf"}->GetWidth()     ? "h" : "w";

			if ( $lSide ne $lProfSide ) {
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

