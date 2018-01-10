
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for output data-contorl, data-cooperation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::OutExport::OutMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use File::Path 'rmtree';
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Gerbers::ProduceData::ProduceData';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::ETesting::ExportIPC::ExportIPC';
use aliased 'Packages::Export::OutExport::MeasureData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobId"}         = shift;
	$self->{"exportCooper"}  = shift;
	$self->{"cooperStep"}    = shift;
	$self->{"exportEt"}      = shift;
	$self->{"exportControl"} = shift;
	$self->{"controlStep"}   = shift;

	$self->{"exportIPC"} = ExportIPC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cooperStep"}, 1 );
	$self->{"exportIPC"}->{"onItemResult"}->Add( sub { $self->__OnCooperETResult(@_) } );
	$self->{"measureData"} = MeasureData->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"cooperStep"} );

	return $self;
}

sub Run {
	my $self = shift;

	$self->__DeleteOldFiles();

	if ( $self->{"exportCooper"} ) {
		$self->__ExportCooperation();
	}

	if ( $self->{"exportEt"} ) {
		$self->__ExportCooperationET();
	}

	if ( $self->{"exportControl"} ) {

		$self->__ExportControl();

	}

}

sub __ExportCooperation {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) export pdf for measurement

	$self->{"measureData"}->Output();

	# 2) Export cooperation data
	my $produceData = ProduceData->new( $inCAM, $jobId, $self->{"cooperStep"} );

	$produceData->{"onItemResult"}->Add( sub { $self->__OnCooperGerResult(@_) } );

	$produceData->Create();

	my $sourcePath = $produceData->GetOutput();

	my $archivPath = JobHelper->GetJobArchive($jobId) . "\\Zdroje\\kooperace\\";

	unless ( -e $archivPath ) {
		mkdir($archivPath) or die "Can't create dir: " . $archivPath . $_;
	}

	move( $sourcePath, $archivPath . $jobId . "_data.zip" ) or die "Can't move file to : " . $archivPath . $jobId . "_data.zip" . $_;

}

sub __ExportCooperationET {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Export electric test

	if ( $self->{"exportEt"} ) {

		$self->{"exportIPC"}->Export("kooperace");

		# if script run on server, move el test to r:/El_tests
		
		get_logger("abstractQueue")->debug( "Is tpv server: ". GeneralHelper->IsTPVServer() );
		
		if ( GeneralHelper->IsTPVServer() ) {

			my $ipcPath = EnumsPaths->Client_ELTESTS . $jobId . "_kooperace\\" . $jobId . "_kooperace.ipc";
			
			get_logger("abstractQueue")->debug( "path $ipcPath");
			
			if ( -e $ipcPath ) {
				
				get_logger("abstractQueue")->debug( "copy");

				copy( $ipcPath, EnumsPaths->Jobs_ELTESTSIPC . $jobId . "_kooperace.ipc" );
			}

		}
	}
}

sub __OnCooperGerResult {
	my $self = shift;
	my $item = shift;

	$item->SetItemId("Cooperation data");

	$self->_OnItemResult($item);
}

sub __OnCooperETResult {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Cooperation ET");

	$self->_OnItemResult($item);
}

sub __ExportControl {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $produceData = ProduceData->new( $inCAM, $jobId, $self->{"controlStep"} );

	$produceData->{"onItemResult"}->Add( sub { $self->__OnControlGerResult(@_) } );

	$produceData->Create();

	my $sourcePath = $produceData->GetOutput();

	my $archivPath = JobHelper->GetJobArchive($jobId) . "\\Zdroje\\";

	move( $sourcePath, $archivPath . $jobId . "_data_control.zip" ) or die "Can't move file to : " . $archivPath . $jobId . "_data_control.zip" . $_;
}

sub __OnControlGerResult {
	my $self = shift;
	my $item = shift;

	$item->SetItemId("Control data");

	$self->_OnItemResult($item);
}

# Before export , delete MDI gerber and JetPrint gerber
sub __DeleteOldFiles {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	if ( $self->{"exportCooper"} ) {

		my $archivPath = JobHelper->GetJobArchive($jobId) . "\\Zdroje\\kooperace\\";

		if ( -e $archivPath ) {
			rmtree($archivPath) or die "Cannot rmtree " . $archivPath . " : $!";
		}
	}

	if ( $self->{"exportControl"} ) {

		my $archivPath = JobHelper->GetJobArchive($jobId) . "\\Zdroje\\";

		if ( -e $archivPath . $jobId . "_data_control.zip" ) {

			unlink( $archivPath . $jobId . "_data_control.zip" ) or die "Unable to delete " . $archivPath . $jobId . "_data_control.zip";
		}
	}

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += $self->{"exportCooper"}  ? 1 : 0;    # cooperation
	$totalCnt += $self->{"exportEt"}      ? 3 : 0;    # cooperation et
	$totalCnt += $self->{"exportControl"} ? 1 : 0;    # control data

	return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::OutExport::OutMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52457";

	my $out = OutMngr->new( $inCAM, $jobId, 1, "o+1" );

	$out->Run();
}

1;

