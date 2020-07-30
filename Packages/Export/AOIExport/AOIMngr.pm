
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::AOIExport::AOIMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Basename;
use File::Copy;

#local library

use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::AOTesting::ExportOPFX::ExportOPFX';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 1;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"stepToTest"}     = shift;         # step, which will be tested
	$self->{"layerNames"}     = shift;         # step, which will be tested
	$self->{"sendToServer"}   = shift;         # if AOI data shoul be send to server from ot folder
	$self->{"incldMpanelFrm"} = shift // 1;    # if pcb step is placed in SR panel, test optically panel frame

	# PROPERTIES
	$self->{"attemptCnt"} = 50;                                                              # max count of attempt
	$self->{"path"}       = JobHelper->GetJobArchive( $self->{"jobId"} ) . "zdroje\\ot\\";

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->{"exportOPFX"} = ExportOPFX->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepToTest"}, $self->{"attemptCnt"}, 0 );
	$self->{"exportOPFX"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	# Set solder mask layer as non board and document
	# It gives better result on AOI 19.1.2018
	my $mc = ( grep { $_->{"gROWname"} eq "mc" } CamJob->GetBoardBaseLayers( $inCAM, $jobId ) )[0];
	if ($mc) {

		CamLayer->SetLayerTypeLayer( $inCAM, $jobId, "mc", "document" );

		#CamLayer->SetLayerContextLayer( $inCAM, $jobId, "mc", "misc" );
	}

	my $ms = ( grep { $_->{"gROWname"} eq "ms" } CamJob->GetBoardBaseLayers( $inCAM, $jobId ) )[0];
	if ($ms) {

		CamLayer->SetLayerTypeLayer( $inCAM, $jobId, "ms", "document" );

		#CamLayer->SetLayerContextLayer( $inCAM, $jobId, "ms", "misc" );
	}

	# Eport OT

	$self->{"exportOPFX"}->Export( $self->{"path"}, $self->{"layerNames"}, $self->{"incldMpanelFrm"} );

	# Copy created IPC to server where are ipc stored
	if ( $self->{"sendToServer"} ) {
		$self->__CopyOPFXToServer();
	}

	if ($mc) {

		CamLayer->SetLayerTypeLayer( $inCAM, $jobId, "mc", "solder_mask" );

		#CamLayer->SetLayerContextLayer( $inCAM, $jobId, "mc", "board" );
	}

	if ($ms) {

		CamLayer->SetLayerTypeLayer( $inCAM, $jobId, "ms", "solder_mask" );

		#CamLayer->SetLayerContextLayer( $inCAM, $jobId, "ms", "board" );
	}

}

sub __CopyOPFXToServer {
	my $self  = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	foreach my $layer ( @{ $self->{"layerNames"} } ) {

		my @aoiFile = FileHelper->GetFilesNameByPattern( $self->{"path"}, "$jobId@" . "$layer" );

		if ( scalar(@aoiFile) ) {

			my $dest = EnumsPaths->Jobs_AOITESTSFUSION . ( fileparse( $aoiFile[0] ) )[0];

			unless ( copy( $aoiFile[0], $dest ) ) {
				die "Unable to copy AOI test $aoiFile[0] to server\n";
			}
		}

	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1;                      # getting sucesfully AOI manager
	$totalCnt += $self->{"layerCnt"};    #export each layer

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::AOIExport::AOIMngr';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName   = "d282870";
	my $stepName  = "mpanel";
	my $layerName = "c";

	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, [ "c", "s" ], 0, 1 );
	$mngr->Run();
}

1;

