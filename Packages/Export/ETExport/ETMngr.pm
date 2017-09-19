
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

use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
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
	
	$self->{"exportIPC"} = ExportIPC->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"stepToTest"}, $self->{"createEtStep"}  );	
	$self->{"exportIPC"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );
	 

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	$self->{"exportIPC"}->Export();
	
	# Temporary solution
	$self->__CopyIPCTemp();
	
}
 
 
 # If exist reoreder on Na priprave and export is server version AND et test not exist, copy opc to special folder
sub __CopyIPCTemp{
	my $self = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	

 	
	# reorder
	my $orderNum = HegMethods->GetPcbOrderNumber($self->{"jobId"}); 
	 
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
	
	
	get_logger("abstractQueue")->error( "Et test $jobId exist: $elTestExist\n ". $inCAM->GetExceptionError() );
	
	# copy test to special ipc test folder
	if( AsyncHelper->ServerVersion() && $orderNum > 1 && $elTestExist ==0){
	
		
		my $ipcPath = EnumsPaths->Client_ELTESTS.$jobId."t\\".$jobId."t.ipc";
		if(-e $ipcPath){
		
			copy($ipcPath, EnumsPaths->Jobs_ELTESTSIPC.$jobId."t.ipc" );	
		}
		
		get_logger("abstractQueue")->error( "Et test $jobId copy from path $ipcPath\n ". $inCAM->GetExceptionError() );
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

