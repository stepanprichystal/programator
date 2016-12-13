
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::SinglePreview::SinglePreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased "Helpers::JobHelper";
use aliased 'Packages::Pdf::ControlPdf::LayerData::LayerData';
use aliased 'Packages::Pdf::ControlPdf::Enums';
use aliased 'Packages::Pdf::ControlPdf::OutputPdf';


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;
	
	$self->{"outputPdf"} = OutputPdf->new();

	return $self;
}

sub Create {
	my $self = shift;
	my $lRef = shift;

	# get all base layers
	my @layers = CamJob->GetBoardLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# Filter only requested layers
	if ($lRef) {

		for ( my $i = scalar(@layers) ; $i >= 0 ; $i-- ) {

			my $l = $layers[$i];
			my $exist = scalar( grep { $_ eq $l->{"gROWname"} } @{$lRef} );

			unless ($exist) {
				splice @layers, $i, 1;    #remove
			}
		}
	}
	
	# Filter ou helper layers fr, v1, etc..

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );

	my $pdfStep = $self->__CreatePdfStep();

	CamHelper->SetStep( $self->{"inCAM"}, $pdfStep );

	my @layerData = $self->__PrepareLayerData( \@layers );
	
	
	$self->{"outputPdf"}->OutputData(\@layerData);
	

	$self->__DeletePdfStep($pdfStep);

}

sub __PrepareLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @layerData = ();

	push(@layerData, $self->__PrepareBaseLayerData(\@layers));
	push(@layerData, $self->__PrepareNCLayerData(\@layers));

}

sub __PrepareBaseLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @resultData = ();

	# prepare non  NC layers
	@layers = grep { $_->{"gROWlayer_type"} ne "rout" || $_->{"gROWlayer_type"} ne "drill" } @layers;

	foreach my $l (@layers) {

		my $lData = LayerData->new();

		my %infoData = ();
		my %info     = ();

		my $tit = JobHelper->GetJobLayerTitle( $l->{"gROWname"} );
		$tit += " / " . JobHelper->GetJobLayerTitle( $l->{"gROWname"}, 1 );

		my $inf = JobHelper->GetJobLayerInfo( $l->{"gROWname"} );
		unless ($inf) {
			$inf += " / " . JobHelper->GetJobLayerInfo( $l->{"gROWname"}, 1 );
		}

		$lData->AddSingleLayer( $l, $tit, $inf );

		push( @resultData, $lData );
	}

}

sub __PrepareNCLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @resultData = ();

	# prepare non  NC layers
	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	CamDrilling->AddNCLayerType( \@layers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	foreach my $l (@layers) {

		my $lData = LayerData->new(Enums->LayerData_STANDARD);

		my %infoData = ();
		my %info     = ();

		my $tit = JobHelper->GetJobLayerTitle( $l->{"gROWname"} );
		$tit += " / " . JobHelper->GetJobLayerTitle( $l->{"gROWname"}, 1 );

		my $inf = JobHelper->GetJobLayerInfo( $l->{"gROWname"} );
		unless ($inf) {
			$inf += " / " . JobHelper->GetJobLayerInfo( $l->{"gROWname"}, 1 );
		}

		$lData->AddSingleLayer( $l, $tit, $inf );

		push( @resultData, $lData );
	}

	# merge f + rs layer data  if exist

	my $dataWithF  = ( grep { $_->GetLayerByName("f") } @resultData )[0];
	my $dataWithRs = ( grep { $_->GetLayerByName("rs") } @resultData )[0];

	# if data containing layer rs and f exist, merge them
	if ( $dataWithF || $dataWithRs ) {

		$dataWithF->AddSingleLayer( $dataWithRs->GetLayerByName("rs") );    #merging

		my $idx = ( grep { $resultData[$_]->GetLayerByName("rs") } 0 .. $#resultData )[0];
		splice @resultData, $idx, 1;                                        # delete rs data
	}
	
	
	# add drill map layers
	
	foreach my $l (@layers) {

		if($l->{"gROWname"} eq "rs" || $l->{"gROWname"} eq "fk" ){
			next;
		}

		my $lData = LayerData->new(Enums->LayerData_DRILLMAP);

		my %infoData = ();
		my %info     = ();

		my $tit = "Drill map: ".JobHelper->GetJobLayerTitle( $l->{"gROWname"} );
		$tit += " / " . JobHelper->GetJobLayerTitle( $l->{"gROWname"}, 1 );
 
		$lData->AddSingleLayer( $l, $tit, "" );
	 
		push( @resultData, $lData );
	}
 
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

