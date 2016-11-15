#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with drilling
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Drilling::DrillChecking::LayerCheck;

#3th party library
use List::MoreUtils qw(uniq);

#local library

#use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';

#use aliased 'CamHelpers::CamHelper';
#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamToolDepth';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub CheckNCLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $mess  = shift;

	my $result = 1;

	# Get all layers
	my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );

	CamDrilling->AddNCLayerType( \@layers );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	# Add histogram

	foreach my $l (@layers) {

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, "panel", $l->{"gROWname"} );
		$l->{"fHist"} = \%fHist;

		my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, "panel", $l->{"gROWname"} );
		$l->{"attHist"} = \%attHist;
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

	# 4) check each NC layers bz type

	# Blind
	unless ( $self->CheckBlindDrill( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# standard drill
	unless ( $self->CheckDrill( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# core drill
	unless ( $self->CheckCoreDrill( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}

	# Depth rout plated/nplated
	unless ( $self->CheckBlindDrill( $inCAM, $jobId, \@layers, $mess ) ) {

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
			$$mess .= "NC layer: " . $l->{"gROWname"} . " is empty.\n";
		}
	}

	return $result;
}

sub CheckAttributes {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	foreach my $l (@layers) {

		if ( $l->{"attHist"}->{".nomenclature"} ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " contains attribut .nomenclature.\n";
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
			$$mess .= "NC layer: " . $l->{"gROWname"} . " has wrong name.\n";
		}
	}

	return $result;
}

sub CheckBlindDrill {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	@layers = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot } @layers;

	# 1) check right direction of drill

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {

			if ( $dir && $dir ne "top2bot" ) {
				$result = 0;
				$$mess .= "Layer $lName has wrong direction of drilling. Direction has to be: top2bot. \n";
			}

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {

			if ( $dir ne "bot2top" ) {
				$result = 0;
				$$mess .= "Layer $lName has wrong direction of drilling. . Direction has to be: bot2top. \n";
			}
		}
	}

	# 2) check start and end layer

	foreach my $l (@layers) {
		my $startL    = $l->{"gROWdrl_start"};
		my $endL      = $l->{"gROWdrl_end"};
		my $layerName = $l->{"gROWname"};

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {

			if ( $startL >= $endL ) {
				$result = 0;
				$$mess .= "Layer: $layerName, drilling start/end layer is wrong in matrix.\n";
			}

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {

			if ( $endL <= $StartL ) {
				$result = 0;
				$$mess .= "Layer: $layerName, drilling start/end layer is wrong in matrix.\n";
			}
		}
	}

	# 3) check if tool depth is set

	foreach my $l (@layers) {

		$self->__ToolDepthSet( $inCAM, $jobId, $l->{"gROWname"}, $mess );
	}
}

sub CheckDrill {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	@layers = grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill } @layers;

	foreach my $l (@layers) {

		# 1) check right direction of drill

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $dir && $dir ne "top2bot" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of routing. Direction has to be: top2bot. \n";
		}

		# 2) check start and end layer

		my $startL = $l->{"gROWdrl_start"};
		my $endL   = $l->{"gROWdrl_end"};

		# normal drill
		if ( $lName =~ /^m$/ ) {
			if ( $startL >= $endL ) {
				$result = 0;
				$$mess .= "Layer: $lName, drill start/end layer is wrong in matrix.\n";
			}
		}

		# blind - through drill
		elsif ( $lName =~ /^m\d+$/ ) {

			my $lCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

			if ( $startL >= $endL || $startL == 1 || $endL == $lCnt ) {
				$result = 0;
				$$mess .= "Layer: $lName, (blind-through drilling) start/end layer is wrong in matrix.\n";
			}
			
		}
		
		# core drill
		elsif ( $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {

			if ( abs($startL - $endL) != 1 ) {
				$result = 0;
				$$mess .= "Layer: $lName, start/end layer is wrong in matrix. Only core layer could be drilled.\n";
			}
		}
		
	}
	
	
	# check if there is no tool depth in layer blind-through
	foreach my $l (@layers) {
		
		my $lName = $l->{"gROWname"};
		
		if ( $lName =~ /^m\d+$/ ) {
			
			# there are tool depths
			if($self->__ToolDepthSet( $inCAM, $jobId, $l->{"gROWname"}, $mess )){
				
				
			}
			
			
		}
		
		
 
	}
	
	
	
}

sub CheckDepthRout {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $result = 1;

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
	} @layers;

	# 1) check right direction of drill

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bDrillTop ) {

			if ( $dir && $dir ne "top2bot" ) {
				$result = 0;
				$$mess .= "Layer $lName has wrong direction of routing. Direction has to be: top2bot. \n ";
			}

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bDrillBot ) {

			if ( $dir ne "bot2top" ) {
				$result = 0;
				$$mess .= "Layer $lName has wrong direction of routing. . Direction has to be: bot2top. \n ";
			}
		}
	}

	# 2) check start and end layer

	foreach my $l (@layers) {
		my $startL    = $l->{"gROWdrl_start"};
		my $endL      = $l->{"gROWdrl_end"};
		my $layerName = $l->{"gROWname"};

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bDrillTop ) {

			if ( $startL >= $endL ) {
				$result = 0;
				$$mess .= "Layer: $layerName, routing start/end layer is wrong in matrix.\n ";
			}

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot || $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bDrillBot ) {

			if ( $endL <= $StartL ) {
				$result = 0;
				$$mess .= "Layer: $layerName, routing start/end layer is wrong in matrix.\n ";
			}
		}
	}

	# 3) check if tool depth is set

	foreach my $l (@layers) {

		$self->__ToolDepthSet( $inCAM, $jobId, $l->{"gROWname"}, $mess );
	}
}

sub __ToolDepthSet {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $mess      = shift;

	my $stepName = "panel";

	my $result = 1;

	#get depths for all diameter
	my @toolDepths = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $layerName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$layerName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	# 1) Check if there are same tools
	my @uniq = uniq @toolSize;

	if ( scalar(@uniq) < scalar(@toolSize) ) {

		$result = 0;
		$$mess .= "Layer: $layerName, contain more tools with same tool-size. Tool size has to be unique in Drill tool table. \n ";
	}

	# 2) check if tool depth is set
	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = CamToolDepth->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );
		unless ($prepareOk) {

			$result = 0;
			$$mess .= "Layer: $layerName, depth is not valid/set for tool: $tSize mm.\n ";

		}
	}

	return $result;

}

# Function return max aspect ratio from all holes and their depths. For given layer
sub GetMaxAspectRatioByLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	#get depths for all diameter
	my @toolDepths = $self->GetToolDepths( $inCAM, $jobId, "panel", $layerName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$layerName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	my $aspectRatio;

	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];
		my $s     = $toolShape[$i];

		if ( $s ne 'hole' ) {
			next;
		}

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = $self->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );
		unless ($prepareOk) {
			next;
		}

		my $tmp = ( $tDepth * 1000 ) / $tSize;

		if ( !defined $aspectRatio || $tmp > $aspectRatio ) {

			$aspectRatio = $tmp;
		}

	}
	return $aspectRatio;
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

	my $result = LayerCheck->CheckNCLayers( $inCAM, $jobId, \$mess );

	print STDERR "Result is $result \n";

	print STDERR " $mess \n";

}

1;
