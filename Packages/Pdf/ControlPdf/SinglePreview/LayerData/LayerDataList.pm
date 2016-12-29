
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataList;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerData';
use aliased 'Helpers::ValueConvertor';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	$self->{"lang"} = shift;

	#$self->{"inCAM"} = shift;
	#$self->{"jobId"} = shift;
	my @l = ();
	$self->{"layers"} = \@l;

	return $self;
}

sub SetLayers {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	# layer data are sorted by final order of printing

	$self->__PrepareBaseLayerData( \@layers );
	$self->__PrepareNCLayerData( \@layers );

}

sub __PrepareBaseLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	# prepare non  NC layers
	@layers = grep { $_->{"gROWlayer_type"} ne "rout" && $_->{"gROWlayer_type"} ne "drill" } @layers;

	foreach my $l (@layers) {

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $lData = LayerData->new( Enums->LayerData_STANDARD, $enTit, $czTit, $enInf, $czInf );

		$lData->AddSingleLayer($l);

		push( @{ $self->{"layers"} }, $lData );
	}

}

sub __PrepareNCLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	# prepare non  NC layers

	#CamDrilling->AddNCLayerType( \@layers );
	#CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	foreach my $l (@layers) {

		my $enTit = ValueConvertor->GetJobLayerTitle($l);
		my $czTit = ValueConvertor->GetJobLayerTitle( $l, 1 );
		my $enInf = ValueConvertor->GetJobLayerInfo($l);
		my $czInf = ValueConvertor->GetJobLayerInfo( $l, 1 );

		my $lData = LayerData->new( Enums->LayerData_STANDARD, $enTit, $czTit, $enInf, $czInf );

		$lData->AddSingleLayer($l);

		push( @{ $self->{"layers"} }, $lData );
	}

	# merge f + rs layer data  if exist

	my $dataWithF  = $self->GetLayerByName("f");
	my $dataWithRs = $self->GetLayerByName("rs");

	# if data containing layer rs and f exist, merge them
	if ( $dataWithF && $dataWithRs ) {

		my @rsLayers = $dataWithRs->GetSingleLayers();

		foreach my $l (@rsLayers) {
			$dataWithF->AddSingleLayer($l);    #merging
		}

		# delete rs

		my $allL = $self->{"layers"};

		for ( my $i = 0 ; $i < scalar( $self->{"layers"} ) ; $i++ ) {

			my $l = @{ $self->{"layers"} }[$i];

			if ( $l == $dataWithRs ) {
				splice @{ $self->{"layers"} }, $i, 1;
				last;
			}

		}

	}

	# add drill map layers

	foreach my $l (@layers) {

		if (    ( $l->{"gROWlayer_type"} ne "drill" || $l->{"gROWlayer_type"} ne "rout" )
			 && $l->{"fHist"}
			 && ( $l->{"fHist"}->{"pad"} > 0 || $l->{"fHist"}->{"line"} > 0 )
			 &&  $l->{"gROWname"} ne "score")
		{

			my $enTit = "Drill map: " . ValueConvertor->GetJobLayerTitle($l);
			my $czTit = "Mapa vrtání: " . ValueConvertor->GetJobLayerTitle( $l, 1 );
			my $enInf = "Units [mm] " . ValueConvertor->GetJobLayerInfo($l);
			my $czInf = "Jednotky [mm] " . ValueConvertor->GetJobLayerInfo( $l, 1 );

			my $lData = LayerData->new( Enums->LayerData_DRILLMAP, $enTit, $czTit, $enInf, $czInf );

			$lData->AddSingleLayer($l);

			push( @{ $self->{"layers"} }, $lData );

		}

	}

	#	# add final layer data to list
	#	foreach my $lData (@resultData){
	#
	#	}

}

sub AddSingleLayer {
	my $self  = shift;
	my $l     = shift;
	my $enTit = shift;
	my $czTit = shift;
	my $enInf = shift;
	my $czInf = shift;

	my $d = SingleLayerData->new( $l, $enTit, $czTit, $enInf, $czInf );

	push( @{ $self->{"layers"} }, $d );

}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };

}

sub GetLayerCnt {
	my $self = shift;

	return @{ $self->{"layers"} };
}

sub GetLayerByName {
	my $self = shift;
	my $name = shift;

	foreach my $lData ( @{ $self->{"layers"} } ) {

		my @single = $lData->GetSingleLayers();

		my $sl = ( grep { $_->{"gROWname"} eq $name } @single )[0];

		if ($sl) {

			return $lData;
		}
	}

}

sub GetPageData {
	my $self    = shift;
	my $pageNum = shift;

	my @data = ();

	my @layers = @{ $self->{"layers"} };

	my $start = ( $pageNum - 1 ) * 4;

	for ( my $i = 0 ; $i < 4 ; $i++ ) {

		my $lData = $layers[ $start + $i ];

		if ($lData) {
			my @singleLayers = $lData->GetSingleLayers();

			my $tit = $lData->GetTitle( $self->{"lang"} );
			my $inf = $lData->GetInfo( $self->{"lang"} );

			my %inf = ( "title" => $tit, "info" => $inf );
			push( @data, \%inf );
		}

	}

	return @data;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

