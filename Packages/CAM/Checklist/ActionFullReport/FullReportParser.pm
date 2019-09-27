
#-------------------------------------------------------------------------------------------#
# Description: Represent category of parser action InCAM report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionFullReport::FullReportParser;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsChecklist';
use aliased 'CamHelpers::CamChecklist';
use aliased 'Packages::CAM::Checklist::ActionFullReport::ActionFullReport';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"step"}      = shift;
	$self->{"checklist"} = shift;
	$self->{"action"}    = shift;

	return $self;
}

sub ParseReport {
	my $self = shift;

	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};
	my $step      = $self->{"step"};
	my $checklist = $self->{"checklist"};
	my $action    = $self->{"action"};

	my $category = shift;    # category keys (Enums::EnumsChecklist->Cat_xxx)
	my $layer    = shift;    # layer name
	my $severity = shift;    # array of severity indicators (Enums::EnumsChecklist->Sev_xxx)

	die "Checklist:" . $self->{"checklist"} . "doesn't esists"
	  unless ( CamChecklist->ChecklistExists( $inCAM, $jobId, $step, $checklist ) );

	my $actionStatus = CamChecklist->ChecklistActionStatus( $inCAM, $jobId, $step, $checklist, $action, );
	die "Checklist action is not in status: DONE. Current status: $actionStatus" unless ( $actionStatus eq EnumsChecklist->Status_DONE );

	my $file = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	CamChecklist->OutputActionFullReport( $inCAM, $jobId, $step, $checklist, $action, $file, $category, $layer, $severity );

	my @lines = @{ FileHelper->ReadAsLines($file) };

	unlink($file) or die $_;

	my $dt = CamChecklist->GetChecklistActionTime( $inCAM, $jobId, $step, $checklist, $action );
	my $ERF = CamChecklist->GetChecklistActionERF( $inCAM, $jobId, $step, $checklist, $action ); 
	

	my $report = ActionFullReport->new( $checklist, $action, $dt, $ERF );

	my $curCategory = undef;

	my $lineReg = qr{^(\w+)\s+                     # category
					  (\w+\d*)\s+                  # layer name
					  (.*)\s+                         # value - ddistance or dimensions
					  (micron)\s+                  # units
					  (.*)\s+                       # symbols definition (symbol1 + symbol2)
					  (RC|LN|SG)\s                 # type of measurement difinition
					  ((\d+\.?\d*\s){1,5})         # measurement definition
					  \w?\s*                       # if measure type LN, some extra parameter
					  (\d)+\s					   # occurence count ?
					  ([GYRB])\s                   # severity of measure
					  \d+                          # index
	                 }x;

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		next if ( $l =~ /^[\t\s]$/ );
		
		if ( $l =~ m/$lineReg/ ) {

			my $catKey     = $1;
			my $layer      = $2;
			my $value      = $3;
			my $units      = $4;
			my $symbolsStr = $5;
			my $defType    = $6;
			my $defMeasStr = $7;
			my $severity   = $10;

			# parse symbols
			my @symbols = split( /\s/, $symbolsStr );
			my $symbol1 = $symbols[0];
			my $symbol2 = $symbols[1] if ( defined $symbols[1] );

			# parse positions
			my @defMeas = split( /\s/, $defMeasStr );

			my ( $p1, $p2, $e1, $e2 ) = undef;

			if ( $defType eq "SG" ) {
				$p1 = { "x" => $defMeas[0], "y" => $defMeas[1] };
				$p2 = { "x" => $defMeas[2], "y" => $defMeas[3] };
			}
			elsif ( $defType eq "RC" ) {
				$p1 = { "x" => $defMeas[0], "y" => $defMeas[1] };
				$e1 = $defMeas[2];
				$e2 = $defMeas[3];
			}
			elsif ( $defType eq "LN" ) {
				$p1 = { "x" => $defMeas[0], "y" => $defMeas[1] };
				$p2 = { "x" => $defMeas[2], "y" => $defMeas[3] };
				$e1 = $defMeas[4];
			}

			$curCategory = $report->GetCategory($catKey);

			unless ( defined $curCategory ) {

				
				$curCategory = $report->AddCategory($catKey, EnumsChecklist->GetCatTitle($catKey));
			}

			$curCategory->AddActionCatVal( $layer, $value, $symbol1, $symbol2, $defType, $p1, $p2, $e1, $e2, $severity );

		}

	}

	return $report;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

