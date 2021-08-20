
#-------------------------------------------------------------------------------------------#
# Description: Helper for exporting MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mditt::ExportFiles::Helper;

#3th party library
use strict;
use warnings;
use List::Util qw[max min first];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Enums';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

use constant MAXPNLH => 700;    # maximal height of panel, for exposing pnl "Vertical" (not rotated)

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Return layer types which should be exported by default
sub GetDefaultLayerCouples {
	my $self = shift;

	my $inCAM = shift;
	my $jobId = shift;

	my $signalLayer = shift // 1;
	my $maskLayer   = shift // 1;
	my $plugLayer   = shift // 1;
	my $goldLayer   = shift // 1;

	my @exportLayers = ();

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $stackup = undef;
	if ( $layerCnt > 2 ) {

		$stackup = Stackup->new( $inCAM, $jobId );
	}

	my @all = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	# Signal layers
	if ($signalLayer) {

		if ( $layerCnt <= 2 ) {

			if ( $layerCnt <= 1 ) {

				my $pcbType = JobHelper->GetPcbType($jobId);

				# No copper pcb has sigl laer in matrix, but it is only helper layer, do not export
				if ( $pcbType ne EnumsGeneral->PcbType_NOCOPPER ) {
					my @couple = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^[cs]$/ } @all;

					push( @exportLayers, \@couple );
				}
			}
			else {
				my @couple = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^[cs]$/ } @all;

				push( @exportLayers, \@couple );
			}

		}
		else {

			my @products = $stackup->GetAllProducts();

			foreach my $p (@products) {

				# Skip if producti is parent input product,
				# - which doesn not contain any pressing
				# - or doesn't contain Cu foil as outer layers (Cu foil must be not "empty")
				if ( $p->GetProductType() eq StackEnums->Product_INPUT && $p->GetIsParent() ) {

					my $matLTop = $p->GetProductOuterMatLayer("first")->GetData();
					my $matLBot = $p->GetProductOuterMatLayer("last")->GetData();

					if (
						 scalar( $p->GetLayers() ) == 1
						 || !(
							      $matLTop->GetType() eq StackEnums->MaterialType_COPPER
							   && $matLBot->GetType() eq StackEnums->MaterialType_COPPER
							   && !$p->GetTopEmptyFoil()
							   && !$p->GetBotEmptyFoil()
						 )
					  )
					{
						next;
					}
				}

				my $topLName = JobHelper->BuildSignalLayerName( $p->GetTopCopperLayer(), $p->GetOuterCoreTop(), 0 );
				my $botLName = JobHelper->BuildSignalLayerName( $p->GetBotCopperLayer(), $p->GetOuterCoreBot(), 0 );

				my $topL = first { $_->{"gROWname"} =~ /^$topLName$/ } @all;
				my $botL = first { $_->{"gROWname"} =~ /^$botLName$/ } @all;

				push( @exportLayers, [ $topL->{"gROWname"}, $botL->{"gROWname"} ] );
			}
		}
	}

	# Solder mask layers
	if ($maskLayer) {

		my @l = grep { $_->{"gROWname"} =~ /^m[cs]2?$/ } @all;    # number 2 is second soldermask

		my @suffixes = ( "", "2" );                               #mask name suffix

		foreach my $suff (@suffixes) {

			my @l = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^m[cs]$suff$/ } @l;

			if ( scalar(@l) ) {

				push( @exportLayers, \@l );
			}
		}
	}

	# Plugging layers
	if ($plugLayer) {

		if ( $layerCnt <= 2 ) {

			my @couple = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^plg[cs]$/ } @all;

			push( @exportLayers, \@couple ) if ( scalar(@couple) );

		}
		else {

			my @products = $stackup->GetAllProducts();

			foreach my $p (@products) {

				if ( $p->GetPlugging() ) {

					my $topLName = JobHelper->BuildSignalLayerName( $p->GetTopCopperLayer(), 0, $p->GetPlugging() );
					my $botLName = JobHelper->BuildSignalLayerName( $p->GetBotCopperLayer(), 0, $p->GetPlugging() );

					my $topL = first { $_->{"gROWname"} =~ /^$topLName$/ } @all;
					my $botL = first { $_->{"gROWname"} =~ /^$botLName$/ } @all;

					push( @exportLayers, [ $topL->{"gROWname"}, $botL->{"gROWname"} ] );
				}
			}

		}
	}

	# Gold layers
	if ($goldLayer) {

		my @l = map { $_->{"gROWname"} } grep { $_->{"gROWname"} =~ /^gold[cs]$/ } @all;

		push( @exportLayers, \@l ) if ( scalar(@l) );
	}

	# Check if all couples has 1-2 layers

	foreach my $couple (@exportLayers) {

		my $lCnt = scalar( @{$couple} );

		die "Wrong number of layers (min 1 max 2)" if ( $lCnt < 1 || $lCnt > 2 );

		my @undef = grep { !defined $_ } @{$couple};

		die "Layer is not defined " if ( scalar(@undef) );

	}

	return @exportLayers;
}

