
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepare layers before print as pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::OutputData::PrepareLayers::PrepareNCDrawing;

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
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

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

sub Prepare {
	my $self   = shift;
	my @layers = @{ shift(@_) };
	my $type   = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	@layers = grep {
		     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop
		  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot
	} @layers;

	foreach my $l (@layers) {

		$self->__ProcessNClayer( $l, $type );

	}

}

# MEthod do necessary stuff for each layer by type
# like resizing, copying, change polarity, merging, ...
sub __ProcessNClayer {
	my $self = shift;
	my $l    = shift;
	my $type = shift;

	my %lines_arcs = %{ $l->{"symHist"}->{"lines_arcs"} };
	my %pads       = %{ $l->{"symHist"}->{"pads"} };

	# 1) Proces slots (lines + arcs)

	foreach my $sym ( keys %lines_arcs ) {

		if ( $lines_arcs{$sym} > 0 ) {

			my $depth = $self->__GetSymbolDepth($sym);

			my $lName = $self->__SeparateSymbol( $l, Enums->Symbol_SLOT, $sym, $depth );

			__ProcessTypeSlot

		}
	}

	# 2) Proces holes ( pads )

	foreach my $sym ( keys %pads ) {

		if ( $pads{$sym} > 0 ) {

			my @depths = $self->__GetDepths();

			foreach my $depth (@depths) {

				__ProcessTypeHole

			}
		}
	}

	# 3) Process surfaces
	if ( $l->{"fHist"}->{"surf"} > 0 ) {

	}

}

# Copy type of symbols to new layer and return layer name
sub __SeparateSymbol {
	my $self    = shift;
	my $sourceL = shift;
	my $type    = shift;    # slot / hole / surface
	my $symbol  = shift;
	my $depth   = shift;

	my $inCAM = $self->{"inCAM"};

	# 1) copy source layer to

	my $lName = GeneralHelper->GetGUID();

	my $f = FeatureFilter->new( $inCAM, $sourceL->{"gROWname"} );

	if ( $type eq Enums->Enums->Symbol_HOLE ) {

		my @types = ("pad");
		$f->SetTypes( \@types );

		my @syms = ($symbol);
		$f->AddIncludeSymbols( \@syms );

	}
	elsif ( $type eq Enums->Enums->Symbol_SLOT ) {

	}
	elsif ( $type eq Enums->Enums->Symbol_SURFACE ) {

	}

	unless ( $f->Select() > 0 ) {
		die "no features selected.\n";
	}

	$inCAM->COM(
				 "sel_copy_other",
				 "dest"         => "layer_name",
				 "target_layer" => $lName
	);

	# if slot or surface, do compensation
	if ( $type eq Enums->Enums->Symbol_SLOT || $type eq Enums->Enums->Symbol_SURFACE ) {

		CamLayer->WorkLayer( $inCAM, $lName);
		my $lComp = CamLayer->RoutCompensation( $inCAM, $sourceL->{"gROWname"}, "document" );

		CamLayer->WorkLayer( $inCAM, $lName );
		$inCAM->COM("sel_delete");

		$inCAM->COM( "merge_layers", "source_layer" => $lComp, "dest_layer" => $lName );
		$inCAM->COM( "delete_layer", "layer" => $lComp );
	}

}

# Copy type of symbols to new layer and return layer name
sub __GetSymbolDepth {
	my $self    = shift;
	my $sourceL = shift;
	my $symbol  = shift;
	
	


	my $lName = GeneralHelper->GetGUID();

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
