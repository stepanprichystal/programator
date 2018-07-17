
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::CpnInfoTextBuilder;

use Class::Interface;
&implements('Programs::Coupon::CpnBuilder::ICpnBuilder');

#3th party library
use strict;
use warnings;
use Switch;
use List::Util qw[min max];

#local library
use aliased 'Programs::Coupon::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::PointLayout';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::InfoTextLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"layout"}       = InfoTextLayout->new();    # Layout of one single coupon
	$self->{"build"}        = 0;                        # indicator if layout was built
	$self->{"singleCpnVar"} = undef;

	# Settings references
	$self->{"cpnSett"} = undef;                         # global settings for generating coupon

	return $self;
}

# Build single coupon layout
# If ok return 1, else 0 + err message
sub Build {
	my $self         = shift;
	my $cpnSingleVar = shift;
	my $cpnSett      = shift;
	my $errMess      = shift;

	$self->{"singleCpnVar"} = $cpnSingleVar;
	$self->{"cpnSett"}      = $cpnSett;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	return $result if ( !$self->{"cpnSett"}->GetInfoText() );

	my $textPos = $self->{"cpnSett"}->GetInfoTextPosition();

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

		#		if ( $self->{"cpnSett"}->GetInfoTextNumber() ) {
		#			$txtPart1 .= "<measure>";
		#		}

		if ( $self->{"cpnSett"}->GetInfoTextTrackImpedance() ) {
			$txtPart1 .= sprintf( "%d", $xmlConstr->GetOption("CALCULATED_IMPEDANCE") ) . "ohm";
		}

		my $txtPart2 = "";

		if ( $self->{"cpnSett"}->GetInfoTextTrackLayer() ) {
			$txtPart2 .= $xmlConstr->GetOption("TRACE_LAYER") . " - ";
		}

		if ( $self->{"cpnSett"}->GetInfoTextTrackWidth() ) {
			$txtPart2 .= "W=" . sprintf( "%d", $xmlConstr->GetParamDouble("WB") );
		}

		if ( $self->{"cpnSett"}->GetInfoTextTrackSpace() && $xmlConstr->ExistsParam("S") ) {
			$txtPart2 .= " S=" . sprintf( "%d", $xmlConstr->GetParamDouble("S") );
		}

		# text lines are placed horizontally
		if ( $textPos eq "right" ) {

			# split info text to 2 rows
			if ( !$self->{"singleCpnVar"}->IsMultistrip() ) {

				# bot row
				$self->{"layout"}->AddText( PointLayout->new( $curX, $curY ), $txtPart2 );
				$curY += $self->{"cpnSett"}->GetInfoTextHeight() / 1000;
				$curY += $self->{"cpnSett"}->GetInfoTextVSpacing() / 1000;

				# top row
				$self->{"layout"}->AddText( PointLayout->new( $curX, $curY ), $txtPart1 );
				$curY += $self->{"cpnSett"}->GetInfoTextHeight() / 1000

			}
			else {

				$self->{"layout"}->AddText( PointLayout->new( $curX, $curY ), $txtPart1 . " " . $txtPart2 );
				$curY += $self->{"cpnSett"}->GetInfoTextHeight() / 1000

			}

			$curY += $self->{"cpnSett"}->GetInfoTextVSpacing() / 1000

		}

		# text lines are placed vertically
		elsif ( $textPos eq "top" ) {

			my $t = "";

			if ( scalar( $self->{"layout"}->GetTexts() ) > 0 ) {

				$self->{"layout"}->AddText( PointLayout->new( $curX, $curY ), "|" );
				$curX += $self->{"cpnSett"}->GetInfoTextHSpacing() / 1000;
			}

			$t .= $txtPart1 . " " . $txtPart2;

			$self->{"layout"}->AddText( PointLayout->new( $curX, $curY ), $t );

			$curX += length($t) * $self->{"cpnSett"}->GetInfoTextWidth() / 1000;
			$curX += $self->{"cpnSett"}->GetInfoTextHSpacing() / 1000;

		}

	}

	if ( $textPos eq "right" ) {

		$self->{"layout"}->SetHeight( $curY - $self->{"cpnSett"}->GetInfoTextVSpacing() / 1000 );

		# search max lines
		my $maxLen = max( map { length( $_->{"val"} ) } $self->{"layout"}->GetTexts() );
		$self->{"layout"}->SetWidth( $maxLen * $self->{"cpnSett"}->GetInfoTextWidth() / 1000 );

	}
	elsif ( $textPos eq "top" ) {

		$self->{"layout"}->SetHeight( $self->{"cpnSett"}->GetInfoTextHeight() / 1000 );
		$self->{"layout"}->SetWidth( $curX - $self->{"cpnSett"}->GetInfoTextHSpacing() / 1000 );
	}
	
	$self->{"layout"}->SetInfoTextUnmask($self->{"cpnSett"}->GetInfoTextUnmask());
	
	$self->{"layout"}->SetInfoTextHeight($self->{"cpnSett"}->GetInfoTextHeight());
	$self->{"layout"}->SetInfoTextWidth($self->{"cpnSett"}->GetInfoTextWidth());
	$self->{"layout"}->SetInfoTextWeight($self->{"cpnSett"}->GetInfoTextWeight());
	


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

