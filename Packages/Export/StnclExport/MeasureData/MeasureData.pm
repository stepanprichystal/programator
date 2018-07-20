
#-------------------------------------------------------------------------------------------#
# Description: Prepare pad info pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::MeasureData::MeasureData;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use utf8;
use strict;
use warnings;

use File::Copy;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamFilter';
use aliased 'Packages::Export::StnclExport::MeasureData::MeasureDataPdf';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = "o+1";

	$self->{"measurePdf"} = MeasureDataPdf->new( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;
	my $mess = shift;
	
	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stencilLayer = undef;

	if ( CamHelper->LayerExists( $inCAM, $jobId, "ds" ) ) {

		$stencilLayer = "ds";

	}
	elsif ( CamHelper->LayerExists( $inCAM, $jobId, "flc" ) ) {

		$stencilLayer = "flc";

	}
	else {

		$$mess .="No stencil layer";
		return 0;
	
	}

	my @feats = $self->__GetPadFeats($stencilLayer);

	unless ( scalar(@feats) ) {
 
	 	$$mess .="No stencil pads found in layer $stencilLayer";
		return 0;
	}

	my ( $x, $y ) = $feats[0]->{"symbol"} =~ /(\d+\.?\d*)x(\d+\.?\d*)/i;

	if ( !defined $x || $x == 0 || !defined $y || $y == 0 ) {

		$$mess .= "Can't parse dimension of smallest pad";
		return 0;
		 
	}

	my $title = $jobId . " - Nejmensi ploska: " . sprintf( "%dum", $x ) . " x " . sprintf( "%dum", $y );

	my $pdf = MeasureDataPdf->new( $inCAM, $jobId );

	my @ids = map { $_->{"id"} } @feats;

	$pdf->Create( $self->{"step"}, $stencilLayer, \@ids, $title );

	unless ( move( $pdf->GetPdfOutput(), EnumsPaths->Jobs_STENCILDATA . $jobId . "_padInfo.pdf" ) ) {
		die "Unable to move stencil measure pdf ".$pdf->GetPdfOutput().".";
	}
	
	return $result;
}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __GetPadFeats {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $lPom = GeneralHelper->GetGUID();
	$inCAM->COM( "merge_layers", "source_layer" => $layer, "dest_layer" => $lPom );

	CamLayer->WorkLayer( $inCAM, $lPom );
	$inCAM->COM('sel_break');
	$inCAM->COM( 'sel_contourize', "accuracy" => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60', "clean_hole_mode" => 'x_and_y' );

	my @feats = ();

	for ( my $i = 0.01 ; $i < 25 ; $i += 0.01 ) {

		CamLayer->WorkLayer( $inCAM, $lPom );
		
		if ( CamFilter->BySurfaceArea( $inCAM, 0, $i ) > 0 ) {

			my $sellected = GeneralHelper->GetGUID();
			CamLayer->CopySelOtherLayer( $inCAM, [$sellected] );

			CamLayer->WorkLayer( $inCAM, $layer );

			if ( CamFilter->SelectByReferenece( $inCAM, $jobId, "touch", $layer, undef, undef, undef, $sellected ) ) {

				my $f = Features->new();
				$f->Parse( $inCAM, $jobId, $self->{"step"}, $layer, 0, 1 );

				@feats = grep {$_->{"symbol"} =~ /(\d+\.?\d*)x(\d+\.?\d*)/i } $f->GetFeatures();
				
				if(scalar(@feats)){
					last;
				}
			}
			else {

				die "Error during  select minimal pads in stencil layer";
			}

			$inCAM->COM( 'delete_layer', layer => $sellected );
		}
	}

	$inCAM->COM( 'delete_layer', layer => $lPom );

	return @feats;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::MeasureData::MeasureData';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13609";

	my $export = MeasureData->new( $inCAM, $jobId );
	$export->Output();

}

1;

