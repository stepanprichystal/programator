#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for checking drilling errors
# when some errors occur, NC export is not possible
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::DrillChecking::LayerCheckError;

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
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::CAM::UniDTM::UniDTM';

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

		my %sHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"symHist"} = \%sHist;

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			my $route = RouteFeatures->new();

			$route->Parse( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );
			my @f = $route->GetFeatures();
			$l->{"feats"} = \@f;

		}

		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );

	}

	# 1) Check if some layer has wronng name

	unless ( $self->CheckWrongNames( \@layers, $mess ) ) {

		$result = 0;
	}

	# 2) Check if layer is not empty

	unless ( $self->CheckIsNotEmpty( \@layers, $stepName, $mess ) ) {

		$result = 0;
	}

	# 3) Check if layer not contain attribute nomenclature

	unless ( $self->CheckAttributes( \@layers, $mess ) ) {

		$result = 0;
	}

	# 4) Check if drill layers not contain invalid symbols..

	unless ( $self->CheckInvalidSymbols(\@layers, $mess ) ) {

		$result = 0;
	}

	# 4) Check if layer has to set right direction

	unless ( $self->CheckDirTop2Bot( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# 5) Check if layer has to set right direction

	unless ( $self->CheckDirBot2Top( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# 6) Check if tool parameters are set correctly
	unless ( $self->CheckToolParameters( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}

	# 7) Check if depth is correctly set
	unless ( $self->CheckContainDepth( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}

	# 8) Check if depth is not set
	unless ( $self->CheckContainNoDepth( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}
	
	# 9) Check if all tools in job have correct size
	unless ( $self->CheckToolDiameter( $inCAM, \@layers, $mess ) ) {

		$result = 0;
	}
	

	# 10) Checkdifference between drill and finish diameter
	unless ( $self->CheckDiamterDiff( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}

	return $result;

}

sub CheckIsNotEmpty {
	my $self     = shift;
	my @layers   = @{ shift(@_) };
	my $stepName = shift;
	my $mess     = shift;

	my $result = 1;

	foreach my $l (@layers) {

		# if panel is not step, NC layer can be empty
		if ( $stepName ne "panel" && defined $l->{"type"} ) {
			next;
		}

		if ( $l->{"fHist"}->{"total"} == 0 ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " is empty (doesn't contain any symbols).\n";
		}
	}

	return $result;
}

sub CheckAttributes {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	# 1) Check if symbols doesn't contain attribute layers
	foreach my $l (@layers) {

		if ( $l->{"attHist"}->{".nomenclature"} ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains attribut .nomenclature. Please remove them.\n";
		}
	}

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	# 2) Check if rout layers has attribute rout chain
	foreach my $l (@layers) {

		# filter pads
		my @sym = grep { $_->{"type"} ne "P" } @{ $l->{"feats"} };

		my @symRoutLess = grep { !defined $_->{"att"}->{".rout_chain"} } @sym;

		if ( scalar(@symRoutLess) > 0 ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . ", => some symbols don't have assigned rout (attribute .rout_chain).\n";
		}
	}

	return $result;
}

# Check if drill layers not contain invalid symbols..
# drilling can contain onlz pads
sub CheckInvalidSymbols {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	# check drill layers

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrill );

	my @layersDrill = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layersDrill) {

		if ( $l->{"fHist"}->{"surf"} > 0 || $l->{"fHist"}->{"arc"} > 0 || $l->{"fHist"}->{"line"} > 0 || $l->{"fHist"}->{"text"} > 0 ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains illegal symbol (surface, line, arc or text). Layer can contains only pads.\n";
		}
	}

	# check rout layers

	my @t2 = ();

	push( @t2, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t2, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_kMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_jbMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_jbMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_nMill );

	# check all nc layers on wrong shaped pads. Pads has to by only r<number>

	my @layersAll = $self->__GetLayersByType( \@layers, [ @t, @t2 ] );

	foreach my $l (@layersAll) {

		my @wrongPads = grep { $_->{"sym"} !~ /^r/i } @{ $l->{"symHist"}->{"pads"} };

		if ( scalar(@wrongPads) ) {

			$result = 0;
			$$mess .=
			  "NC layer: " . $l->{"gROWname"} . " contains illegal symbol pad shapes: " . join( ";", map { $_->{"sym"} } @wrongPads ) . " .\n";
		}
	}

	 

	return $result;
}

sub CheckWrongNames {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	foreach my $l (@layers) {

		unless ( $l->{"type"} ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " has wrong name. This is not standard NC layer name. Repair it.\n";
		}
	}

	return $result;
}

sub CheckDirTop2Bot {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		# not def means top2bot
		if ( $dir && $dir eq "bot2top" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction must be: TOP-to-BOT. \n";
		}

		my $startL = $l->{"gROWdrl_start"};
		my $endL   = $l->{"gROWdrl_end"};

		if ( $startL >= $endL ) {

			# check for core driling, which start/end in same layer

			if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {

				if ( $startL == $endL ) {
					$result = 0;
					$$mess .=
"Vrstva: $lName, má špatně nastavený vrták v metrixu u vrtání jádra. Vrták nesmí začínat a končit na stejné vrstvě.\n";
				}

			}
		}

	}

	return $result;

}

sub CheckDirBot2Top {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $dir ne "bot2top" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction must be: BOT-to-TOP. \n";
		}

		my $startL = $l->{"gROWdrl_start"};
		my $endL   = $l->{"gROWdrl_end"};

		# check for core driling, if doesn wrong direction

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill && $dir && $dir eq "bot2top" ) {

			$result = 0;
			$$mess .=
"Vrstva: $lName má špatně nastavený vrták v metrixu u vrtání jádra. Vrták musí mít vždy směr TOP-to-BOT.\n";

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

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	foreach my $l (@layers) {

		# 1) Check if tools are unique within while layer, check if all necessary parameters are set
		unless ( $l->{"uniDTM"}->CheckTools($mess) ) {
			$result = 0;

		}

		# 2) Check if DTM type is set (vrtane/vzsledne)
		my $DTMType = CamDTM->GetDTMDefaultType( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );

		if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {
			$result = 0;
			$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
			$$mess .= "Layer, which contains plated routing/drilling must have set DTM type \"vrtane\" or \"vysledne\" at least in nested steps.\n";
		}

		# 3) If "neplat/1 side pcb" check if DTM type is "vrtane"
		if ( $layerCnt < 2 ) {

			if ( $DTMType eq EnumsDrill->DTM_VYSLEDNE ) {
				$result = 0;
				$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
				$$mess .= "Pcb which is NOT plated has to set Drill Tool Manager type: \"vrtane\" not type: \"vysledne\". \n";
			}
		}

	}

	return $result;
}

sub CheckContainDepth {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };
	my $mess     = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_jbMillBot );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthSet($mess) ) {
			$result = 0;
		}
	}

	return $result;
}

