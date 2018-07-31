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

		my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
		$l->{"symHist"} = \%symHist;

		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			my $route = RouteFeatures->new();

			$route->Parse( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );
			my @f = $route->GetFeatures();
			$l->{"feats"} = \@f;

		}

		$l->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $stepName, $l->{"gROWname"}, 1 );

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

		# Check if rout doesn't contain tool size smaller than 500
		if ( $l->{"gROWlayer_type"} eq "rout" ) {

			my @unitTools = $l->{"uniDTM"}->GetTools();

			foreach my $t (@unitTools) {

				if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) {
					next;
				}

				if ( $t->GetDrillSize() < 500 ) {
					$result = 0;
					$$mess .= "NC layer \"" . $l->{"gROWname"} . "\".\n";
					$$mess .=
					    "Routing layers should not contain tools diamaeter smaller than 500µm. Layer contains tool diameter: "
					  . $t->GetDrillSize()
					  . "µm.\n";
				}
			}
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

		my @floatDim = map { $_->GetDrillSize() . "µm" } grep { $_->GetDrillSize() =~ /^\w\d+\.\d+$/ } @tools;
		@floatDim = uniq(@floatDim);

		if ( scalar(@floatDim) ) {

			my $str = join( ", ", @floatDim );

			$result = 0;
			$$mess .= "Layer \"" . $l->{"gROWname"} . "\" contains tools, where drill diameters contain decimal point: $str. Is it ok? \n";
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
	my $jobId = "f52456";

	my $mess = "";

	my $result = LayerWarnInfo->CheckNCLayers( $inCAM, $jobId, "panel", undef, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
