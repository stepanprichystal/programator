#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for checking drilling warnings
# when some warning occur, NC export is still possible
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw[max min];

#local library

#use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'CamHelpers::CamDTM';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub CheckNCLayers {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $stepName    = shift;
	my $layerFilter = shift;
	my $mess        = shift;

	my $result = 1;

	# Get all layers
	my @allLayers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	my @layers = ();

	# Filter if exist requsted layer
	if ($layerFilter) {

		my %tmp;
		@tmp{ @{$layerFilter} } = ();
		@layers = grep { exists $tmp{ $_->{"gROWname"} } } @allLayers;

	}
	else {
		@layers = @allLayers;
	}

	CamDrilling->AddNCLayerType( \@layers );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	# Add histogram and uni DTM

	foreach my $l (@layers) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"attHist"} = \%attHist;

		my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"symHist"} = \%symHist;

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			my $route = RouteFeatures->new();

			$route->Parse( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );
			my @f = $route->GetFeatures();
			$l->{"feats"} = \@f;

		}

		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1, 1 );

	}

	# 1) Check if tool parameters are set correctly
	unless ( $self->CheckToolParameters( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}
	else {

		# 2) Check if tool parameters are set correctly
		unless ( $self->CheckNonBoardLayers( $inCAM, $jobId, $mess ) ) {

			$result = 0;
		}

		# 1) Check floating point diameters
		unless ( $self->CheckFloatDiemeters( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

			$result = 0;
		}

		# 3) Check if all tools in job have correct size
		unless ( $self->CheckToolDiameter( $inCAM, \@layers, $mess ) ) {

			$result = 0;
		}
	}

	return $result;

}

# Check if tools are unique within while layer, check if all necessary parameters are set
sub CheckToolParameters {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };
	my $mess     = shift;

	my $result = 1;

	foreach my $l (@layers) {

		# if uniDTM check fail, dont do another control
		unless ( $l->{"uniDTM"}->CheckTools() ) {
			next;
		}

		# Check magazeine
		unless ( $l->{"uniDTM"}->GetChecks()->CheckMagazine($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}
 
	}

	# Check if some tools are same diameter as special tools and
	# theses tools has missing magazine info
	my @t = ();
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );

	my @layersST = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layersST) {
		unless ( $l->{"uniDTM"}->GetChecks()->CheckSpecialTools($mess) ) {
			$result = 0;
			$$mess .= "\n";
		}
	}

	return $result;
}

# Check if some layers are non board
sub CheckNonBoardLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $mess  = shift;

	my $result = 1;

	my @layers = CamJob->GetAllLayers( $inCAM, $jobId );
	CamDrilling->AddNCLayerType( \@layers );

	# search for layer which has defined "type" but is not board

	my @nonBoard = grep { defined $_->{"type"} && $_->{"gROWcontext"} ne "board" } @layers;
	@nonBoard = grep { $_->{"gROWname"} !~ /_/ && $_->{"gROWname"} !~ /v\d/ } @nonBoard;

	if ( scalar(@nonBoard) ) {

		@nonBoard = map { "\"" . $_->{"gROWname"} . "\"" } @nonBoard;
		my $str = join( "; ", @nonBoard );

		$result = 0;
		$$mess .= "Matrix contains rout/drill layers, which are not board ($str). Is it ok? \n";

	}

	return $result;
}

# Check if diameters are integer numbers, not float.
# Only layer LAYERTYPE_plt_nMill, because holes with various diameters are inserted automatically into this layer
#  (during final route creation eg)
sub CheckFloatDiemeters {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $step   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		my @tools = $l->{"uniDTM"}->GetTools();

		my @floatDim = map { $_->GetDrillSize() . "Âµm" } grep { $_->GetDrillSize() =~ /^\w\d+\.\d+$/ } @tools;
		@floatDim = uniq(@floatDim);

		if ( scalar(@floatDim) ) {

			my $str = join( ", ", @floatDim );

			$result = 0;
			$$mess .= "Layer \"" . $l->{"gROWname"} . "\" contains tools, where drill diameters contain decimal point: $str. Is it ok? \n";
		}
	}

	return $result;

}

