
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::OtherBuilders::TitleBuilder;

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
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}            = shift;
	$self->{"jobId"}            = shift;
	$self->{"cpnsSingleHeight"} = shift;

	$self->{"layout"}       = TitleLayout->new();    # Layout of one single coupon
	$self->{"build"}        = 0;                     # indicator if layout was built
	$self->{"singleCpnVar"} = undef;

	# Settings references
	$self->{"cpnSett"} = undef;                      # global settings for generating coupon

	# Other properties

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

	return $result if ( !$self->{"cpnSett"}->GetTitle() );

	my $type = $self->{"cpnSett"}->GetTitleType();
	$self->{"layout"}->SetType($type);

	my $titleW = ( 2 * $self->{"cpnSett"}->GetTitleMargin() ) / 1000;
	my $titleH = ( 2 * $self->{"cpnSett"}->GetTitleMargin() ) / 1000;

	my $totalWidth = 0;

	# logo + job id width (1 row)
	my $logoText = "Gatema";

	$totalWidth += $self->{"cpnSett"}->GetLogoWidth();
	$totalWidth += $self->{"cpnSett"}->GetTitleLogoJobIdHDist();
	$totalWidth += length( $self->{"jobId"} ) * $self->{"cpnSett"}->GetTitleTextWidth();
	$totalWidth += 2 * $self->{"cpnSett"}->GetTitleMargin();

	# Check if title will be in one or two rows

	my $rowCnt = 1;

	if ( $type eq "left" && ($totalWidth / 1000) > $self->{"cpnsSingleHeight"} ) {
		$rowCnt = 2;
	}

	#$rowCnt = 1;
	$self->{"layout"}->SetJobIdVal( uc( $self->{"jobId"} ) );

	# title in 1 row
	if ( $rowCnt == 1 ) {

		my $logoPos = Point->new(
			$self->{"cpnSett"}->GetTitleMargin() / 1000 + $self->{"cpnSett"}->GetLogoWidth() / 2 / 1000,
			$self->{"cpnSett"}->GetTitleMargin() / 1000 + $self->{"cpnSett"}->GetLogoHeight() / 2 / 1000    # logo is pad and pad has origin in center
		);

		#$logoPos->Rotate( 90, 0 ) if ( $type eq "left" );

		$self->{"layout"}->SetLogoPosition($logoPos);

		my $jobIdPos = Point->new(
			$self->{"cpnSett"}->GetTitleMargin() / 1000 +
			  $self->{"cpnSett"}->GetLogoWidth() / 1000 +
			  $self->{"cpnSett"}->GetTitleLogoJobIdHDist() / 1000,

			$self->{"cpnSett"}->GetTitleMargin() / 1000
		);

		#$jobIdPos->Rotate( 90, 0 ) if ( $type eq "left" );

		$self->{"layout"}->SetJobIdPosition($jobIdPos);

		# set total w + h
		$titleW += $self->{"cpnSett"}->GetLogoWidth() / 1000;
		$titleW += ( $self->{"cpnSett"}->GetTitleLogoJobIdHDist() ) / 1000;
		$titleW += ( length( $self->{"jobId"} ) * $self->{"cpnSett"}->GetTitleTextWidth() ) / 1000;

		$titleH += max( ( $self->{"cpnSett"}->GetTitleTextHeight(), $self->{"cpnSett"}->GetLogoHeight() ) ) / 1000;

	}

	# title in 2 rows
	else {

		my $jobIdPos = Point->new( ( $self->{"cpnSett"}->GetTitleMargin() ) / 1000, ( $self->{"cpnSett"}->GetTitleMargin() ) / 1000 );

		#$jobIdPos->Rotate( 90, 0 ) if ( $type eq "left" );

		$self->{"layout"}->SetJobIdPosition($jobIdPos);

		my $logoPos = Point->new(
			( $self->{"cpnSett"}->GetTitleMargin() ) / 1000 + $self->{"cpnSett"}->GetLogoWidth() / 2 / 1000,
			(
			   $self->{"cpnSett"}->GetTitleMargin() +
				 $self->{"cpnSett"}->GetTitleTextHeight() +
				 $self->{"cpnSett"}->GetTitleLogoJobIdVDist() +
				 $self->{"cpnSett"}->GetTitleTextHeight() / 2     # logo is pad and pad has origin in center
			) / 1000
		);

		#$logoPos->Rotate( 90, 0 ) if ( $type eq "left" );

		$self->{"layout"}->SetLogoPosition($logoPos);

		# set total w + h
		$titleW += max( ( $self->{"cpnSett"}->GetLogoWidth() / 1000, length( $self->{"jobId"} ) * $self->{"cpnSett"}->GetTitleTextWidth() / 1000 ) );

		$titleH +=
		  $self->{"cpnSett"}->GetTitleTextHeight() / 1000 +
		  $self->{"cpnSett"}->GetTitleLogoJobIdVDist() / 1000 +
		  $self->{"cpnSett"}->GetLogoHeight() / 1000;

	}

	$self->{"layout"}->SetHeight($titleH);
	$self->{"layout"}->SetWidth($titleW);

	# Consider "title" position
	my $titlePos;
	if ( $type eq "top" ) {

		my $logoPos    = $self->{"layout"}->GetLogoPosition();
		my $logoPosNew = Point->new( $self->{"cpnSett"}->GetCouponMargin() / 1000 + $logoPos->X(),
									 $self->{"cpnSett"}->GetCouponMargin() / 1000 + $self->{"cpnsSingleHeight"} + $logoPos->Y() );
		$self->{"layout"}->SetLogoPosition($logoPosNew);

		my $jobIdPos    = $self->{"layout"}->GetJobIdPosition();
		my $jobIdPosNew = Point->new( $self->{"cpnSett"}->GetCouponMargin() / 1000 + $jobIdPos->X(),
									  $self->{"cpnSett"}->GetCouponMargin() / 1000 + $self->{"cpnsSingleHeight"} + $jobIdPos->Y() );
		$self->{"layout"}->SetJobIdPosition($jobIdPosNew);

	}
	elsif ( $type eq "left" ) {

		my $xPos = $titleH;

		if ( $self->{"cpnSett"}->GetCouponMargin() / 1000 >= $titleH ) {

			$xPos = $self->{"cpnSett"}->GetCouponMargin() / 1000;
		}

		my $yPos = ( ( $self->{"cpnsSingleHeight"} + 2 * $self->{"cpnSett"}->GetCouponMargin() / 1000 ) - $titleW ) / 2;

		my $logoPos = $self->{"layout"}->GetLogoPosition();
		$logoPos->Rotate( 90, 0 );

		my $logoPosNew = Point->new( $xPos + $logoPos->X(), $yPos + $logoPos->Y() );
		$self->{"layout"}->SetLogoPosition($logoPosNew);

		my $jobIdPos = $self->{"layout"}->GetJobIdPosition();
		$jobIdPos->Rotate( 90, 0 );
		my $jobIdPosNew = Point->new( $xPos + $jobIdPos->X(), $yPos + $jobIdPos->Y() );
		$self->{"layout"}->SetJobIdPosition($jobIdPosNew);
	}

	$self->{"layout"}->SetTitleUnMask( $self->{"cpnSett"}->GetTitleUnMask() );

	$self->{"layout"}->SetTitleTextHeight( $self->{"cpnSett"}->GetTitleTextHeight() );
	$self->{"layout"}->SetTitleTextWidth( $self->{"cpnSett"}->GetTitleTextWidth() );
	$self->{"layout"}->SetTitleTextWeight( $self->{"cpnSett"}->GetTitleTextWeight() );

	$self->{"layout"}->SetLogoSymbol( $self->{"cpnSett"}->GetLogoSymbol() );
	$self->{"layout"}->SetLogoWidth( $self->{"cpnSett"}->GetLogoWidth() );
	$self->{"layout"}->SetLogoHeight( $self->{"cpnSett"}->GetLogoHeight() );
	$self->{"layout"}->SetLogoSymbolWidth( $self->{"cpnSett"}->GetLogoSymbolWidth() );
	$self->{"layout"}->SetLogoSymbolHeight( $self->{"cpnSett"}->GetLogoSymbolHeight() );

	$self->{"build"} = 1;

	return $result;
}

sub GetLayout {
	my $self = shift;

	return $self->{"layout"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

