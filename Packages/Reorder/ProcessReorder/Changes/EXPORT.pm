#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ProcessReorder::Changes::EXPORT;
use base('Packages::Reorder::ProcessReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ProcessReorder::Changes::IChange');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Managers::AsyncJobMngr::Enums' => "EnumsJobMngr";

use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Unit::Helper' => "UnitHelper";

use aliased 'Programs::Exporter::ExportUtility::DataTransfer::DataTransfer';
use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::DataTransfer::Enums' => 'EnumsTransfer';
use aliased 'Programs::Exporter::ExportChecker::Enums'               => 'CheckerEnums';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Do export, only non pool pcb
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;
 
	if( $self->{"isPool"}){
		return $result;
	}
 
	if ( $self->__CheckBeforeExport($mess) ) {

		unless ( $self->__PrepareExportFile($mess) ) {
			$result = 0;
		}
	}
	else {

		$result = 0;
	}

	return $result;

}

sub __CheckBeforeExport {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"units"} = UnitHelper->PrepareUnits($inCAM, $jobId);

	my @activeOnUnits = grep { $_->GetGroupState() eq CheckerEnums->GroupState_ACTIVEON } @{ $self->{"units"}->{"units"} };

	foreach my $unit (@activeOnUnits) {

		my $resultMngr = -1;
		my $succes = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

		if ( $resultMngr->GetErrorsCnt() ) {

			$result = 0;
			$$mess .= $resultMngr->GetErrorsStr(1);
		}
	}
	
	return $result;
}
 

sub __PrepareExportFile {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $pathExportFile = EnumsPaths->Client_EXPORTFILES . $jobId;

	my $dataTransfer = DataTransfer->new( $jobId, EnumsTransfer->Mode_WRITE, $self->{"units"}, undef, $pathExportFile );

	my @orders = HegMethods->GetPcbOrderNumbers($jobId);

	$dataTransfer->SaveData( EnumsJobMngr->TaskMode_ASYNC, 1, undef, undef, \@orders );

	unless ( -e $pathExportFile ) {
		$$mess .= "Error during preparing \"export file\" for job $jobId";
		$result = 0;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ProcessReorder::Changes::EXPORT' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

