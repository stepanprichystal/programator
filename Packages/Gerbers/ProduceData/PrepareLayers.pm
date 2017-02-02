
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::OutputPrepare;

#3th party library
use threads;
use strict;
use warnings;
use PDF::API2;
use List::Util qw[max min];
use Math::Trig;
use Image::Size;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::ProduceData::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamToolDepth';

#use aliased 'CamHelpers::CamFilter';
#use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamSymbol';

#use aliased 'Packages::SystemCall::SystemCall';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"layerList"} = shift;

	$self->{"profileLim"} = undef;    # limits of pdf step

	return $self;
}

sub PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	# get limits of step
	my %lim = CamJob->GetProfileLimits2( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, 1 );
	$self->{"profileLim"} = \%lim;

	# prepare layers
	$self->__PrepareLayers($layers);

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	$self->__PrepareBASEBOARD( $layers, Enums->Type_BOARDLAYERS );
	$self->__PrepareNCDRILL( $layers, Enums->Type_NCLAYERS );
	$self->__PrepareNCMILL( $layers, Enums->Type_NCLAYERS );
	$self->__PrepareNCDEPTHMILL( $layers, Enums->Type_NCLAYERS );
	$self->__PrepareOUTLINE( $layers, Enums->Type_OUTLINE );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareBASEBOARD {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $l->{"gROWname"} );

		$self->{"layerList"}->AddLayer($lData);
	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDRILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;
	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot

	} @layers;

	foreach my $l (@layers) {

		my $tit   = ValueConvertor->GetJobLayerTitle($l);
		my $inf   = ValueConvertor->GetJobLayerInfo($l);
		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 "copy_layer",
					 "source_job"   => $jobId,
					 "source_step"  => $self->{"step"},
					 "source_layer" => $l->{"gROWname"},
					 "dest"         => "layer_name",
					 "dest_step"    => $self->{"step"},
					 "dest_layer"   => $lName,
					 "mode"         => "append"
		);

		$self->__ComputeNewDTMTools( $lName, $l->{"plated"} );

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);

	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# Scoring single + plated mill single

	my @layersSingle =
	  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score } @layers;

	foreach my $l (@layersSingle) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 "copy_layer",
					 "source_job"   => $jobId,
					 "source_step"  => $self->{"step"},
					 "source_layer" => $l->{"gROWname"},
					 "dest"         => "layer_name",
					 "dest_step"    => $self->{"step"},
					 "dest_layer"   => $lName,
					 "mode"         => "append"
		);

		$self->__ComputeNewDTMTools( $lName, $l->{"plated"} );

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

	# Merge: mill, rs, k mill layers

	my @layersMill = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill
	} @layers;

	if ( scalar(@layersMill) ) {

		my $lName = GeneralHelper->GetGUID();

		my $f = ( grep { $_->{"gROWname"} eq "f" } @layers )[0];

		my $tit = ValueConvertor->GetJobLayerTitle($f);
		my $inf = ValueConvertor->GetJobLayerInfo($f);

		foreach my $l (@layersMill) {

			$inCAM->COM(
						 "copy_layer",
						 "source_job"   => $jobId,
						 "source_step"  => $self->{"step"},
						 "source_layer" => $l->{"gROWname"},
						 "dest"         => "layer_name",
						 "dest_step"    => $self->{"step"},
						 "dest_layer"   => $lName,
						 "mode"         => "append"
			);

		}

		$self->__ComputeNewDTMTools( $lName, $f->{"plated"} );
		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($f), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

# Create layer and fill profile - simulate pcb material
sub __PrepareNCDEPTHMILL {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	@layers = grep { $_->{"type"} && $_->{"gROWcontext"} eq "board" } @layers;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# all depth nc layers

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		my $tit = ValueConvertor->GetJobLayerTitle($l);
		my $inf = ValueConvertor->GetJobLayerInfo($l);

		my $lName = GeneralHelper->GetGUID();

		$inCAM->COM(
					 "copy_layer",
					 "source_job"   => $jobId,
					 "source_step"  => $self->{"step"},
					 "source_layer" => $l->{"gROWname"},
					 "dest"         => "layer_name",
					 "dest_step"    => $self->{"step"},
					 "dest_layer"   => $lName,
					 "mode"         => "append"
		);

		$self->__ComputeNewDTMTools( $lName, $l->{"plated"} );

		# add table with depth information
		$self->__InsertDepthTable($lName);

		my $lData = LayerData->new( $type, ValueConvertor->GetFileNameByLayer($l), $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

}

sub __PrepareOUTLINE {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lName );

	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "200" );

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	foreach my $l (@layers) {

		my $tit = "Outline layer";
		my $inf = "";

		my $lData = LayerData->new( $type, "dim", $tit, $inf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

sub __ComputeNewDTMTools {
	my $self   = shift;
	my $lName  = shift;
	my $plated = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

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

				$t->{"gTOOLfinish_size"} = $t->{"gTOOLdrill_size"} - 100;    # 100µm - this is size of plating

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

		if ( $DTMType eq "vrtane" && $plated ) {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"} - 100;
		}
		else {
			$t->{"gTOOLdrill_size"} = $t->{"gTOOLfinish_size"};
		}
	}

	# 3) Set new values to DTM
	CamDTM->SetDTMTools( $inCAM, $jobId, $self->{"step"}, $lName, \@tools );

	# 4) Adjust surfaces in layer. All must be -100µm
	CamLayer->WorkLayer( $inCAM, $lName );

	# 5) Resize all surfaces -100

	if ($plated) {

		my @types = ("surface");
		if ( CamFilter->ByTypes( $inCAM, \@types ) > 0 ) {

			my $lNameSurf     = GeneralHelper->GetGUID();
			my $lNameSurfComp = GeneralHelper->GetGUID();

			$inCAM->COM(
						 "sel_move_other",
						 "target_layer" => $lNameSurf,
						 "invert"       => "no",
						 "dx"           => "0",
						 "dy"           => "0",
						 "size"         => "0",
						 "x_anchor"     => "0",
						 "y_anchor"     => "0"
			);

			CamLayer->WorkLayer( $inCAM, $lNameSurf );
			RoutCompensation( $inCAM, $lNameSurfComp, 'document' );

			CamLayer->WorkLayer( $inCAM, $lNameSurfComp );
			$inCAM->COM( "sel_resize", "size" => -100 );
			$inCAM->COM(
				"sel_copy_other",
				"dest"         => "layer_name",
				"target_layer" => $lName,
				"invert"       => "no"

			);
			$inCAM->COM( "delete_layer", "layer" => $lNameSurf );
			$inCAM->COM( "delete_layer", "layer" => $lNameSurfComp );

			CamLayer->WorkLayer( $inCAM, $lName );
		}
	}

}

sub __GetDepthTable {
	my $self  = shift;
	my $lName = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $stepName = $self->{"step"};

	my @rows = ();    # table row

	# 1) get depths for all diameter
	my @toolDepths = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $lName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$lName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	# 2) check if tool depth is set
	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = CamToolDepth->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );

		unless ($prepareOk) {

			die "$tSize doesn't has set deep of milling/drilling.\n";
		}

		# TODO - az bude sprovoznene pridavani flagu na specialni nastroje, tak dodelat
		# pak to pro nastroj 6.5 vrati 90stupnu atp
		my $tInfo = "";

		my @row = ();

		push( @row, ( sprintf( "%0.2f", $tSize / 1000 ), sprintf( "%0.2f", $tDepth ), $tInfo ) );

		push( @rows, \@row );
	}

	return @rows;
}

sub __InsertDepthTable {
	my $self  = shift;
	my $lname = shift;

	my $inCAM = $self->{"inCAM"};

	my @rows = $self->__GetDepthTable($lname);
	unless (@rows) {
		return 0;
	}

	CamLayer->WorkLayer( $inCAM, $lname );

	my $tabPosY = abs( $self->{"profileLim"}->{"yMax"} - $self->{"profileLim"}->{"yMin"} ) + 20;
	my $tabPosX = 0;
	my %pos     = ( "x" => $tabPosX, "y" => $tabPosY );

	my @colWidths = ( 70, 60, 60 );

	my @row1 = ( "Tool [mm]", "Depth [mm]", "Tool info" );
	@rows = ( \@row1, @rows );

	CamSymbol->AddTable( $inCAM, \%pos, \@colWidths, 10, 5, 2, \@rows );

	my $tableHeight = scalar(@rows) * 10;
	my %posTitl = ( "x" => $tabPosX, "y" => $tabPosY + $tableHeight + 5 );
	CamSymbol->AddText( $inCAM, "Tool depths definition", \%posTitl, 6, 1 );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
