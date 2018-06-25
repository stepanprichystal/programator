
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnBuilder::CpnInfoTextBuilder;

use Class::Interface;
&implements('Packages::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Packages::Coupon::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::Coupon::CpnBuilder::CpnLayout::InfoTextLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"}     = shift;    # global settings for generating coupon
	$self->{"singleCpnVar"} = shift;
	$self->{"cpnSingle"}    = shift;

	$self->{"layout"} = InfoTextLayout->new();    # Layout of one single coupon

	$self->{"microstrips"} = [];

	$self->{"build"} = 0;                         # indicator if layout was built

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	return $result if ( !$self->{"settings"}->GetInfoText() );

	my $textPos = $self->{"settings"}->GetInfoTextPosition();

	$self->{"layout"}->SetType($textPos);
	$self->{"singleCpnVar"}->IsMultistrip();

	# Info text will be placed on top
	my $curX = 0;
	my $curY = 0;

	my @strips = map { $_->GetStrips() } $self->{"singleCpnVar"}->GetPools();

	for ( my $i = scalar(@strips) - 1 ; $i >= 0 ; $i-- ) {

		my $stripVar  = $strips[$i];
		my $xmlConstr = $stripVar->Data()->{"xmlConstraint"};

		# built one text line or two lines
		my $txtPart1 = "";

		#		if ( $self->{"settings"}->GetInfoTextNumber() ) {
		#			$txtPart1 .= "<measure>";
		#		}

		if ( $self->{"settings"}->GetInfoTextTrackImpedance() ) {
			$txtPart1 .= sprintf( "%d", $xmlConstr->GetOption("CALCULATED_IMPEDANCE") ) . "ohm";
		}

		my $txtPart2 = "";

		if ( $self->{"settings"}->GetInfoTextTrackLayer() ) {
			$txtPart2 .=  $xmlConstr->GetOption("TRACE_LAYER")  . " - ";
		}

		if ( $self->{"settings"}->GetInfoTextTrackWidth() ) {
			$txtPart2 .= "W=" . sprintf( "%d", $xmlConstr->GetParamDouble("WB") );
		}

		if ( $self->{"settings"}->GetInfoTextTrackSpace() && $xmlConstr->ExistsParam("S") ) {
			$txtPart2 .= " S=" . sprintf( "%d", $xmlConstr->GetParamDouble("S") );
		}

		# text lines are placed horizontally
		if ( $textPos eq "right" ) {

			# split info text to 2 rows
			if ( !$self->{"singleCpnVar"}->IsMultistrip() ) {

				# bot row
				$self->{"layout"}->AddText( Point->new( $curX, $curY ), $txtPart2 );
				$curY += $self->{"settings"}->GetInfoTextHeight();
				$curY += $self->{"settings"}->GetInfoTextVSpacing();

				# top row
				$self->{"layout"}->AddText( Point->new( $curX, $curY ), $txtPart1 );
				$curY += $self->{"settings"}->GetInfoTextHeight()

			}
			else {

				$self->{"layout"}->AddText( Point->new( $curX, $curY ), $txtPart1 . " " . $txtPart2 );
				$curY += $self->{"settings"}->GetInfoTextHeight()

			}

			$curY += $self->{"settings"}->GetInfoTextVSpacing()

		}

		# text lines are placed vertically
		elsif ( $textPos eq "top" ) {

			my $t = "";

			if ( scalar( $self->{"layout"}->GetTexts() ) > 0 ) {

				$self->{"layout"}->AddText( Point->new( $curX, $curY ), "|" );
				$curX += $self->{"settings"}->GetInfoTextHSpacing();
			}

			$t .= $txtPart1 . " " . $txtPart2;

			$self->{"layout"}->AddText( Point->new( $curX, $curY ), $t );

			$curX += length($t) * $self->{"settings"}->GetInfoTextWidth();
			$curX += $self->{"settings"}->GetInfoTextHSpacing();

		}

	}

	if ( $textPos eq "right" ) {

		$self->{"layout"}->SetHeight( $curY - $self->{"settings"}->GetInfoTextVSpacing() );

		# search max lines
		my $maxLen = max( map { length( $_->{"val"} ) } $self->{"layout"}->GetTexts() );
		$self->{"layout"}->SetWidth( $maxLen * $self->{"settings"}->GetInfoTextWidth() );

	}
	elsif ( $textPos eq "top" ) {

		$self->{"layout"}->SetHeight( $self->{"settings"}->GetInfoTextHeight() );
		$self->{"layout"}->SetWidth( $curX - $self->{"settings"}->GetInfoTextHSpacing() );
	}

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

sub GetType {
	my $self = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