# Return  default settings for specific layer type
# Hash contains:
# - rotationCCW: 0/90 (vertical orientation/horizontal orientation)
# - fiducialType: Fiducials_CUSQUERE/Fiducials_OLECHOLE
sub GetDefaultLayerSett {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layerName = shift;

	my %sett = ( "rotationCCW" => undef, "fiducialType" => undef );

	my $pcbType  = JobHelper->GetPcbType($jobId);
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $stackup  = undef;
	if ( $layerCnt > 2 ) {

		$stackup = Stackup->new( $inCAM, $jobId );
	}

	# 1) Set Rotatin
	my $rotationCW = 0;
	my %profLim    = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my $pnlH       = $profLim{"yMax"} - $profLim{"yMin"};

	if ( $pnlH > MAXPNLH ) {
		$sett{"rotationCCW"} = 90;
	}
	else {
		$sett{"rotationCCW"} = 0;
	}

	# 2) Set fiducials

	if ( $layerName =~ /^(outer)?[csv]\d?$/ ) {

		# SIGNAL LAYERS

		if ( $layerCnt <= 2 ) {

			# 2v
			$sett{"fiducialType"} = Enums->Fiducials_OLECHOLE2V;

		}
		else {

			# vv

			if ( $layerName =~ /^outer/ ) {

				$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEINNERVV;
			}
			else {

				if ( $layerName =~ /^[cs]/ ) {

					$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEOUTERVV;
				}
				elsif ( $layerName =~ /^v\d+/ ) {

					my %lPars = JobHelper->ParseSignalLayerName($layerName);

					if ( $stackup->GetSequentialLam() && $stackup->GetCuLayer( $lPars{"sourceName"} )->GetIsFoil() ) {

						$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEINNERVVSL;
					}
					else {

						$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEINNERVV;
					}

				}
			}

			# vv
		}
	}
	elsif ( $layerName =~ /^m[cs]\d?$/ ) {

		# SOLDER MASK

		if ( $layerCnt <= 2 ) {

			# 2v

			if (    ( $layerName =~ /^mc\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "c" ) && $pcbType ne EnumsGeneral->PcbType_NOCOPPER )
				 || ( $layerName =~ /^ms\d?$/ && CamHelper->LayerExists( $inCAM, $jobId, "s" ) ) )
			{
				$sett{"fiducialType"} = Enums->Fiducials_CUSQUERE;
			}
			else {

				$sett{"fiducialType"} = Enums->Fiducials_OLECHOLE2V;
			}
		}
		else {

			# vv

			$sett{"fiducialType"} = Enums->Fiducials_CUSQUERE;
		}

	}
	elsif ( $layerName =~ /^plg[csv]\d?$/ ) {

		# PLUG LAYERS

		if ( $layerCnt <= 2 ) {

			# 2v

			$sett{"fiducialType"} = Enums->Fiducials_OLECHOLE2V;
		}
		else {

			# vv

			my %lPars = JobHelper->ParseSignalLayerName($layerName);

			if ( $lPars{"sourceName"} =~ /^[cs]$/ ) {

				$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEOUTERVV;
			}
			else {
				if ( $stackup->GetSequentialLam() && $stackup->GetCuLayer( $lPars{"sourceName"} )->GetIsFoil() ) {

					$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEINNERVVSL;
				}
				else {

					$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEINNERVV;
				}

			}

		}

	}
	elsif ( $layerName =~ /^gold[cs]\d?$/ ) {

		# GOLD LAYER

		if ( $layerCnt <= 2 ) {

			# 2v

			$sett{"fiducialType"} = Enums->Fiducials_OLECHOLE2V;

		}
		else {

			# vv

			$sett{"fiducialType"} = Enums->Fiducials_OLECHOLEOUTERVV;
		}

	}

	die "Rotation is not defined for layer: $layerName"     if ( !defined $sett{"rotationCCW"} );
	die "Fiducial type is not defined for layer: $layerName" if ( !defined $sett{"fiducialType"} );

	return %sett;
}

# Convert layer type outer<layer name> to filename exported fotr MDI
sub ConverOuterName2FileName {
	my $self     = shift;
	my $lName    = shift;
	my $layerCnt = shift;

	my $fileName = undef;

	my %lPars = JobHelper->ParseSignalLayerName($lName);

	die "Layer: $lName is not outer type" if ( !$lPars{"outerCore"} );

	if ( $lPars{"sourceName"} =~ /^v\d+/ ) {

		$fileName = $lPars{"sourceName"};
	}
	elsif ( $lPars{"sourceName"} eq "c" ) {

		$fileName = "v1";
	}
	elsif ( $lPars{"sourceName"} eq "s" ) {

		$fileName = "v" . $layerCnt;
	}

	return $fileName;
}

# Convert inner layer to filename with suffix "after pressing" exported for MDI
sub ConverInnerName2AfterPressFileName {
	my $self  = shift;
	my $lName = shift;

	die "Layer name: $lName is in wrong format" unless ( $lName =~ /^v\d+$/ );

	return $lName . "_po_lisovani";

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Mditt::ExportFiles::Helper';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d246713";
	my $stepName = "panel";

	my %types = Helper->CreateFakeLayers( $inCAM, $jobId, "panel" );

	print %types;
}

1;

