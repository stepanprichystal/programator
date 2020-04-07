
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare non NC layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputData::PrepareLayers::PrepareBase;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Packages::CAMJob::OutputData::LayerData::LayerData';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAMJob::OutputData::Enums';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';

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

	$self->{"profileLim"} = shift;    # limits of pdf step

	$self->{"outputNClayer"} = OutputParserNC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	return $self;
}

sub Prepare {
	my $self   = shift;
	my $layers = shift;

	# prepare layers
	$self->__PrepareLayers($layers);

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __PrepareLayers {
	my $self   = shift;
	my $layers = shift;

	$self->__PrepareBASEBOARD( $layers, Enums->Type_BOARDLAYERS );
	$self->__PrepareOUTLINE( $layers, Enums->Type_OUTLINE );
	$self->__PrepareSPECIALSURF( $layers, Enums->Type_SPECIALSURF );
	$self->__PrepareFILLEDHOLES( $layers, Enums->Type_FILLEDHOLES );
	$self->__PrepareFLEXLAYERS( $layers, Enums->Type_FLEXLAYERS );

}

# Create layer and fill profile - simulate pcb material
sub __PrepareBASEBOARD {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;
	@layers = grep { $_->{"gROWname"} !~ /^(plg|[lg]|gold)[cs]$/i } @layers;         # special surfaces (goldc, gc, lc, plgc,  etc)
	@layers = grep { $_->{"gROWname"} !~ /^(coverlay|stiff)[csv]\d*$/i } @layers;    # special flex layers (coverlayc, coverlays, stiffc,  etc)

	foreach my $l (@layers) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}
}

sub __PrepareOUTLINE {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};

	# 1) Outline layer

	my $lOutline = GeneralHelper->GetNumUID();
	$inCAM->COM( 'create_layer', layer => $lOutline, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	CamLayer->WorkLayer( $inCAM, $lOutline );

	$inCAM->COM( "profile_to_rout", "layer" => $lOutline, "width" => "200" );

	# fake layer 'o'
	my %l = ( "gROWname" => "o" );

	my $enTit = Helper->GetJobLayerTitle( \%l, $type );
	my $czTit = Helper->GetJobLayerTitle( \%l, $type, 1 );
	my $enInf = Helper->GetJobLayerInfo( \%l );
	my $czInf = Helper->GetJobLayerInfo( \%l, 1 );

	my $lData = LayerData->new( $type, \%l, $enTit, $czTit, $enInf, $czInf, $lOutline );

	$self->{"layerList"}->AddLayer($lData);

	# 2)
	my $l = first { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} eq "bendarea" && $_->{"gROWname"} eq "bend" } @layers;

	if ( defined $l ) {
		my $lOutlineFlex = GeneralHelper->GetNumUID();

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lOutlineFlex );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lOutlineFlex );

		$self->{"layerList"}->AddLayer($lData);
	}

}

