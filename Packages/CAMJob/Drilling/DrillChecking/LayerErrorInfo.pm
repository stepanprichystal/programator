package Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo;

#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for checking drilling errors
# when some errors occur, NC export is not possible
# Author:SPR
#-------------------------------------------------------------------------------------------#

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

	# 1) Check if layer names are set correctly, if no don't no continue in other checks

	unless ( $self->CheckWrongNames( \@layers, $mess ) ) {

		$result = 0;
		return $result;
	}

	# Add histogram and uni DTM which is needet to advanced checking

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

	# 2) Check if tool parameters are set correctly,if not don't continue in other checks
	unless ( $self->CheckToolParameters( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
		return $result;
	}

	# 3) Check if layer is not empty

	unless ( $self->CheckIsNotEmpty( \@layers, $stepName, $mess ) ) {

		$result = 0;
	}

	# 4) Check if layer not contain attribute nomenclature

	unless ( $self->CheckAttributes( \@layers, $mess ) ) {

		$result = 0;
	}

	# 5) Check if drill layers not contain invalid symbols..

	unless ( $self->CheckInvalidSymbols( \@layers, $mess ) ) {

		$result = 0;
	}

	# 6) Check if layer has to set right direction

	unless ( $self->CheckDirTop2Bot( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# 7) Check if layer has to set right direction

	unless ( $self->CheckDirBot2Top( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# 8) Check if layer has to set right direction

	unless ( $self->CheckDrillStartStop( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# 8) Check if depth is correctly set
	unless ( $self->CheckContainDepth( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

		$result = 0;
	}

	# 9) Check if depth is not set
	unless ( $self->CheckContainNoDepth( $inCAM, $jobId, $stepName, \@layers, $mess ) ) {

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

	# remove core frame drilling generated before export (theses layers are empty for quicker creation)
	@layers = grep { $_->{"gROWname"} !~ /v1j\d+/ } @layers;

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
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains attribut .nomenclature. Please remove it.\n";
		}

		if ( $l->{"attHist"}->{".out_nc_ignore"} ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains attribut .out_nc_ignore. Please remove it.\n";
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
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldsMill );

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
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fcDrill );
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
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_rsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_frMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cvrlycMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_prepregMill );

	my @layers1 = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers1) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		# not def means top2bot
		if ( $dir && $dir eq "bot2top" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction must be: TOP-to-BOT. \n";
		}

		my $startL = $l->{"NCSigStartOrder"};
		my $endL   = $l->{"NCSigEndOrder"};

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill || $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill ) {

			# core drilling has to go though 2 layers only
			if ( $endL - $startL != 1 ) {
				$result = 0;
				$$mess .=
				    "Vrstva: $lName, má špatně nastavený vrták v metrixu u vrtání jádra. "
				  . "Vrták nesmí začínat a končit na stejné vrstvě"
				  . " a musí být natažený na signálových vrstvách jádra. \n";
			}

		}

	}

	# Check for blind layer from top, if not end in S layer
	my @layers2 = $self->__GetLayersByType( \@layers, [ EnumsGeneral->LAYERTYPE_plt_bDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop ] );

	foreach my $l (@layers2) {

		my $lName = $l->{"gROWname"};

		if ( $l->{"NCSigEnd"} eq "s" ) {
			$result = 0;
			$$mess .= "Blind layer: $lName, can not end in matrix in layer: \"s\"\n";
		}
	}

	# Check plated through blind layer if start and end not in c/s layer
	my @layers4 = grep { $_->{"gROWname"} =~ /\d/ } $self->__GetLayersByType( \@layers, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );

	foreach my $l (@layers4) {

		my $lName = $l->{"gROWname"};

		if ( $l->{"NCSigStart"} eq "c" ) {
			$result = 0;
			$$mess .= "Blind through plated NC layer \"" . $lName . "\" can not to start in layer \"c\"\n";
		}

		if ( $l->{"NCSigEnd"} eq "s" ) {
			$result = 0;
			$$mess .= "Blind through plated NC layer \"" . $lName . "\" can not to end in layer \"s\"\n";
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldsMill );

	my @layers1 = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers1) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $dir ne "bot2top" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction must be: BOT-to-TOP. \n";
		}

		my $startL = $l->{"NCSigStartOrder"};
		my $endL   = $l->{"NCSigEndOrder"};

		# check for core driling, if doesn wrong direction

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill && $dir && $dir eq "bot2top" ) {

			$result = 0;
			$$mess .= "Vrstva: $lName má špatně nastavený vrták v metrixu u vrtání jádra. Vrták musí mít vždy směr TOP-to-BOT.\n";

		}
	}

	# Check for blind layer from top, if not end in C layer
	my @layers2 = $self->__GetLayersByType( \@layers, [ EnumsGeneral->LAYERTYPE_plt_bDrillBot, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot ] );

	foreach my $l (@layers2) {

		my $lName = $l->{"gROWname"};

		if ( $l->{"NCSigEnd"} eq "c" ) {
			$result = 0;
			$$mess .= "Blind layer: $lName, can not end in matrix in layer: \"c\"\n";
		}
	}

	# Check for filled layers from bot, if start in last layer
	my @layers3 = $self->__GetLayersByType( \@layers, [ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot ] );

	foreach my $l (@layers3) {

		my $lName = $l->{"gROWname"};

		if ( $l->{"NCSigStart"} ne "s" ) {
			$result = 0;
			$$mess .= "Filled blind layer from bot: $lName, has to start in layer \"s\" (now start in: " . $l->{"NCSigStart"} . ")\n";
		}
	}

	return $result;
}

