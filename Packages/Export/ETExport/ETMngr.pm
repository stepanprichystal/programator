
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ETExport::ETMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use Log::Log4perl qw(get_logger :levels);

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
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
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"stepToTest"}   = shift;    #step, which will be tested
	$self->{"createEtStep"} = shift;    #step, which will be tested

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

	$self->{"exportIPC"}->Export();

	# Copy created IPC to server where are ipc stored
	$self->__CopyIPCToETServer();

	# Copy IPC to R: where IPC will be taken by random TPV user to processing (temporary solution for reorders)
	$self->__CopyIPCToServer();

}

# Copy created IPC to server where are prepared electrical test for machines
# Usefull when ET program is not already prepared and operator has to prepare program itself.
sub __CopyIPCToETServer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepToTest"};

	# reorder
	my $orderNum = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );

	# Test if el test exist
	my $path = JobHelper->GetJobElTest($jobId) . "\\" . $jobId . "t.ipc";

	my $elTestExist = 1;
	unless ( -e $path ) {

		unless ( -e JobHelper->GetJobElTest($jobId) ) {
			mkdir( JobHelper->GetJobElTest($jobId) ) or die "Can't create dir: " . JobHelper->GetJobElTest($jobId) . $_;
		}

		my $ipcPath = EnumsPaths->Client_ELTESTS . $jobId . "t\\" . $jobId . "t.ipc";

		copy( $ipcPath, $path );

	}
}

# If exist reoreder on Na priprave and export is server version AND et test not exist, copy opc to special folder
# Tests are taken from this folder by TPV
sub __CopyIPCToServer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"stepToTest"};

	# reorder
	my $orderNum = HegMethods->GetPcbOrderNumber( $self->{"jobId"} );

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

	# copy test to special ipc test folder
	if ( GeneralHelper->IsTPVServer() && $orderNum > 1 && $elTestExist == 0 ) {

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

}

1;