# gold fingers, grafit paste
sub __PrepareSPECIALSURF {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "drill" && $_->{"gROWlayer_type"} ne "rout" } @layers;

	# 1)  # special surfaces (goldc, gc - where are only affected pads by "reference" layer considered)
	my @lPadConsider = grep { $_->{"gROWname"} =~ /^(g|gold)[cs]$/i } @layers;

	foreach my $l (@lPadConsider) {

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		my $refL    = $l->{"gROWname"};
		my $baseCuL = ( $refL =~ m/^([pmlg]|gold)?([cs])$/ )[1];
		my $maskL   = "m" . $baseCuL;

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {
			$maskL = 0;
		}

		unless ( CamHelper->LayerExists( $inCAM, $jobId, $refL ) ) {
			die "Reference layer $refL doesn't exist.";
		}

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
		my $lName = Helper->FeaturesByRefLayer( $inCAM, $jobId, $baseCuL, $refL, $maskL, $self->{"profileLim"} );

		# if layer is gold[cs] - add info about gold finger count
		if ( $refL =~ m/gold(c|s)/ ) {

			my $cnt = CamGoldArea->GetGoldFingerCount( $inCAM, $jobId, $step, $1 );
			$enInf .= "gold finger count: $cnt";
			$czInf .= "poèet zlacených plošek: $cnt";

			if ( $cnt == 0 ) {
				next;
			}
		}

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

	# 2) # special surfaces where is used  "reference" layer
	my @lRefLayer = grep { $_->{"gROWname"} =~ /^l[cs]$/i } @layers;

	foreach my $l (@lRefLayer) {

		my $lName = GeneralHelper->GetNumUID();

		my $enTit = Helper->GetJobLayerTitle( $l, $type );
		my $czTit = Helper->GetJobLayerTitle( $l, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($l);
		my $czInf = Helper->GetJobLayerInfo( $l, 1 );

		$inCAM->COM( "merge_layers", "source_layer" => $l->{"gROWname"}, "dest_layer" => $lName );

		my $lData = LayerData->new( $type, $l, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

}

# gold fingers, grafit paste
sub __PrepareFILLEDHOLES {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my @lFilled = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} eq "drill" } @layers;

	CamDrilling->AddNCLayerType( \@lFilled );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@lFilled );

	@lFilled = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill
	} @lFilled;

	my %lFilledMatrix = ();
	push( @{ $lFilledMatrix{ $_->{"NCSigStartOrder"} . "_" . $_->{"NCSigEndOrder"} . "_" . $_->{"gROWdrl_dir"} } }, $_ ) foreach (@lFilled);

	foreach my $k ( keys %lFilledMatrix ) {

		die "Wrong key format ($k)" if ( $k !~ /\d+_\d+_(top2bot|bot2top)/ );

		my @l = @{ $lFilledMatrix{$k} };

		my $lName = GeneralHelper->GetNumUID();
		my $lMain = $l[0];

		my $enTit = Helper->GetJobLayerTitle( $lMain, $type );
		my $czTit = Helper->GetJobLayerTitle( $lMain, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($lMain);
		my $czInf = Helper->GetJobLayerInfo( $lMain, 1 );

		# Merge all layers
		foreach my $lFill (@l) {

			my $result = $self->{"outputNClayer"}->Prepare($lFill);

			my $lDrillRout = $result->MergeLayers();    # merge DRILLBase and ROUTBase result layer

			$inCAM->COM(
						 "copy_layer",
						 "source_job"   => $jobId,
						 "source_step"  => $self->{"step"},
						 "source_layer" => $lDrillRout,
						 "dest"         => "layer_name",
						 "dest_step"    => $self->{"step"},
						 "dest_layer"   => $lName,
						 "mode"         => "append"
			);

			$inCAM->COM( "delete_layer", "layer" => $lDrillRout );

		}

		my $lData = LayerData->new( $type, $lMain, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

	}
}

# Special layers connected with flexible PCB: coverlay; stiffener
sub __PrepareFLEXLAYERS {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# 1) Define coverlays
	my @lCoverlay = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} eq "coverlay" } @layers;
	foreach my $cvrL (@lCoverlay) {

		# 1) Create full surface by profile
		my $lName = CamLayer->FilledProfileLim( $inCAM, $jobId, $self->{"pdfStep"}, 1000, $self->{"profileLim"} );
		CamLayer->ClipAreaByProf( $inCAM, $lName, 0, 0,1 );   
		CamLayer->WorkLayer( $inCAM, $lName );

		# 2) Copy coverlay milling

		my @cvrRoutLs =
		  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ] );
		CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@cvrRoutLs );

		my $cvrRoutL = ( grep { $_->{"gROWdrl_start"} eq $cvrL->{"gROWname"} && $_->{"gROWdrl_end"} eq $cvrL->{"gROWname"} } @cvrRoutLs )[0];
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $cvrRoutL->{"gROWname"}, "document" );
		CamLayer->Contourize( $inCAM, $lTmp, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
		$inCAM->COM( "merge_layers", "source_layer" => $lTmp, "dest_layer" => $lName, "invert" => "yes" );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		# 3) If exist coverlay pins, final shape of coverlay depands on NPLT rout layers
		if ( CamHelper->LayerExists( $inCAM, $jobId, "coverlaypins" ) ) {

			# Countourize whole layers and keep surfaces in bend area only

			CamLayer->WorkLayer( $inCAM, $lName );
			CamLayer->ClipAreaByProf( $inCAM, $lName, 1000 );         # do not clip outline rout 3mm behuind profile
			CamLayer->Contourize( $inCAM, $lName, "x_or_y", "0" );

			if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $lName, undef, undef, undef, "bend" ) ) {

				$inCAM->COM('sel_reverse');
				if ( CamLayer->GetSelFeaturesCnt($inCAM) ) {
					CamLayer->DeleteFeatures($inCAM);
				}
			}
		}

		CamLayer->WorkLayer( $inCAM, $lName );
		CamLayer->Contourize( $inCAM, $lName, "x_or_y", "0" );

		my $enTit = Helper->GetJobLayerTitle( $cvrL, $type );
		my $czTit = Helper->GetJobLayerTitle( $cvrL, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($cvrL);
		my $czInf = Helper->GetJobLayerInfo( $cvrL, 1 );

		my $lData = LayerData->new( $type, $cvrL, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);
	}

	# 2) Define stiffeners
	my @stiffLayers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} eq "stiffener" } @layers;

	foreach my $stiffL (@stiffLayers) {

		# 1) Create full surface by profile
		my $lName = CamLayer->FilledProfileLim( $inCAM, $jobId, $self->{"pdfStep"}, 1000, $self->{"profileLim"} );
		CamLayer->ClipAreaByProf( $inCAM, $lName, 0, 0,1 );   
		CamLayer->WorkLayer( $inCAM, $lName );

		# 2) Copy negative of stiffener rout

		my @stiffRoutLs =
		  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_stiffcMill, EnumsGeneral->LAYERTYPE_nplt_stiffsMill ] );
		CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@stiffRoutLs );

		my $stiffRoutL = ( grep { $_->{"gROWdrl_start"} eq $stiffL->{"gROWname"} && $_->{"gROWdrl_end"} eq $stiffL->{"gROWname"} } @stiffRoutLs )[0];
		my $lTmp = CamLayer->RoutCompensation( $inCAM, $stiffRoutL->{"gROWname"}, "document" );
		CamLayer->Contourize( $inCAM, $lTmp, "x_or_y", "203200" );    # 203200 = max size of emptz space in InCAM which can be filled by surface
		$inCAM->COM(
					 "merge_layers",
					 "source_layer" => $lTmp,
					 "dest_layer"   => $lName,
					 "invert"       => "yes"
		);
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lTmp );

		# 3) Copy negatife NPLT mill to stiffener to acheive final stiffener shape

		my @NPLTNClayers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_nMill ] );

		foreach my $npltL (@NPLTNClayers) {

			my $routL = CamLayer->RoutCompensation( $inCAM, $npltL->{"gROWname"}, "document" );
			$inCAM->COM( "merge_layers", "source_layer" => $routL, "dest_layer" => $lName, "invert" => "yes" );
			CamMatrix->DeleteLayer( $inCAM, $jobId, $routL );
		}

		my $enTit = Helper->GetJobLayerTitle( $stiffL, $type );
		my $czTit = Helper->GetJobLayerTitle( $stiffL, $type, 1 );
		my $enInf = Helper->GetJobLayerInfo($stiffL);
		my $czInf = Helper->GetJobLayerInfo( $stiffL, 1 );

		my $lData = LayerData->new( $type, $stiffL, $enTit, $czTit, $enInf, $czInf, $lName );

		$self->{"layerList"}->AddLayer($lData);

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
