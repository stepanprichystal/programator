
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::CheckGroup::CheckMngr;
use base('Packages::PoolMerge::PoolMngrBase');

use Class::Interface;
&implements('Packages::PoolMerge::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Managers::AbstractQueue::Enums' => "EnumsAbstrQ";
use aliased 'Programs::PoolMerge::Enums'     => "EnumsPool";
use aliased 'Helpers::FileHelper';
use aliased 'Packages::PoolMerge::CheckGroup::Helper::MasterJobHelper';
use aliased 'Packages::PoolMerge::CheckGroup::Helper::CheckHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $inCAM    = shift;
	my $poolInfo = shift;
	my $self     = $class->SUPER::new( $poolInfo->GetInfoFile(), @_ );
	bless $self;

	$self->{"inCAM"}    = $inCAM;
	$self->{"poolInfo"} = $poolInfo;

	$self->{"masterHelper"} = MasterJobHelper->new( $inCAM, $poolInfo );
	$self->{"checkHelper"} = CheckHelper->new( $inCAM, $poolInfo );

	return $self;
}

sub Run {
	my $self = shift;

	my @ordersInfo = $self->{"poolInfo"}->GetOrdersInfo();

	# 1) Choose master job
	my $masterJobRes = $self->_GetNewItem("Find master job");
	my $masterOrder  = undef;
	my $masterJob  = undef;
	my $mess         = "";

	unless ( $self->{"masterHelper"}->GetMasterJob(  \$masterOrder, \$masterJob, \$mess ) ) {

		$masterJobRes->AddError($mess);
	}
	else {

		$self->SetValInfoFile( "masterOrder", $masterOrder );
		$self->SetValInfoFile( "masterJob", $masterJob );
		
	}

	$self->_OnPoolItemResult($masterJobRes);
	
	
	
	# 7) Check if nif are ok
	my $childStatusRes = $self->_GetNewItem("Child job status");
	$mess           = "";
#
#	unless ( $self->{"checkHelper"}->CheckChildJobStatus(  $masterOrder, \$mess ) ) {
#
#		$childStatusRes->AddError($mess);
#	}

	$self->_OnPoolItemResult($childStatusRes);
	
		# 3) Check if jobs exist
	my $jobsExistRes = $self->_GetNewItem("Pool jobs exist");
	$mess         = "";

	unless ( $self->{"checkHelper"}->PoolJobsExist( \$mess ) ) {

		$jobsExistRes->AddError($mess);
	}
	
	$self->_OnPoolItemResult($jobsExistRes);
	
	# 3) Check if jobs exist
	my $jobsClosedRes = $self->_GetNewItem("Pool jobs closed");
	$mess         = "";

	unless ( $self->{"checkHelper"}->PoolJobsClosed( \$mess ) ) {

		$jobsClosedRes->AddError($mess);
	}
	
	$self->_OnPoolItemResult($jobsClosedRes);
	
	
	
	
	
    # Let "pool merger" know, master job was chosen
	# Then "pool merger" open it
	if ( defined $masterJob ) {

		$self->_OnSetMasterJob($masterJob);

	}
	else {
		die "Master job is not defined";
	}
	
	


	# 2) Check master job
	my $masterJobCheckRes = $self->_GetNewItem("Mater job checks");
	$mess    = "";

#	unless ( $self->{"masterHelper"}->CheckMasterJob(  $masterJob, \$mess ) ) {
#
#		$masterJobCheckRes->AddError($mess);
#	}

	$self->_OnPoolItemResult($masterJobCheckRes);

 



	# 4) Check if jobs o+1 step exist
	my $jobsContainStepRes = $self->_GetNewItem("Step o+1 exists");
	$mess               = "";

#	unless ( $self->{"checkHelper"}->JobsContainStep( \$mess ) ) {
#
#		$jobsContainStepRes->AddError($mess);
#	}

	$self->_OnPoolItemResult($jobsContainStepRes);

	# 5) Check pcb dimension are ok
	my $dimensionsRes = $self->_GetNewItem("Pcb dimensions");
	$mess          = "";

	unless ( $self->{"checkHelper"}->DimensionsAreOk( \$mess ) ) {

		$dimensionsRes->AddError($mess);
	}

	$self->_OnPoolItemResult($dimensionsRes);

	# 6) Check if nif are ok
	my $nifAreOkRes = $self->_GetNewItem("Nif control");
	$mess        = "";

	unless ( $self->{"checkHelper"}->CheckNifAreOk( \$mess ) ) {

		$nifAreOkRes->AddError($mess);
	}

	$self->_OnPoolItemResult($nifAreOkRes);



}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 7;    # controls
	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

