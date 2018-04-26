#!/usr/bin/perl-w 

use strict;
use warnings;

use Tk;
use Tk::LabFrame;
use Tk::BrowseEntry;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::InCAM::InCAM';

use aliased 'Enums::EnumsProducPanel';
use aliased 'Packages::ProductionPanel::PanelDimension';
use aliased 'Packages::ProductionPanel::MergePoolPcb';
use aliased 'Packages::ProductionPanel::MergeHelper::CountHelper';
use aliased 'Packages::ProductionPanel::MergeHelper::MergePoolHelper';

my $inCAM = InCAM->new();




my $fileName = MergePoolPcb->GUImerge1();

my %getXmlHash = CountHelper->GetCountJobsInFile($fileName);

( my $proposalOrder, my $maska01, my $konstTrida ) = MergePoolPcb->GetMasterJob( keys $getXmlHash{'order'} );

my @listOrderWithTerms = _AddTermToList( keys $getXmlHash{'order'} );

my $masterOrder = MergePoolPcb->GUImerge2( $fileName, $proposalOrder, @listOrderWithTerms );

MergePoolHelper->CopyJobToMaster( $inCAM, $masterOrder, keys $getXmlHash{'pcb'} );

( my $jobName ) = $masterOrder =~ /([DdFf]\d{6,})/;

my $panelSize = PanelDimension->GetPanelName($inCAM, $jobName, $fileName);


$inCAM->COM(
	'script_run',
	name    => "//incam/incam_server/site_data/scripts/PaneliseScript.pl",
	dirmode => 'global',
	params  => "$jobName $fileName $konstTrida $maska01 csv $panelSize"
);


###########################################################################################################
# LOCAL SUBROUTINE
###########################################################################################################



sub _AddTermToList {
	my @orderList = @_;
	my @newList   = ();
	foreach my $key (@orderList) {
		my @termin = split /\s/, HegMethods->GetTermOfOrder($key);
		push @newList,, "$key       $termin[0]";
	}
	return (@newList);
}

