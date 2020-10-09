
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for creation:
# - Export data, (from prepared group data), which will consume exporter utility. Handler: OnExportGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::Model::CommExportData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library

use aliased 'Enums::EnumsIS';
 
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::CommData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

# Export data, (from prepared group data), which will consume exporter utility
# are prepared in this method
sub OnExportGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();

	my $inCAM = $dataMngr->{"inCAM"};
	my $jobId = $dataMngr->{"jobId"};

	my $stepName = "panel";

	my $exportData = CommData->new();

	$exportData->SetChangeOrderStatus( $groupData->GetChangeOrderStatus() );
	
	my $status = $groupData->GetOrderStatus();
	if($status eq EnumsIS->CurStep_POSLANDOTAZ){
		
		my $login = getlogin();
		$status =~ s/<user>/$login/;
	}
 
	
	$exportData->SetOrderStatus( $status );
	$exportData->SetExportEmail( $groupData->GetExportEmail() );
	$exportData->SetEmailAction( $groupData->GetEmailAction() );
	$exportData->SetEmailToAddress( $groupData->GetEmailToAddress() );
	$exportData->SetEmailCCAddress( $groupData->GetEmailCCAddress() );
	$exportData->SetEmailSubject( $groupData->GetEmailSubject() );
	$exportData->SetEmailIntro( $groupData->GetEmailIntro() );
	$exportData->SetIncludeOfferInf( $groupData->GetIncludeOfferInf() );
	$exportData->SetIncludeOfferStckp( $groupData->GetIncludeOfferStckp() );
	$exportData->SetClearComments( $groupData->GetClearComments() );

	return $exportData;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

