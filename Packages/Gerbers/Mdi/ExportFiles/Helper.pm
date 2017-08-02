
#-------------------------------------------------------------------------------------------#
# Description: Helper for exporting MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::Mdi::ExportFiles::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Enums';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
# Return layer types which should be exported by default
sub GetDefaultLayerTypes {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my %mdiInfo = ();

	my @layers = CamJob->GetAllLayers( $inCAM, $jobId );

	my $signal = scalar( grep { $_->{"gROWname"} eq "c" } @layers );

	if ( HegMethods->GetTypeOfPcb($jobId) eq "Neplatovany" ) {
		$signal = 0;
	}

	$mdiInfo{ Enums->Type_SIGNAL } = $signal;

	if ( scalar( grep { $_->{"gROWname"} =~ /m[cs]/ } @layers ) ) # && CamJob->GetJobPcbClass( $inCAM, $jobId ) >= 8 
	{
		$mdiInfo{ Enums->Type_MASK } = 1;
	}
	else {
		$mdiInfo{ Enums->Type_MASK } = 0;
	}

	$mdiInfo{ Enums->Type_PLUG } =
	  scalar( grep { $_->{"gROWname"} =~ /plg[cs]/ } @layers ) ? 1 : 0;
	$mdiInfo{ Enums->Type_GOLD } =
	  scalar( grep { $_->{"gROWname"} =~ /gold[cs]/ } @layers ) ? 1 : 0;

	return %mdiInfo;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Gerbers::Mdi::ExportFiles::Helper';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "f52457";
	my $stepName = "panel";

	my %types = Helper->GetDefaultLayerTypes( $inCAM, $jobId);

	 print %types;
}

1;

