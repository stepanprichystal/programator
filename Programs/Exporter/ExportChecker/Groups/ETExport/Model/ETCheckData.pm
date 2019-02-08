
#-------------------------------------------------------------------------------------------#
# Description: This class is responsible for:
# - Checking group data before final export. Handler: OnCheckGroupData
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::ETExport::Model::ETCheckData;

#3th party library
use strict;
use warnings;
use File::Copy;

#local library
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamStepRepeatPnl';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;    # Return the reference to the hash.
}

sub OnCheckGroupData {
	my $self     = shift;
	my $dataMngr = shift;

	my $inCAM    = $dataMngr->{"inCAM"};
	my $jobId    = $dataMngr->{"jobId"};
	my $stepName = "panel";

	# 1) check attribute .n_electric (it can appear in odb data)

	my @steps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId );
	my @l = ("c");
	push( @l, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	my $impPresent = 0;
	foreach my $step (@steps) {

		foreach my $l (@l) {
			my %attHist = CamHistogram->GetAttHistogram( $inCAM, $jobId, $step, $l, 1 );

			if ( $attHist{".n_electric"} ) {

				$dataMngr->_AddWarningResult(
											  "Attribute",
											  "Ve stepu: $step, vrstvì: \"$l\" nìkteré features obsahují atribut \".n_electric\"."
												. "Plošky s tímto atributem se nebudou elektricky testovat, je to ok?"
				);
				next;
			}
		}
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

