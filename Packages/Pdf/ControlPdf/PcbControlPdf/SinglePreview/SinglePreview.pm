
#-------------------------------------------------------------------------------------------#
# Description: Create pdf of single layer previef + drill maps with titles and description
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::SinglePreview;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased "Helpers::JobHelper";
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::LayerData::LayerDataList';
use aliased 'Packages::Pdf::ControlPdf::Helpers::SinglePreview::OutputPdfBase';
use aliased 'Packages::CAMJob::OutputData::OutputData';
use aliased 'Packages::CAMJob::OutputData::Enums' => 'OutDataEnums';

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
	$self->{"SR"}    = shift;    # Consider SR steps
	$self->{"lang"}  = shift;

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	$self->{"outputData"} = OutputData->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"SR"} );

	$self->{"layerList"} = LayerDataList->new( $self->{"lang"} );
	$self->{"outputPdf"} =
	  OutputPdfBase->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"outputData"}->GetStepName(),
						  $self->{"lang"}, $self->{"outputPath"} );

	return $self;
}

# Return
# 0 - error
# 1 - succes
# 2 - no layer to export
sub Create {
	my $self           = shift;
	my $drawProfile    = shift;
	my $drawProfile1Up = shift;
	my $SRExist        = shift // 0;
	my $message        = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# prepare layers for export

	my $mess   = "";
	my $result = $self->{"outputData"}->Create( \$mess );

	unless ($result) {
		die "Error when preparing layers for output." . $mess . "\n";
	}

	my @dataLayers = $self->{"outputData"}->GetLayers();
	my $stepName   = $self->{"outputData"}->GetStepName();

	# 1) Filter layers for output

	$self->__FilterLayersForOutput( \@dataLayers, $SRExist );

	# 2) Sort layers for output
	my @sorted = ();

	push( @sorted, grep { $_->GetOriLayer()->{"gROWlayer_type"} eq "silk_screen" } @dataLayers );
	push( @sorted, grep { $_->GetOriLayer()->{"gROWlayer_type"} eq "solder_mask" } @dataLayers );
	push( @sorted, grep { $_->GetOriLayer()->{"gROWlayer_type"} =~ /(siglnal)|(power_ground)|(mixed)/ } @dataLayers );

	# If no layers for export return 0 
	unless (scalar(@sorted)){
		
		$$message = "No layers";
		return 2;
	}

	$_->{"sorted"} = 1 foreach (@sorted);
	push( @sorted, grep { !defined $_->{"sorted"} } @dataLayers );
	delete $_->{"sorted"} foreach (@sorted);

	# 3) Set layer list structure

	$self->{"layerList"}->SetStepName($stepName);
	$self->{"layerList"}->SetLayers( \@sorted );

	# 4) define multiplicity per page by step size

	my $featsCnt = 0;
	my @layers   = $self->{"layerList"}->GetLayers();
	foreach my $l ( map { $_->GetOutput() } @layers ) {
		  my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $self->{"outputData"}->GetStepName(), $l );
		  $featsCnt += $hist{"total"};
	}

	my $featPerL = $featsCnt / scalar(@layers);

	# Decide if 9 or 4 layers per page
	my $multiplX = 3;
	my $multiplY = 3;
	if ( $featPerL > 4000 ) {
		  $multiplX = 2;
		  $multiplY = 2;
	}

	# 5) Output pdf
	$self->{"outputPdf"}->Output( $self->{"layerList"}, $multiplX, $multiplY, $drawProfile, $drawProfile1Up, [ 255, 157, 157 ], [ 180, 180, 180 ] );

	# clear job
	$self->{"outputData"}->Clear();

	return $result;

}

sub GetOutput {
	  my $self = shift;

	  return $self->{"outputPdf"}->GetOutput();
}

sub __FilterLayersForOutput {
	  my $self       = shift;
	  my $dataLayers = shift;
	  my $SRExist    = shift;

	  # 1) Remove outline layers
	  @{$dataLayers} = grep { !( $_->GetType() eq OutDataEnums->Type_OUTLINE && $_->GetOriLayer()->{"gROWname"} eq "o" ) } @{$dataLayers};

	  # 2) Remove inner layers of panel
	  if ($SRExist) {
		  @{$dataLayers} =
			grep { !( $_->GetType() eq OutDataEnums->Type_BOARDLAYERS && $_->GetOriLayer()->{"gROWname"} =~ /^v\d$/ ) } @{$dataLayers};
	  }
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

