
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::ControlPdf;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';

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

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"step"} );

	my $pdfStep = $self->__CreatePdfStep();

	CamHelper->SetStep( $self->{"inCAM"}, $pdfStep );

	$self->__PrepareLayerData( \@layers );

	$self->__DeletePdfStep($pdfStep);

}

sub __PrepareLayerData {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @finalLayer = ();

	# prepare non  NC layers
	my @baseLayers = grep { $_->{"gROWlayer_type"} ne "rout" || $_->{"gROWlayer_type"} ne "drill" } @layers;
	
	
	foreach my $l {}
	
	
	
	my @NCLayers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

}

sub __GetLayerTitle {
	my $self = shift;
	my $name = shift;
 
}

# create special step, which IPC will be exported from
sub __CreatePdfStep {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepPdf = "pdf_" . $self->{"step"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $stepPdf ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepPdf, "type" => "step" );
	}

	$inCAM->COM(
				 'copy_entity',
				 type             => 'step',
				 source_job       => $jobId,
				 source_name      => $self->{"step"},
				 dest_job         => $jobId,
				 dest_name        => $stepPdf,
				 dest_database    => "",
				 "remove_from_sr" => "yes"
	);

	return $stepPdf;
}

# delete pdf step
sub __DeletePdfStep {
	my $self    = shift;
	my $stepPdf = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $stepPdf ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepPdf, "type" => "step" );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

