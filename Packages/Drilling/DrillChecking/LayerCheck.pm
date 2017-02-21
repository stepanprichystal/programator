#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with drilling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Drilling::DrillChecking::LayerCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

#use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
 
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
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

	unless ( $self->CheckIsNotEmpty( \@layers, $mess ) ) {

		$result = 0;
	}

	# 3) Check if layer not contain attribute nomenclature

	unless ( $self->CheckAttributes( \@layers, $mess ) ) {

		$result = 0;
	}

	# 4) Check if drill layers not contain invalid symbols..

	unless ( $self->CheckInvalidSymbols( \@layers, $mess ) ) {

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

	return $result;

}

sub CheckIsNotEmpty {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	foreach my $l (@layers) {

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

	my @t = ();

	push( @t, EnumsGeneral->LAYERTYPE_plt_nDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
	push( @t, EnumsGeneral->LAYERTYPE_plt_bDrillBot );
	push( @t, EnumsGeneral->LAYERTYPE_plt_cDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_dcDrill );
	push( @t, EnumsGeneral->LAYERTYPE_plt_fDrill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		if ( $l->{"fHist"}->{"surf"} > 0 || $l->{"fHist"}->{"arc"} > 0 || $l->{"fHist"}->{"line"} > 0 || $l->{"fHist"}->{"text"} > 0 ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains illegal symbol (surface, line, arc or text). Layer can contains only pads.\n";
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
	push( @t, EnumsGeneral->LAYERTYPE_nplt_lsMill );
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
			$$mess .= "Vrstva: $lName má špatně nastavený vrták v metrixu u vrtání jádra. Vrták musí mít vždy směr TOP-to-BOT.\n";

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

		unless ( $l->{"uniDTM"}->CheckTools($mess) ) {
			$result = 0;
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

	use aliased 'Packages::Drilling::DrillChecking::LayerCheck';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";

	my $result = LayerCheck->CheckNCLayers( $inCAM, $jobId, "o+1", undef, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
