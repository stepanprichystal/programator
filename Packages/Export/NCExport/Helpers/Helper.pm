
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Helpers::Helper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use List::Util qw[max min first];

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsDrill';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-----

sub UpdateNCInfo {
	my $self      = shift;
	my $jobId     = shift;
	my @info      = @{ shift(@_) };
	my $errorMess = shift;

	my $result = 1;

	my $infoStr = $self->__BuildNcInfo( \@info );

	eval {

		# TODO this is temporary solution
		#		my $path = GeneralHelper->Root() . "\\Connectors\\HeliosConnector\\UpdateScript.pl";
		#		my $ncInfo = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
		#
		#		print STDERR "path nc info is:".$ncInfo."\n\n";
		#		print STDERR "path script is :".$path."\n\n";
		#		my $f;
		#		open($f, ">", $ncInfo);
		#		print $f $infoStr;
		#		close($f);
		#		system("perl $path $jobId $ncInfo");
		# TODO this is temporary solution

		$result = HegMethods->UpdateNCInfo( $jobId, $infoStr, 1 );
		unless ($result) {

			$$errorMess = "Failed to update NC-info.";
		}

	};
	if ( my $e = $@ ) {

		if ( ref($e) && $e->isa("Packages::Exceptions::HeliosException") ) {

			$$errorMess = $e->{"mess"};
		}

		$result = 0;
	}

	return $result;
}

# Build string "nc info" based on information from nc manager
sub __BuildNcInfo {
	my $self = shift;
	my @info = @{ shift(@_) };

	my $str = "";

	for ( my $i = 0 ; $i < scalar(@info) ; $i++ ) {

		my %item = %{ $info[$i] };

		my @data = @{ $item{"data"} };

		if ( $item{"group"} ) {
			$str .= "\nSkupina operaci:\n";
		}
		else {
			$str .= "\nSamostatna operace:\n";
		}

		foreach my $item (@data) {

			my $row = "[ " . $item->{"name"} . " ] - ";

			my $mach = join( ", ", @{ $item->{"machines"} } );

			$row .= uc($mach) . "\n";

			$str .= $row;
		}

	}

	return $str;
}

sub StoreOperationInfoTif {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $step          = shift;
	my $operationMngr = shift;

	my $tif = TifNCOperations->new($jobId);

	# 1) store operations

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );    # Signal layer cnt

	my @op = ();

	my @opItems = ();
	foreach my $opItem ( $operationMngr->GetOperationItems() ) {

		if ( defined $opItem->GetOperationGroup() ) {

			push( @opItems, $opItem );
			next;
		}

		if ( !defined $opItem->GetOperationGroup() ) {

			# unless operation definition is defined at least in one operations in group operation items
			# process this operation

			my $o = ( $opItem->GetOperations() )[0];

			my $isInGroup = scalar( grep { $_->GetName() eq $o->GetName() }
									map { $_->GetOperations() } grep { defined $_->GetOperationGroup() } $operationMngr->GetOperationItems() );

			push( @opItems, $opItem ) if ( !$isInGroup );

		}

	}

	foreach my $opItem (@opItems) {
		my %opInf = ();

		# Set Operation name
		$opInf{"opName"} = $opItem->GetName();

		my @layers = $opItem->GetSortedLayers();

		# Ser Operation machines
		my @machines = map { $_->{"suffix"} } $opItem->GetMachines();
		$opInf{"machines"} = {};
		$opInf{"machines"}->{$_} = {} foreach @machines;

		# Set if operation contains rout layers
		my $isRout = scalar( grep { $_->{"gROWlayer_type"} eq "rout" } @layers ) ? 1 : 0;
		$opInf{"isRout"} = $isRout;

		my $matThick;
		if ( $layers[0]->{"gROWdrl_start"} =~ /^(cvrl)|(bend)/ ) {
			$matThick = 0;
		}
		else {
			if ( $layerCnt <= 2 ) {

				$matThick = HegMethods->GetPcbMaterialThick($jobId);
			}
			else {
				my $stackup = Stackup->new( $inCAM, $jobId );
				$matThick = $stackup->GetThickByCuLayer( $layers[0]->{"NCSigStart"} ) / 1000;
			}
		}

		# Set material thickness during operation
		$opInf{"ncMatThick"} = $matThick * 1000;

		# Set operation min standard "not special" slot tool
		$opInf{"minSlotTool"} = undef;

		if ($isRout) {

			foreach my $layer (@layers) {

				my $unitDTM = UniDTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 1 );
				my $tool = $unitDTM->GetMinTool( EnumsDrill->TypeProc_CHAIN, 1 );    # slot tool, default (no special)

				# tool type chain doesn't have exist
				next if ( !defined $tool );

				if ( !defined $opInf{"minSlotTool"} || $tool->GetDrillSize() < $opInf{"minSlotTool"} ) {
					$opInf{"minSlotTool"} = $tool->GetDrillSize();
				}
			}
		}

		# Set operation layers
		@layers = map { $_->{"gROWname"} } @layers;
		$opInf{"layers"} = \@layers;

		# Set stretch value for NC layer
		my @stretchX = ();
		my @stretchY = ();

		#		my @stretchX = ();
		#my @stretchY = ();

		push( @op, \%opInf );

	}

	$tif->SetNCOperations( \@op );

	# 2) store rout tool info
	my %toolInfo = ();

	my @layers =
	  map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "rout" && $_->{"gROWname"} ne "score" } CamJob->GetNCLayers( $inCAM, $jobId );
	foreach my $s ( ( map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step ) ), $step ) {

		$toolInfo{$s} = {};

		foreach my $l (@layers) {

			my $rtm = UniRTM->new( $inCAM, $jobId, $s, $l );

			foreach my $ch ( $rtm->GetChains() ) {

				my $outline = scalar( grep { $_->IsOutline() } $ch->GetChainSequences() ) == scalar( $ch->GetChainSequences() ) ? 1 : 0;
				$toolInfo{$s}->{$l}->{ $ch->GetChainTool()->GetChainOrder() } = { "isOutline" => $outline };
			}
		}
	}

	$tif->SetToolInfos( \%toolInfo );

}