# Check if all tools in job are available in our CNC department (drill_size.tab, rout_size.tab )
sub CheckToolDiameter {
	my $self   = shift;
	my $inCAM  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	# check drill layers

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrillBot );

	my @layersDrill = $self->__GetLayersByType( \@layers, \@t );

	my @t2 = ();

	push( @t2, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t2, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_kMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_nMillBot );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_lsMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_cvrlycMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_cvrlysMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_prepregMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_stiffcMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_stiffsMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_soldcMill );
	push( @t2,  EnumsGeneral->LAYERTYPE_nplt_soldsMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bstiffsMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_tapecMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_tapesMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_tapebrMill );
	
	
	 
	

	my @layersRout = $self->__GetLayersByType( \@layers, \@t2 );

	# 1) check drill layers on max available drill tool
	my @drillTool = CamDTM->GetToolTable( $inCAM, 'drill' );
	my $maxDrillTool = max(@drillTool) * 1000;    # in µm

	foreach my $l (@layersDrill) {

		my @maxLTools = map { $_->GetDrillSize() } grep { !$_->GetSpecial() && $_->GetDrillSize() > $maxDrillTool } $l->{"uniDTM"}->GetTools();

		if ( scalar(@maxLTools) ) {

			$result = 0;
			$$mess .=
			    "NC layer: "
			  . $l->{"gROWname"}
			  . " contains drill tool ("
			  . join( ";", @maxLTools )
			  . "µm) larger than our max tool ($maxDrillTool µm)\n";
		}
	}

	# 2) check rout layers on max available drill tool
	my @routTool = CamDTM->GetToolTable( $inCAM, 'rout' );
	my $maxRoutTool = max(@routTool) * 1000;    # in µm

	foreach my $l (@layersRout) {

		my @maxLDrillTools =
		  grep { !$_->GetSpecial() && $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE && $_->GetDrillSize() > $maxDrillTool }
		  $l->{"uniDTM"}->GetTools();

		if ( scalar(@maxLDrillTools) ) {

			$result = 0;
			$$mess .=
			    "NC layer: "
			  . $l->{"gROWname"}
			  . " contains drill tool ("
			  . join( ";", map { $_->GetDrillSize() } @maxLDrillTools )
			  . "µm) larger than our max tool ($maxDrillTool µm)\n";
		}

		my @maxLRoutTools =
		  grep { !$_->GetSpecial() && $_->GetTypeProcess() eq EnumsDrill->TypeProc_CHAIN && $_->GetDrillSize() > $maxRoutTool }
		  $l->{"uniDTM"}->GetTools();

		if ( scalar(@maxLRoutTools) ) {

			$result = 0;
			$$mess .=
			    "NC layer: "
			  . $l->{"gROWname"}
			  . " contains rout tool ("
			  . join( ";", map { $_->GetDrillSize() } @maxLRoutTools )
			  . "µm) larger than our max tool ($maxRoutTool µm)\n";
		}
	}

	# 3) Chek drill tools againts CNC available tools
	foreach my $l (@layersDrill) {

		foreach my $td ( map { $_->GetDrillSize() } grep { !$_->GetSpecial() } $l->{"uniDTM"}->GetTools() ) {

			unless ( grep { $_ * 1000 == $td } @drillTool ) {

				$result = 0;
				$$mess .= "NC layer: " . $l->{"gROWname"} . " contains drill tool: $td µm which is not available in CNC department\n";
			}
		}
	}

	# 4) Chek rout tools againts CNC available tools
	foreach my $l (@layersRout) {

		foreach my $t ( grep { !$_->GetSpecial() } $l->{"uniDTM"}->GetTools() ) {

			if ( $t->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE ) {
				unless ( grep { $_ * 1000 == $t->GetDrillSize() } @drillTool ) {

					$result = 0;
					$$mess .=
					    "NC layer: "
					  . $l->{"gROWname"}
					  . " contains drill tool: "
					  . $t->GetDrillSize()
					  . " µm which is not available in CNC department\n";
				}
			}
			elsif ( $t->GetTypeProcess() eq EnumsDrill->TypeProc_CHAIN ) {
				unless ( grep { $_ * 1000 == $t->GetDrillSize() } @routTool ) {

					$result = 0;
					$$mess .=
					    "NC layer: "
					  . $l->{"gROWname"}
					  . " contains rout tool:"
					  . $t->GetDrillSize()
					  . " µm which is not available in CNC department\n";
				}
			}

		}
	}

	return $result;
}

sub __GetLayersByType {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my @t      = @{ shift(@_) };

	my @matchL = ();

	foreach my $l (@layers) {

		my $match = scalar( grep { $_ eq $l->{"type"} } @t );

		if ($match) {

			push( @matchL, $l );
		}

	}
	return @matchL;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerWarnInfo';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113608";

	my $mess = "";

	my $result = LayerWarnInfo->CheckNCLayers( $inCAM, $jobId, "panel", undef, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
