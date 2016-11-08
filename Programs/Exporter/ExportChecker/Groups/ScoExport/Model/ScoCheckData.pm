
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ScoExport::Model::ScoCheckData;



#3th party library
use strict;
use warnings;
use File::Copy;

#local library
#use aliased 'CamHelpers::CamLayer';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'CamHelpers::CamHelper';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}


sub OnCheckGroupData{
	my $self = shift;
	my $dataMngr = shift;	

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $groupData = $dataMngr->GetGroupData();
	
	# Check of coe thick
	
	my $thick = $groupData->GetCoreThick();
	
	if(!defined || $thick <= 0){
		
		$dataMngr->_AddErrorResult( "Tlouška zùstatku dps po drážkování je nulová nebo není definovaná.");
	}
	 

	 
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

