
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PlotExport::Model::PlotCheckData;

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

	my @layers = @{ $groupData->GetLayers() };

	foreach my $lInfo (@layers) {

		# Check if layers has set polarity
		unless ( defined $lInfo->{"polarity"} ) {
			$dataMngr->_AddErrorResult( "Board layer", "Layer " . $lInfo->{"name"} . " doesn't have set polarity." );
		}

		# Check if layers has set mirror
		unless ( defined $lInfo->{"mirror"} ) {
			$dataMngr->_AddErrorResult( "Board layer", "Layer " . $lInfo->{"name"} . " doesn't have set mirror." );
		}

		# Check if layers has set compensation
		unless ( defined $lInfo->{"comp"} ) {
			$dataMngr->_AddErrorResult( "Board layer","Layer " . $lInfo->{"name"} . " doesn't have set comp." );
		}
		
	}
	
	# Test if some compensation are not a number
	my @wrongComp = grep {$_->{"comp"} !~ (/^-?\d+$/) } @layers;
	if(@wrongComp){
		
		my $str = join("; ", map { "\"".$_->{"name"}."\" = ".$_->{"comp"} } @wrongComp);
		
		$dataMngr->_AddErrorResult( "Layer compensation", "Some layers has wrong compensation: $str");
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