sub CheckDrillStartStop {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	# 1) This helper drill shouldn't go through signal layers
	my @t = ();
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_stiffsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldcMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_soldsMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cvrlycMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_prepregMill );

	my @layers1 = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers1) {

		my $lName = $l->{"gROWname"};

		# not def means top2bot
		if ( $l->{"NCThroughSig"} ) {
			$result = 0;
			$$mess .= "Layer $lName can't start or stop or go through signal layers in matrix.\n";
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
			next;

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
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	# 1) Check if layers contain depth in DTM table
	foreach my $l (@layers) {

		unless ( $l->{"uniDTM"}->GetChecks()->CheckToolDepthSet($mess) ) {
			$result = 0;
		}
	}

	# 2) Check if layer start/stop/go through signal layer
	foreach my $l (@layers) {

		unless ( $l->{"NCThroughSig"} ) {

			$result = 0;
			$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
			$$mess .= "Thist type of NC layer has to START or END or GO THROUGH at least one signal layer.\n";
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_nMill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fcDrill );
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fcDrill );
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
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );
	push( @t2, EnumsGeneral->LAYERTYPE_nplt_nMill );

	# check all nc layers on wrong shaped pads. Pads has to by only r<number>

	my @layersAll = $self->__GetLayersByType( \@layers, [ @t, @t2 ] );

	# check all nc layers on max available drill tool
	my @tool    = CamDTM->GetToolTable( $inCAM, 'drill' );
	my $maxTool = max(@tool) * 1000;                         # in µm
	my $minTool = min(@tool) * 1000;                         # in µm

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

# Check if drill size is greater than finish size
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
	push( @t, EnumsGeneral->LAYERTYPE_plt_nFillDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cFillDrill );
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
		@tools = grep { defined $_->GetFinishSize() && ( $_->GetFinishSize() - 100 ) > $_->GetDrillSize() } @tools;

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

	use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d272450";

	my $mess = "";

	my $result = LayerErrorInfo->CheckNCLayers( $inCAM, $jobId, "panel", undef, \$mess );

	#	my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	#	my $result = 1;
	#
	#	CamDrilling->AddNCLayerType( \@layers );
	#	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );
	#	$result = 0 if ( !LayerErrorInfo->CheckWrongNames( \@layers, \$mess ) );
	#	$result = 0 if ( $result && !LayerErrorInfo->CheckDirBot2Top( $inCAM, $jobId, \@layers, \$mess ) );
	#	$result = 0 if ( $result && !LayerErrorInfo->CheckDirTop2Bot( $inCAM, $jobId, \@layers, \$mess ) );
	#
	#	unless ($result) {
	#		print STDERR " $mess \n";
	#	}

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
