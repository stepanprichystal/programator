
#-------------------------------------------------------------------------------------------#
# Description: Responsible for preparing control data or cooperaton data
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::ProduceData;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Path 'rmtree';

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Gerbers::ProduceData::LayerData::LayerDataList';
use aliased 'Packages::Gerbers::ProduceData::OutputLayers';
use aliased 'Packages::Gerbers::ProduceData::OutputInfo';
use aliased 'Packages::Gerbers::ProduceData::OutputPdf';
use aliased 'Packages::Gerbers::ProduceData::Enums';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::OutputData';
use aliased 'Packages::ItemResult::Enums' => "EnumsResult";

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"produceDataResult"} = $self->_GetNewItem("Produce data");

	my $filesDir = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . "\\";
	mkdir($filesDir) or die "Can't create dir: " . $filesDir . $_;

	$self->{"layerList"}    = LayerDataList->new( $self->{"jobId"} );
	$self->{"outputLayers"} = OutputLayers->new( $self->{"inCAM"}, $self->{"jobId"}, $filesDir );
	$self->{"outputInfo"}   = OutputInfo->new( $self->{"inCAM"}, $self->{"jobId"},$self->{"step"}, $filesDir );
	$self->{"outputPdf"}   = OutputPdf->new( $self->{"inCAM"}, $self->{"jobId"}, $filesDir );
	

	$self->{"outputLayers"}->{"onItemResult"}->Add( sub { $self->__OnLayersResult(@_) } );

	$self->{"filesDir"}  = $filesDir;
	$self->{"outputZip"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".zip";

	return $self;
}

# Create image preview
sub Create {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# prepare layers for export
	my $outData = OutputData->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	my $mess   = "";
	my $result = $outData->Create( \$mess );

	unless ($result) {
		die "Error when preparing layers for output." . $mess . "\n";
	}

	my @dataLayers = $outData->GetLayers();
	my $stepName   = $outData->GetStepName();

	$self->{"layerList"}->AddLayers( \@dataLayers );
	$self->{"layerList"}->SetStepName($stepName);

	# Prepare layers for export
	$self->{"outputLayers"}->Output( $self->{"layerList"} );

	# Prepare info file readme.txt
	$self->{"outputInfo"}->Output( $self->{"layerList"} );
	
	# Prepare stackup pdf
	$self->{"outputPdf"}->Output( $self->{"layerList"} );

	$self->__ZipFiles();

	# clear job
	$outData->Clear();

	$self->_OnItemResult( $self->{"produceDataResult"} );

	return 1;
}

# Return path of image
sub GetOutput {
	my $self = shift;

	return $self->{"outputZip"};
}

sub __OnLayersResult {
	my $self = shift;
	my $item = shift;

	if ( $item->Result() eq EnumsResult->ItemResult_Fail ) {

		my @errors = $item->GetErrors();
		$self->{"produceDataResult"}->AddErrors(\@errors);
	}
}

sub __ZipFiles {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	my $zip = Archive::Zip->new();

	my $dir;
	opendir( $dir, $self->{"filesDir"} );
	while ( ( my $f = readdir($dir) ) ) {

		next unless $f =~ /^[a-z]/i;

		$zip->addFile( $self->{"filesDir"} . "\\" . $f, $f );

	}
	close $dir;

	## Add a directory
	#my $dir = $zip->addDirectory( $archivePath . "\\" );

	if ( $zip->writeToFileNamed( $self->{"outputZip"} ) == AZ_OK ) {

		rmtree( $self->{"filesDir"} ) or die "Cannot rmtree " . $self->{"filesDir"} . " : $!";
	}
	else {

		die 'Error when zip output jpb files';
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::ProduceData::ProduceData';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152456";

	my $mess = "";

	my $control = ProduceData->new( $inCAM, $jobId, "o+1" );
	$control->Create();

}

1;

