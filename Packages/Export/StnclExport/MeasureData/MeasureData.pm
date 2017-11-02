
#-------------------------------------------------------------------------------------------#
# Description: Prepare pad info pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::MeasureData::MeasureData;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::Export::StnclExport::MeasureData::MeasureDataPdf';

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
	$self->{"ncExport"}->{"onItemResult"}->Add( sub { $self->__OnExportResult(@_) } );

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $la

}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __GetPadFeatIds {
	my $self  = shift;
	my $layer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $f = Features->new();

	my @featIds = ();

	for ( my $i = 0.1 ; $i < 25 ; $i += 0.1 ) {

		if ( CamFilter->BySurfaceArea( $inCAM, 0, $i ) > 0 ) {

			my @feat = (1388);
			$f->Parse( $inCAM, $jobId, $self->{"step"}, $layer, 0, 1 );

			my @features = $f->GetFeatures();
			
			 

			last;

			my @layers = ($lName);
			CamLayer->CopySelected( $inCAM, \@layers, 0, 100 );
		}

	}

}

sub __PreparePDF {

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportDrill->new( $inCAM, $jobId );
	$export->Output();

}

1;

