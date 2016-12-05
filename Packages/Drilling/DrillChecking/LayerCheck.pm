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

	# 4) Check if layer has to set right direction

	unless ( $self->CheckDirTop2Bot( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}
 
	# 5) Check if layer has to set right direction

	unless ( $self->CheckDirBot2Top( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}
 

	# 6) Check if depth is correctly set
	unless ( $self->CheckContainDepth( $inCAM, $jobId, \@layers, $mess ) ) {

		$result = 0;
	}
		
	# 7) Check if depth is not set
	unless ( $self->CheckContainNoDepth( $inCAM, $jobId, \@layers, $mess ) ) {

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

# TODO check on missing rout attribute

# Check if drill layers not contain invalid symbols..
sub CheckInvalidSymbols {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
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
	

	@layers = $self->__GetLayersByType( \@layers, \@t  );

	foreach my $l (@layers) {

		if ( $l->{"fHist"}->{"total"} == 0 ) {
			$result = 0;
			$$mess .= "NC layer: " . $l->{"gROWname"} . " is empty.\n";
		}
	}

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
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );

	@layers = $self->__GetLayersByType( \@layers, \@t  );

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		# not def means top2bot
		if ( $dir && $dir eq "bot2top") {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction has to be: top2bot. \n";
		}

		my $startL = $l->{"gROWdrl_start"};
		my $endL   = $l->{"gROWdrl_end"};

		if ( $startL >= $endL ) {

			#exception for core driling, which start/end in same layer

			if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill && $startL == $endL ) {
				next;
			}

			if ( abs( $startL - $endL ) != 1 ) {
				$result = 0;
				$$mess .= "Layer: $lName, start/end layer is wrong in matrix. Only core layer could be drilled.\n";
			}
		}

	}

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

	@layers = $self->__GetLayersByType( \@layers, \@t  );

	foreach my $l (@layers) {

		my $dir   = $l->{"gROWdrl_dir"};
		my $lName = $l->{"gROWname"};

		if ( $dir ne "bot2top" ) {
			$result = 0;
			$$mess .= "Layer $lName has wrong direction of drilling/routing. Direction has to be: bot2top. \n";
		}

		my $startL = $l->{"gROWdrl_start"};
		my $endL   = $l->{"gROWdrl_end"};

		unless( defined $endL || defined  $StartL){
			print STDERR "dddd";
		}

		if ( $endL <= $startL ) {
			$result = 0;
			$$mess .= "Layer: $layerName, drilling start/end is wrong in matrix. Drilling/routing cant't start and end in same layer.\n";
		}
	}
}

sub CheckContainDepth {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

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
	
	@layers = $self->__GetLayersByType( \@layers, \@t  );

	foreach my $l (@layers) {

		$self->__ToolDepthSet( $inCAM, $jobId, $l->{"gROWname"}, $mess );
	}
}

sub CheckContainNoDepth {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

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
	push( @t, EnumsGeneral->LAYERTYPE_nplt_kMill );

	@layers = $self->__GetLayersByType( \@layers, \@t );

	foreach my $l (@layers) {

		$self->__ToolDepthNotSet( $inCAM, $jobId, $l->{"gROWname"}, $mess );
	}
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

sub __ToolDepthNotSet {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $mess      = shift;

	my $stepName = "panel";

	my $result = 1;

	#get depths for all diameter
	my @toolDepths = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $layerName );

	foreach my $d (@toolDepths) {

		if ( defined $d->{"depth"} ) {

			my $t = $d->{"drill_size"};

			$result = 0;
			$$mess .= "Layer: $layerName, has defined tool depth for tool: $t mm. This layer can't contain depths.\n ";
		}
	}

	return $result;
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
