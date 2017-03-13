#-------------------------------------------------------------------------------------------#
# Description: Helper module for counting of job in panel | csv | xml
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::ProductionPanel::MergeHelper::CountHelper;

#3th party library
use strict;
use warnings;




#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub GetCountJobsInFile {
	my $self  = shift;
	my $inputFile  = shift;
	my %returnHash = ();

	if ( $inputFile =~ /\.[Xx][Mm][Ll]$/ ) {
		%returnHash = _XMLfile($inputFile);
	}
	else {
		%returnHash = _CSVfile($inputFile);
	}

	return (%returnHash);
}


sub GetCountJobsOnPanel {
	my $self  = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepPanel  = 'panel';
	my %pcdOnPanel = ();

	$inCAM->COM( 'set_subsystem', name => 'Panel-Design' );
	$inCAM->COM( 'set_step',      name => $stepPanel );

	$inCAM->INFO(
		entity_type => 'step',
		entity_path => "$jobId/$stepPanel",
		data_type   => 'SR'
	);
	my @usedStepstmp = @{ $inCAM->{doinfo}{gSRstep} };
	my @usedStepX    = @{ $inCAM->{doinfo}{gSRnx} };
	my @usedStepY    = @{ $inCAM->{doinfo}{gSRny} };

	my $count = 0;
	foreach my $itemStep (@usedStepstmp) {
		unless ( $itemStep =~ /coupon/ ) {
			if ( $itemStep eq 'o+1' ) {
				$itemStep = $jobId;
			}

			my $nasobnostXY = ( $usedStepX[$count] * $usedStepY[$count] );
			$pcdOnPanel{"$itemStep"} += $nasobnostXY;

			$count++;
		}
	}
	return (%pcdOnPanel);
}

sub _XMLfile {
	my $xmlFile       = shift;
	my %getXmlHashtmp = ();

	use XML::Simple;
	use Data::Dumper;

	my $getStructure = XMLin("$xmlFile");
	my $countOfItem  = ( scalar @{ $getStructure->{order} } ) - 1;

	for ( my $count = 0 ; $count <= $countOfItem ; $count++ ) {

		$getXmlHashtmp{'order'}
		  ->{ lc $getStructure->{order}->[$count]->{order_id} } += 1;

		$getXmlHashtmp{'pcb'}
		  ->{ lc substr( $getStructure->{order}->[$count]->{order_id}, 0, 6 ) }
		  += 1;
	}
	return (%getXmlHashtmp);

}

sub _CSVfile {
	my $csvFile       = shift;
	my %getCSVHashtmp = ();

	open( CSV, "$csvFile" );
	while (<CSV>) {
		if ( $_ =~ /([FfDd]\d{5,}-\d{2})/ ) {
			my $jobItem = $1;
			$getCSVHashtmp{'order'}->{ lc $jobItem } += 1;

			my $jobId = lc substr $jobItem, 0, 6;
			$getCSVHashtmp{'pcb'}->{$jobId} += 1;
		}
	}
	close CSV;

	return (%getCSVHashtmp);
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#


1;