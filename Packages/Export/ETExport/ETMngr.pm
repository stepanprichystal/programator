
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ETExport::ETMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use Log::Log4perl qw(get_logger :levels);
use File::Path 'rmtree';

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::ETesting::BasicHelper::OptSet';
use aliased 'Packages::ETesting::BasicHelper::ETSet';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::ETesting::ExportIPC::ExportIPC';
use aliased 'Managers::AsyncJobMngr::Helper' => 'AsyncHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamNetlist';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId = __PACKAGE__;
	my $createFakeL = 1;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL);
	bless $self;
 

	$self->{"stepToTest"}   = shift;    # step, which will be tested
	$self->{"createEtStep"} = shift;    # 1 - et step will be created from scratch, 0 - already prepared et step
	$self->{"keepProfile"}  = shift;    # keep profile in nested steps (IPC file will contain SR)
	$self->{"localCopy"}    = shift;    # store IPC file to local pc disc
	$self->{"serverCopy"}   = shift;    # store ipc file to server

	$self->{"exportIPC"} = ExportIPC->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepToTest"}, $self->{"createEtStep"} );
	$self->{"exportIPC"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 
	# Remove "nestlist helper" steps
	CamNetlist->RemoveNetlistSteps( $inCAM, $jobId );

	$self->{"exportIPC"}->Export( undef, $self->{"keepProfile"} );

	# Copy created IPC to server where are ipc stored
	if ( $self->{"serverCopy"} ) {
		$self->__CopyIPCToETServer();
	}

	# Copy IPC to R: where IPC will be taken by random TPV user to processing (temporary solution for reorders)
	$self->__CopyIPCToETStorage();

	# Remove client copy of IPC if is not requested
	if ( !$self->{"localCopy"} || GeneralHelper->IsTPVServer() ) {

		my $ipcPath = EnumsPaths->Client_ELTESTS . $jobId . "t\\";
		if ( -e $ipcPath ) {

			rmtree($ipcPath) or die "Unable to delete local copy of IPC ($ipcPath). " . $!;
		}
	}

}

# Copy created IPC to server where are prepared electrical test for machines
# Usefull when ET program is not already prepared and operator has to prepare program itself.
sub __CopyIPCToETServer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepToTest"};

	# Test if el test exist
	my $path = JobHelper->GetJobElTest($jobId) . "\\" . $jobId . "t.ipc";

	my $elTestExist = 1;
	unless ( -e $path ) {

		my $p = EnumsPaths->Jobs_ELTESTS . substr( uc($jobId), 0, 4 );

		
		unless ( -e $p ) {
			# Create parent dir
			mkdir($p) or die "Can't create dir: $p" . $_;
		}

		unless ( -e JobHelper->GetJobElTest($jobId) ) {
			# Create jopb dir
			mkdir( JobHelper->GetJobElTest($jobId) ) or die "Can't create dir: " . JobHelper->GetJobElTest($jobId) . $_;
		}
	}

	my $ipcPath = EnumsPaths->Client_ELTESTS . $jobId . "t\\" . $jobId . "t.ipc";

	copy( $ipcPath, $path );
}

# If exist reoreder on Na priprave and export is server version AND et test not exist, copy opc to special folder
# Tests are taken from this folder by TPV
sub __CopyIPCToETStorage {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepToTest"};

	# move test to special ipc test folder if it is cerver script
	return 0 unless ( GeneralHelper->IsTPVServer() );

	# Test if el test exist
	my $path = JobHelper->GetJobElTest($jobId);

	my $elTestExist = 1;
	if ( -e $path ) {

		my @dirs = ();

		if ( opendir( DIR, $path ) ) {
			@dirs = readdir(DIR);
			closedir(DIR);
		}

		if ( scalar( grep { $_ =~ /^A[357]_/i } @dirs ) < 1 ) {

			$elTestExist = 0;
		}

	}
	else {
		$elTestExist = 0;
	}

	get_logger("abstractQueue")->error( "Et test $jobId exist: $elTestExist\n " . $inCAM->GetExceptionError() );

	if ( !( $elTestExist || $self->{"keepProfile"} ) ) {

		my $ipcPath = EnumsPaths->Client_ELTESTS . $jobId . "t\\" . $jobId . "t.ipc";
		if ( -e $ipcPath ) {

			copy( $ipcPath, EnumsPaths->Jobs_ELTESTSIPC . $jobId . "t.ipc" );
		}

		get_logger("abstractQueue")->error( "Et test $jobId copy from path $ipcPath\n " . $inCAM->GetExceptionError() );
	}
}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1;    # EtStep Created
	$totalCnt += 1;    # Et set createed
	$totalCnt += 1;    # Et optimize

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::ETExport::ETMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d222769";

	my $et = ETMngr->new( $inCAM, $jobId, "panel", 1, 1,1 );

	$et->Run()

}

1;

