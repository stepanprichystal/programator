
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <LayerData> and operations with this items
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::LayerData::LayerDataList;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Gerbers::ProduceData::LayerData::LayerData';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::ValueConvertor';
use aliased 'Packages::CAMJob::OutputData::Enums' => 'EnumsOut';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	my @l = ();
	$self->{"layers"} = \@l;

	$self->{"stepName"} = undef;

	$self->{"lang"} = "en";

	return $self;
}

sub AddLayers {
	my $self   = shift;
	my $layers = shift;    # layer, typ of Packages::Gerbers::OutputData::LayerData::LayerData

	foreach my $lOutput ( @{$layers} ) {

		# Process only layers, which has no parent
		if ( $lOutput->GetParent() ) {
			next;
		}

		my $name       = "";
		my $nameSuffix = 0;

		$self->__GetFileName( $lOutput, \$name, \$nameSuffix );

		my $l = LayerData->new( $lOutput->GetType(), $name, $nameSuffix,
								$lOutput->GetTitle( $self->{"lang"} ),
								$lOutput->GetInfo( $self->{"lang"} ),
								$lOutput->GetOutput() );
		push( @{ $self->{"layers"} }, $l );

		# Process parent layers

		foreach my $child ( @{$layers} ) {

			if ( defined $child->GetParent() && $child->GetParent() == $lOutput ) {

				my $lChild = LayerData->new( $child->GetType(), $name, $nameSuffix,
											 $child->GetTitle( $self->{"lang"} ),
											 $child->GetInfo( $self->{"lang"} ),
											 $child->GetOutput() );
				push( @{ $self->{"layers"} }, $lChild );

				$lChild->{"parent"} = $l;
			}
		}
	}
}

sub __GetFileName {
	my $self       = shift;
	my $lOutput    = shift;
	my $name       = shift;
	my $nameSuffix = shift;

	# 1) get new name
	my $oriL = $lOutput->GetOriLayer();

	$$name = $self->{"jobId"} . $self->__GetFileNameByLayer( $oriL, $lOutput->GetType() );

	# 2) verify if same name exist (consider only layer without parent)

	my @same = grep { !defined $_->{"parent"} && $_->{"name"} eq $$name } @{ $self->{"layers"} };

	if ( scalar(@same) ) {

		if ( scalar(@same) == 1 ) {
			$same[0]->{"nameSuffix"} = 1;
		}

		$$nameSuffix = scalar(@same) + 1;
	}

}

# Return name of file of exported layer
sub __GetFileNameByLayer {
	my $self       = shift;
	my $l          = shift;
	my $outputType = shift;    # Packages::CAMJob::OutputData::Enums::Type_

	my $name = "";
	my ($numInName) = $l->{"gROWname"} =~ /(\d*)/;
	unless (defined) {
		$numInName = "";
	}
	else {
		$numInName = "_" . $numInName;
	}

	# outline
	if ( $l->{"gROWname"} =~ /^o$/i ) {
		$name = "dim";

	}

	# inner layer
	elsif ( $l->{"gROWname"} =~ /^v(\d)$/i ) {

		my $lNum = $1;
		$name = "in" . $lNum;
	}

	# board base layer
	elsif ( $l->{"gROWname"} =~ /^([pmlg]|gold)?[cs]2?$/i ) {

		my %en = ();
		$en{"pc"}    = "plt";
		$en{"pc2"}   = "plt2";
		$en{"ps"}    = "plb";
		$en{"ps2"}   = "plb2";
		$en{"mc"}    = "smt";
		$en{"ms"}    = "smb";
		$en{"c"}     = "top";
		$en{"s"}     = "bot";
		$en{"lc"}    = "lc";
		$en{"ls"}    = "ls";
		$en{"gc"}    = "gc";
		$en{"gs"}    = "gs";
		$en{"goldc"} = "goldfingerst";
		$en{"golds"} = "goldfingersb";

		$name = $en{ $l->{"gROWname"} };

	}

	# nc layers
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq EnumsOut->Type_NCLAYERS ) )
	{

		$name = "pth";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq EnumsOut->Type_NCLAYERS ) )
	{

		$name = "pth_blind_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot
			|| ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq EnumsOut->Type_NCLAYERS ) )
	{

		$name = "pth_blind_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $outputType eq EnumsOut->Type_FILLEDHOLES ) {

		$name = "filled_pth";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop && $outputType eq EnumsOut->Type_FILLEDHOLES ) {

		$name = "filled_pth_blind_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot && $outputType eq EnumsOut->Type_FILLEDHOLES ) {

		$name = "filled_pth_blind_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
		$name = "pth_core_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill && $outputType eq EnumsOut->Type_FILLEDHOLES ) {
		$name = "filled_pth_core_" . $l->{"NCSigStartOrder"} . "-" . $l->{"NCSigEndOrder"};
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill ) {
		$name = "mill_pth";

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {

		$name = "mill_pth_top";

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
		$name = "mill_pth_bot";

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nDrill ) {
		$name = "npth";

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
		$name = "mill";

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
		$name = "mill_top";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
		$name = "mill_bot";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
		$name = undef;    # we do not export rs

	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop ) {
		$name = "mill_core_top";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot ) {
		$name = "mill_core_bot";
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
		$name = undef;
	}
	elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_score ) {
		$name = "score";
	}

	return $name;

}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };
}

sub GetLayersByType {
	my $self = shift;
	my $type = shift;

	my @layers = grep { $_->GetType() eq $type } @{ $self->{"layers"} };

	return @layers;
}

sub GetStepName {
	my $self = shift;

	return $self->{"stepName"};
}

sub SetStepName {
	my $self = shift;

	$self->{"stepName"} = shift;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

