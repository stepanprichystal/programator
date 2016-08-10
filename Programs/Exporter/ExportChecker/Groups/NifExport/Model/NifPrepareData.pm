
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for prepare:
# - default "dataset" (groupData) for displaying them in GUI. Handler: OnPrepareGroupData
# - decide, if group will be active in GUI. Handler: OnIsGroupAllowed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifPrepareData;


#3th party library
use strict;
use warnings;


#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifGroupData';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# This method decide, if group will be "active"
# This if will be enabled in GUI
sub OnIsGroupAllowed{
	my $self = shift;
	my $dataMngr = shift;	#instance of GroupDataMngr
 
 
 
	return 0;

}

# Default "group data" are prepared in this method
sub OnPrepareGroupData{
	my $self = shift;
	my $dataMngr = shift;	#instance of GroupDataMngr
	
	
	my $groupData = NifGroupData->new();
	$groupData->SetNotes("poznamka test");
	$groupData->SetTenting(0);
	$groupData->SetPressfit(1);
	$groupData->SetMaska01(0);
	$groupData->SetDatacode("mc");
	
	return $groupData;
	
 
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

