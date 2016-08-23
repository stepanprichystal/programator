package Programs::Exporter::ExportUtility::Groups::AOIExport::AOIExportTmp;

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportUtility::Groups::AOIExport::AOIGroup';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Model::AOIGroupData';
use aliased 'Programs::Exporter::ExportChecker::Groups::AOIExport::Presenter::AOIUnit';
use aliased 'Managers::MessageMngr::MessageMngr';

#-------------------------------------------------------------------------------------------#
#  NC export, all layers, all machines..
#-------------------------------------------------------------------------------------------#

my $resultMess = "";
my $succes     = 1;

sub new {

	my $self = shift;
	$self = {};
	bless $self;
	return $self;
}

sub Run {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $stepToTest = shift;


	#GET INPUT NIF INFORMATION

	my $groupData = AOIGroupData->new();
	$groupData->SetStepToTest($stepToTest);

	my $unit = AOIUnit->new($jobId);
	
	$unit->InitDataMngr($inCAM, $groupData);
	
	my $resultMngr = -1;
	my $succ = $unit->CheckBeforeExport( $inCAM, \$resultMngr );

	# Check export data for errors
	unless ( $succ) {

		my @errors   = $resultMngr->GetErrors();
		my @warnings = $resultMngr->GetWarnings();

		#my @fail = $nifPreGroup->GetFailResults();
		my @fail = (@errors, @warnings);
		my $messMngr = MessageMngr->new($jobId);

		foreach my $resItem (@fail) {

			my @mess1 = ( $resItem->GetErrorStr() );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
		}

		return 0;
	}

	my %exportData = $unit->GetExportData($inCAM);

	my $group = AOIGroup->new( $inCAM, $jobId );
	$group->SetData( \%exportData );
	my $itemsCnt = $group->GetItemsCount();

	#my $builder = $group->GetResultBuilder();
	$group->{"onItemResult"}->Add( sub { Test(@_) } );

	$group->Run();

	print "\n========================== E X P O R T: " . $group->GetGroupId() . " ===============================\n";
	print $resultMess;
	print "\n========================== E X P O R T: "
	  . $group->GetGroupId()
	  . " - F I N I S H: "
	  . ( $succes ? "SUCCES" : "FAILURE" )
	  . " ===============================\n";

	sub Test {
		my $itemResult = shift;

		if ( $itemResult->Result() eq "failure" ) {
			$succes = 0;
		}

		$resultMess .= " \n=============== Export task result: ==============\n";
		$resultMess .= "Task: " . $itemResult->ItemId() . "\n";
		$resultMess .= "Task result: " . $itemResult->Result() . "\n";
		$resultMess .= "Task errors: \n" . $itemResult->GetErrorStr() . "\n";
		$resultMess .= "Task warnings: \n" . $itemResult->GetWarningStr() . "\n";
	}

	unless ($succes) {
		my $messMngr = MessageMngr->new($jobId);
		my @mess1 = ( "== EXPORT FAILURE === GROUP:  ".$group->GetGroupId()."\n".$resultMess);
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );
	}


	return $succes;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExportUtility::Groups::ETExport::ETExportTmp';

	my $jobId    = "f13610";
	my $stepName = "panel";
	my $inCAM    = InCAM->new();

	#GET INPUT NIF INFORMATION
	my $stepToTest = "panel";

}

1;

