#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Compute duration of drilling and store results to: C:/Export/DrillDuration.txt
# Run in InCAM, put job ids separated with space as parameter
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Helpers::FileHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Packages::CAMJob::Drilling::DrillDuration::DrillDuration';
use aliased 'Packages::CAMJob::Routing::RoutDuration::RoutDuration';
use aliased 'Packages::Export::NCExport::ExportMngr::ExportPanelAllMngr';

use aliased 'Packages::CAMJob::Dim::JobDim';

my @jobs = ();
while ( my $j = shift ) {

	$j =~ s/\s//g;

	$j = lc($j);

	die "paremeter is not in job format: $j" if ( $j !~ /^\w\d+$/ );

	push( @jobs, $j );
}

print STDERR scalar(@jobs);

my $inCAM = InCAM->new();

my $res = "";

foreach my $jobId (@jobs) {

	my $wasOpened = 0;

	my $usr = "";
	if ( CamJob->IsJobOpen( $inCAM, $jobId, 1, \$usr ) ) {

		my $usrName = $ENV{USERNAME};
		if ( lc($usr) !~ /$usrName/i ) {

			print STDERR "Job: $jobId is open by  $usr\n";
			next;
		}
	}

	if ( CamJob->IsJobOpen( $inCAM, $jobId ) ) {

		$wasOpened = 1;
	}

	CamHelper->OpenJob( $inCAM, $jobId ) unless ($wasOpened);

	my $duration = __ComputeDuration($jobId);

	CamJob->CloseJob( $inCAM, $jobId ) unless ($wasOpened);

}

FileHelper->WriteString( 'c:/Export/DrillDuration.txt', $res );

sub __ComputeDuration {
	my $jobId = shift;
	my $str   = "";

	my $stepName = "panel";

	$res .= "\n======================================================================\n";
	$res .= "JOB = $jobId";
	$res .= "\n======================================================================\n\n";

	#:, duration = " . sprintf( "%02d:%02d:%02d", $duration / 3600, $duration / 60 % 60, $duration % 60 ) . "\n";

	my $materialName = HegMethods->GetMaterialKind($jobId);
	my $export       = ExportPanelAllMngr->new( $inCAM, $jobId, $stepName );
	my @opItems      = ();

	foreach my $opItem ( $export->GetOperationMngr()->GetOperationItems() ) {

		if ( defined $opItem->GetOperationGroup() ) {

			push( @opItems, $opItem );
			next;
		}

		if ( !defined $opItem->GetOperationGroup() ) {

			# unless operation definition is defined at least in one operations in group operation items
			# process this operation

			my $o = ( $opItem->GetOperations() )[0];

			my $isInGroup = scalar(
							   grep { $_->GetName() eq $o->GetName() }
							   map { $_->GetOperations() } grep { defined $_->GetOperationGroup() } $export->GetOperationMngr()->GetOperationItems()
			);

			push( @opItems, $opItem ) if ( !$isInGroup );
		}
	}

	my %multipl = JobDim->GetDimension( $inCAM, $jobId );    # multiple of panel

	foreach my $ncOper (@opItems) {

		$res .= "OPERACE: " . $ncOper->{"name"} . "\n";

		my $duration = 0;

		foreach my $l ( $ncOper->GetSortedLayers() ) {

			my $tDrill = DrillDuration->GetDrillDuration( $inCAM, $jobId, $stepName, $l->{"gROWname"} );

			# dill hole duration (include all nested steps and tool changes)
			$duration += $tDrill;

			# rout paths duration (include all nested steps and tool changes)
			my $tRout = RoutDuration->GetRoutDuration( $inCAM, $jobId, $stepName, $l->{"gROWname"} ) if ( $l->{"gROWlayer_type"} eq "rout" );
			$duration += $tRout;

			$res .=
			    "- Vrstva: "
			  . $l->{"gROWname"}
			  . ", doba: "
			  . sprintf("%.1f", ( $tDrill + $tRout ) / 60 )
			  . " ( vrtani: "
			  . sprintf("%.1f", ( $tDrill / 60 ))
			  . " [min], frezovani:"
			  . sprintf("%.1f", ( $tRout / 60 ))
			  . " [min])\n";

		}

		my $d = sprintf( "%02d:%02d:%02d", $duration / 3600, $duration / 60 % 60, $duration % 60 );

		$duration = $duration / $multipl{"nasobnost"};
		my $dj = sprintf( "%02d:%02d:%02d", $duration / 3600, $duration / 60 % 60, $duration % 60 );

		$res .= "Celkova doba:\n";
		$res .= "- cely panel: $d\n";
		$res .= "- JEDEN KUS : $dj\n\n";
	}

	return $str;

}