sub StoreNClayerSettTif {
	my $self          = shift;
	my $inCAM         = shift;
	my $jobId         = shift;
	my $layerSett     = shift;
	my $operationMngr = shift;

	# 1) Before store settings, check if layers which are merged have same scale settings

	my @opItems = ();
	foreach my $opItem ( $operationMngr->GetOperationItems() ) {

		my @lSetts = ();

		foreach my $l ( $opItem->GetSortedLayers() ) {
			push( @lSetts, first { $_->{"name"} eq $l->{"gROWname"} } @{$layerSett} );
		}

		my @stretchX = uniq( map { $_->{"stretchX"} } @lSetts );
		my @stretchY = uniq( map { $_->{"stretchY"} } @lSetts );

		die "NC layers (" . join( "; ", map { $_->{"name"} } @lSetts ) . ") to merging has different \"StretchX\" parameter."
		  if ( scalar(@stretchX) > 1 );

		die "NC layers (" . join( "; ", map { $_->{"name"} } @lSetts ) . ") to merging has different \"StretchY\" parameter."
		  if ( scalar(@stretchY) > 1 );
	}

	# 2) Store NC layer settings
	my $tif = TifNCOperations->new($jobId);

	$tif->SetNCLayerSett($layerSett);
}

# Move z-axis coupon steps to temporary panel step
# Return number of removed/moved z-axis coupons
sub SeparateCouponZaxis {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $sourcePnl = shift;
	my $cpnPnl    = shift;

	# If exist coupon depth steps, copy main panel and separate coupn steps
	my $cpnName = EnumsGeneral->Coupon_ZAXIS;

	# 1) Create coupon panel + copy coupon steps
	my $sr = SRStep->new( $inCAM, $jobId, $cpnPnl );

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $sourcePnl );

	my $aPnl = ActiveArea->new( $inCAM, $jobId, $sourcePnl );
	$sr->Create( ( $lim{"xMax"} - $lim{"xMin"} ),
				 ( $lim{"yMax"} - $lim{"yMin"} ),
				 $aPnl->BorderT(), $aPnl->BorderB(), $aPnl->BorderL(), $aPnl->BorderR(), { "x" => $lim{"xMin"}, "y" => $lim{"yMin"} } );

	my @repeats = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $sourcePnl );
	@repeats = grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } @repeats;

	foreach my $r (@repeats) {
		$sr->AddSRStep( $r->{"stepName"}, $r->{"gSRxa"}, $r->{"gSRya"}, $r->{"gSRangle"}, $r->{"gSRnx"}, $r->{"gSRny"}, $r->{"gSRdx"},
						$r->{"gSRdy"} );
	}
	
	# Copy signal layer c + v - need fiducials
	CamMatrix->CopyLayer( $inCAM, $jobId, "c", $sourcePnl, "c", $cpnPnl );
	CamMatrix->CopyLayer( $inCAM, $jobId, "v", $sourcePnl, "v", $cpnPnl );

	# 2) Remove coupons from source panel step
	CamHelper->SetStep( $inCAM, $sourcePnl );
	my @repeatsSrc = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $sourcePnl );
	@repeatsSrc = grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } @repeatsSrc;
	foreach my $r (@repeatsSrc) {
		CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $sourcePnl, $r->{"stepName"} );
	}

	return scalar(@repeats);

}

# Get back  z-axis coupon steps from temporary panel to source panel
sub RestoreCouponZaxis {
	my $self            = shift;
	my $inCAM           = shift;
	my $jobId           = shift;
	my $sourcePnl       = shift;
	my $cpnPnl          = shift;
	my $removedStepsCnt = shift;

	if ( $removedStepsCnt > 0 ) {

		# If exist coupon depth steps, copy main panel and separate coupn steps
		my $cpnName = EnumsGeneral->Coupon_ZAXIS;
		
		my @zAxisCpn = grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } CamStepRepeat->GetUniqueDeepestSR( $inCAM, $jobId, $cpnPnl );
		
		 
		die "No z-axis coupon in panel step: " . $self->{"stepName"} unless ( scalar(@zAxisCpn) );

		my $sr = SRStep->new( $inCAM, $jobId, $sourcePnl );

		my @repeats = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $cpnPnl );
		@repeats = grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } @repeats;

		foreach my $r (@repeats) {
			$sr->AddSRStep( $r->{"stepName"}, $r->{"gSRxa"}, $r->{"gSRya"}, $r->{"gSRangle"},
							$r->{"gSRnx"},    $r->{"gSRny"}, $r->{"gSRdx"}, $r->{"gSRdy"} );
		}

		# Final check if z-axis coupon steps count is same as before separation
		my @repeatsSrc = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $sourcePnl );
		@repeatsSrc = grep { $_->{"stepName"} =~ /^$cpnName\d+$/i } @repeatsSrc;

		if ( scalar(@repeatsSrc) != $removedStepsCnt ) {

			die "Error during restore z-axis steps to panel step. Removed steps: $removedStepsCnt, Restored steps: " . scalar(@repeatsSrc);
		}

		# Remove temporary panel
		CamStep->DeleteStep( $inCAM, $jobId, $cpnPnl );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

