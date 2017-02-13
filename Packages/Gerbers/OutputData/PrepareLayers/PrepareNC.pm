
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::PrepareLayers::PrepareNC;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::OutputData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::OutputData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamToolDepth';

use aliased 'Packages::Gerbers::OutputData::PrepareLayers::PrepareNCDrawing';
use aliased 'Packages::Gerbers::OutputData::PrepareLayers::PrepareNCStandard';

use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Drilling::DrillChecking::LayerCheck';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';



#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"step"}       = shift;
	$self->{"layerList"}  = shift;
	$self->{"profileLim"} = shift;

	$self->{"prepareNCStandard"} =
	  PrepareNCStandard->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layerList"}, $self->{"profileLim"} );
	$self->{"prepareNCDrawing"} =
	  PrepareNCDrawing->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layerList"}, $self->{"profileLim"} );

	$self->{"plateThick"} = 100;    # value of plating in holes 100 µm

	return $self;
}

sub Prepare {
	my $self       = shift;
	my @layers     = @{ shift(@_) };
	my @childSteps = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# Set layer info for each NC layer and filter only NC board layer
	CamDrilling->AddNCLayerType( \@layers );
	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;
	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	# Load feature histogram histogram
	foreach my $l (@layers) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;

	}

	# 1) Check if all parameters are ok. Such as vysledne/vrtane, one surfae depth per layer, etc..
	$self->__CheckNCLayers( \@layers );

	# 2) Remove attributes chain from surface, resize if plated surface
	$self->__AdjustSurfaces( \@layers );

	# 3) If step is originally flattened with nested steps, use DTM type vzsledne/vratne form child
	# step, if is not set
	$self->__SetDTMType( \@layers, \@childSteps );

	# 3) Set all NC layers to finish sizes (consider type of DTM vysledne/vrtane)
	$self->__SetFinishSizes( \@layers );

	# 4) Load histograms about layer features and their attribues
	foreach my $l (@layers) {

		# a) feature attributes histogram
		my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step, $l->{"gROWname"} );
		$l->{"attHist"} = \%attHist;

		# b) symbol histogram - combine line and arcs conut (because we use same tool)
		my %sHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $l->{"gROWname"}, 1, 1 );

		my %line_arcs = ();
		foreach my $k ( keys %{ $sHist{"lines"} } ) {
			$line_arcs{$k} = 0;

			$line_arcs{$k} += $sHist{"lines"}->{$k} if ( defined $sHist{"lines"}->{$k} );
			$line_arcs{$k} += $sHist{"arcs"}->{$k}  if ( defined $sHist{"arcs"}->{$k} );
		}
		$sHist{"lines_arcs"} = \%line_arcs;
		$l->{"symHist"} = \%sHist;

	}

	# 5) Create layer data for NC layers
	$self->__PrepareLayers( \@layers );

}

sub __CheckNCLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $mess = "";

	my @layerNames = map { $_->{"gROWname"} } @layers;

	unless ( LayerCheck->CheckNCLayers( $inCAM, $jobId, $self->{"step"}, \@layerNames, \$mess ) ) {

		die "Can't prepare NC layers for output. NC layers contains error: $mess \n";
	}

}

# Remove attributes chain from surface, resize if plated surface
sub __AdjustSurfaces {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {

		if ( $l->{"fHist"}->{"surf"} > 0 && $l->{"plated"} ) {

			my $f = FeatureFilter->new( $inCAM, $l->{"gROWname"} );

			my @types = ("surface");
			$f->SetTypes( \@types );

			# delete rout chain attribute in order resize plated survaces
			if ( $f->Select() > 0 ) {

				CamAttributes->DelFeatuesAttribute( $inCAM, ".rout_chain", "" );
				
				if ( $f->Select() ) { 
					$inCAM->COM( "sel_resize", "size" => -$self->{"plateThick"} ); 
				}
			}

			CamLayer->ClearLayers($inCAM);
		}
	}
}

sub __SetDTMType {
	my $self       = shift;
	my @layers     = @{ shift(@_) };
	my @childSteps = @{ shift(@_) };

	unless ( scalar(@childSteps) ) {
		return 0;
	}

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {

		my $lName = $l->{"gROWname"};
		my $DTMType = CamDTM->GetDTMUToolsType( $inCAM, $jobId, $self->{"step"}, $lName );

		# if DTM type not set, find type in nested ste[s]
		if ( $DTMType ne "vrtane" && $DTMType ne "vysledne" ) {

			foreach my $s (@childSteps) {
				my $childDTMType = CamDTM->GetDTMUToolsType( $inCAM, $jobId, $s->{"stepName"}, $lName );
				if ( $childDTMType eq "vrtane" || $childDTMType eq "vysledne" ) {
					CamDTM->SetDTMTable( $inCAM, $jobId, $self->{"step"}, $lName, $childDTMType );
					last;
				}
			}
		}
	}
}

# Set all NC layers to finish sizes (consider type of DTM vysledne/vrtane)
sub __SetFinishSizes {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $l (@layers) {

		my $lName = $l->{"gROWname"};

		# Prepare tool table for drill map and final sizes of data (depand on column DSize in DTM)

		my @tools = CamDTM->GetDTMColumns( $inCAM, $jobId, $self->{"step"}, $lName );
		my $DTMType = CamDTM->GetDTMUToolsType( $inCAM, $jobId, $self->{"step"}, $lName );

		if ( $DTMType ne "vrtane" && $DTMType ne "vysledne" ) {
			die "Typ v Drill tool manageru (vysledne/vrtane) neni nastaven u vrstvy: '" . $lName . "' ";
		}

		# check if dest size are defined
		my @badSize = grep { !defined $_->{"gTOOLdrill_size"} || $_->{"gTOOLdrill_size"} == 0 || $_->{"gTOOLdrill_size"} eq "" } @tools;

		if (@badSize) {
			@badSize = map { $_->{"gTOOLfinish_size"} } @badSize;
			my $toolStr = join( ", ", @badSize );
			die "Tools: $toolStr, has not set drill size.\n";
		}

		# 1) If some tool has not finish size, correct it by putting there drill size (if vysledne resize -100µm)

		foreach my $t (@tools) {

			if ( !defined $t->{"gTOOLfinish_size"} || $t->{"gTOOLfinish_size"} == 0 || $t->{"gTOOLfinish_size"} eq "" ) {

				if ( $DTMType eq "vysledne" ) {

					$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"} - $self->{"plateThick"};    # 100µm - this is size of plating

				}
				elsif ( $DTMType eq "vrtane" ) {
					$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"};
				}

			}
		}

		# 2) Copy 'finish' value to 'drill size' value.
		# Drill size has to contain value of finih size, because all pads, lines has size depand on this column
		# And we want diameters size after plating

		foreach my $t (@tools) {

			if ( $DTMType eq "vrtane" && $l->{"plated"} ) {
				$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"} - $self->{"plateThick"};
			}
			else {
				$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"};
			}
		}

		# 3) Set new values to DTM
		CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName, \@tools );

		# 4) If some tools same, merge it
		$inCAM->COM( "tools_merge", "layer" => $lName );

	}
}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	$self->{"prepareNCStandard"}->Prepare( $layers, Enums->Type_NCLAYERS );
	$self->{"prepareNCDrawing"}->Prepare( $layers, Enums->Type_NCLAYERS );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
