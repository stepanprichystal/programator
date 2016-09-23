
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCCheckData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Presenter::NifHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

# Checking group data before final export
# Errors, warnings are passed to <$dataMngr>
sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;    #instance of GroupDataMngr

	my $groupData = $dataMngr->GetGroupData();
	my $inCAM     = $dataMngr->{"inCAM"};
	my $jobId     = $dataMngr->{"jobId"};
	my $stepName  = "panel";


 
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

