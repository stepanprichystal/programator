
#-------------------------------------------------------------------------------------------#
# Description: Helper for exporting Jet print files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Jetprint::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::Jetprint::Enums';
use aliased "Packages::Polygon::PolygonFeatures";
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Return default fiducial marks for jet rite
sub GetDefaultFiduc {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $pcbType   = shift // CamHelper->GetPcbType( $inCAM, $jobId );
	my $boardBase = shift // [ CamJob->GetBoardBaseLayers( $inCAM, $jobId ) ];

	my $fiducType = Enums->Fiducials_SUN5;    # default is sun

	my $pcExist    = scalar( grep { $_->{"gROWname"} eq "pc" } @{$boardBase} )        ? 1 : 0;
	my $psExist    = scalar( grep { $_->{"gROWname"} eq "ps" } @{$boardBase} )        ? 1 : 0;
	my $mcExist    = scalar( grep { $_->{"gROWname"} eq "mc" } @{$boardBase} )        ? 1 : 0;
	my $msExist    = scalar( grep { $_->{"gROWname"} eq "ms" } @{$boardBase} )        ? 1 : 0;
	my $cvrlcExist = scalar( grep { $_->{"gROWname"} eq "cvrlc" } @{$boardBase} ) ? 1 : 0;
	my $cvrlsExist = scalar( grep { $_->{"gROWname"} eq "cvrls" } @{$boardBase} ) ? 1 : 0;

	# Check exceptions
	if ( ( $pcExist && !$mcExist && $cvrlcExist ) || ( $psExist && !$msExist && $cvrlsExist ) ) {

		# Coverlay from top without mask
		$fiducType = Enums->Fiducials_HOLE3;

	}
	elsif ( $pcbType eq EnumsGeneral->PcbType_NOCOPPER ) {

		# No copper
		$fiducType = Enums->Fiducials_HOLE3;

	}
	elsif ( $pcbType eq EnumsGeneral->PcbType_1V && $psExist ) {

		# 1V with bottom silcscreen
		$fiducType = Enums->Fiducials_HOLE3;
	
	}elsif ( $pcbType eq EnumsGeneral->PcbType_1VFLEX || $pcbType eq EnumsGeneral->PcbType_2VFLEX ) {

		#  Flexible PCB, because solder mask is not cover sun fiducials at panel edge, 
		# so we can't use them
		$fiducType = Enums->Fiducials_HOLE3;
	}

	return $fiducType;
}

# Return default rotation by panel height
# 0 = 0deg
# 1 = 90deg
sub GetDefaultRotation {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $layerCnt = shift // CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $profLim  = shift // {CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" )};

	my $maxJetprintLen = 600;    # 600 mm height panel

	# Rotate data 90° if PCB is too long
	my $rot = 0;
	my %lim = ();

	if ( $layerCnt > 2 ) {

		my $route = Features->new();
		$route->Parse( $inCAM, $jobId, "panel", "fr" );
		my @features = $route->GetFeatures();
		%lim = PolygonFeatures->GetLimByRectangle( \@features );

	}
	else {

		%lim = %{$profLim};
	}

	$rot = 1 if ( ( $lim{"yMax"} - $lim{"yMin"} ) > $maxJetprintLen );

	return $rot;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Jetprint::Helper';
	use aliased 'Packages::InCAM::InCAM';

	#	my $inCAM = InCAM->new();
	#
	#	my $jobId    = "d246713";
	#	my $stepName = "panel";
	#
	#	my %types = Helper->CreateFakeLayers( $inCAM, $jobId, "panel" );
	#
	#	print %types;
}

1;

