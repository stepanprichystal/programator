
#-------------------------------------------------------------------------------------------#
# Description: Special layer - Copper, contain special propery and operation for this
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerDataList;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::Enums';
use aliased 'Packages::Pdf::ControlPdf::SinglePreview::LayerData::LayerData';

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

		my $lData = LayerData->new( Enums->LayerData_STANDARD );

		my %infoData = ();
		my %info     = ();

		my $enTit = JobHelper->GetJobLayerTitle($l);
		my $czTit = JobHelper->GetJobLayerTitle( $l, 1 );
		my $enInf = JobHelper->GetJobLayerInfo($l);
		my $czInf = JobHelper->GetJobLayerInfo( $l, 1 );

		$lData->AddSingleLayer( $l, $enTit, $czTit, $enInf, $czInf );

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

		my $lData = LayerData->new( Enums->LayerData_STANDARD );

		my %infoData = ();
		my %info     = ();

		my $enTit = JobHelper->GetJobLayerTitle($l);
		my $czTit = JobHelper->GetJobLayerTitle( $l, 1 );
		my $enInf = JobHelper->GetJobLayerInfo($l);
		my $czInf = JobHelper->GetJobLayerInfo( $l, 1 );

		$lData->AddSingleLayer( $l, $enTit, $czTit, $enInf, $czInf );

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

		# smazat rs
		#my $idx = ( grep { $resultData[$_]->GetLayerByName("rs") } 0 .. $#resultData )[0];

		#splice @resultData, $idx, 1;                                        # delete rs data
	}

	# add drill map layers

	foreach my $l (@layers) {

		if ( $l->{"gROWname"} eq "rs" || $l->{"gROWname"} eq "fk" || $l->{"gROWlayer_type"} ne "drill" ) {
			next;
		}

		my $lData = LayerData->new( Enums->LayerData_DRILLMAP );

		my %infoData = ();
		my %info     = ();

		my $enTit = "Drill map: " . JobHelper->GetJobLayerTitle($l);
		my $czTit = "Mapa vrtani: " . JobHelper->GetJobLayerTitle( $l, 1 );
		my $enInf = "";
		my $czInf = "";

		$lData->AddSingleLayer( $l, $enTit, $czTit, $enInf, $czInf );

		push( @{ $self->{"layers"} }, $lData );
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

		my $sl = ( grep { $_->GetLayer()->{"gROWname"} eq $name } @single )[0];

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

			my $tit = join( " + ", map { $_->GetTitle( $self->{"lang"} ) } @singleLayers );
			my $inf = join( " + ", map { $_->GetInfo( $self->{"lang"} ) } @singleLayers );

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