sub CheckContainNoDepth {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };
	my $mess     = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthNotSet($mess) ) {
			$result = 0;
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrill );

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
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_jbMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_jbMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_nMill );

	# check all nc layers on wrong shaped pads. Pads has to by only r<number>

	my @layersAll = $self->__GetLayersByType( \@layers, [ @t, @t2 ] );
 

	# check all nc layers on max available drill tool
	my @tool    = CamDTM->GetToolTable( $inCAM, 'drill' );
	my $maxTool = max(@tool)*1000; # in �m
	my $minTool = min(@tool)*1000; # in �m

	foreach my $l (@layersAll) {

		my @maxTools = grep { ( $_->{"sym"} =~ m/^r(\d+\.?\d*)$/ )[0] > $maxTool } @{ $l->{"symHist"}->{"pads"} };

		if ( scalar(@maxTools) ) {

			$result = 0;
			$$mess .=
			    "NC layer: "
			  . $l->{"gROWname"}
			  . " contains drilled holes ("
			  . join( ";", map { $_->{"sym"} } @maxTools )
			  . ") larger than our max tool ($maxTool mm)\n";
		}

#		my @minTools = grep { ( $_->{"sym"} =~ m/^r(\d+\.?\d*)$/ )[0] < $minTool } @{ $l->{"symHist"}->{"pads"} };
#
#		if ( scalar(@minTools) ) {
#
#			$result = 0;
#			$$mess .=
#			    "NC layer: "
#			  . $l->{"gROWname"}
#			  . " contains drilled holes ("
#			  . join( ";", map { $_->{"sym"} } @minTools )
#			  . ") smaller than our min tool ($minTool mm)\n";
#		}

	}

	return $result;
}


# Check if tools are unique within while layer, check if all necessary parameters are set
sub CheckDiamterDiff {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };
	my $mess     = shift;

	my $result = 1;

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		my @tools = grep { $_->GetSource() eq Enums->Source_DTM } $l->{"uniDTM"}->GetTools();
		@tools = grep { ( $_->GetFinishSize() - 100 ) > $_->GetDrillSize() } @tools;

		if ( scalar(@tools) ) {

			@tools = map { "DrillSize " . $_->GetDrillSize() . "µm < FinishSize " . $_->GetFinishSize() . "µm" } @tools;
			my $str = join( "; ", @tools );
			$result = 0;
			$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
			$$mess .= "\"Drill size\" diameters must be greater than \"Finish size\" diameters. Problem tools: $str \n";

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

	use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerCheckError';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $mess = "";

	my $result = LayerCheckError->CheckNCLayers( $inCAM, $jobId, "panel", undef, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
