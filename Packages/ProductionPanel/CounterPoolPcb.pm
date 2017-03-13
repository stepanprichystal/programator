
#-------------------------------------------------------------------------------------------#
# Description:
# Author:RVI
#-------------------------------------------------------------------------------------------#
use warnings;
use strict;

package Packages::ProductionPanel::CounterPoolPcb;

use POSIX qw(mktime);
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::MessageMngr';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Count of order on the panel
#
sub GetCountOfOrder {
	my $self  = shift;
	my $inCAM = shift;
	my $file  = shift;
	my $jobId = shift;

	my %panelHash = _GetCountOfPcb( $inCAM, $jobId );

	my %getXmlHash = _CountOfFile($file);

	foreach my $key ( keys $getXmlHash{'pcb'} ) {

		#print "aaaaaaaaaa $key\n";

		my $rest = $panelHash{$key} - $getXmlHash{'pcb'}->{$key};
		if ( $rest > 0 ) {
			for my $item ( keys $getXmlHash{'order'} ) {
				if ( $item =~ /$key/ ) {
					$getXmlHash{'order'}->{$item} += $rest;
					last;
				}
			}
		}
		elsif ( $rest < 0 ) {
			for my $item ( keys $getXmlHash{'order'} ) {
				if ( $item =~ /$key/ ) {
					$getXmlHash{'order'}->{$item} += $rest;
					last;
				}
			}

		}
	}

	# Here make file with all information for Helios
	_CreatePoolFile( $jobId, %getXmlHash );

	return ();
}

sub GetMasterJob {
	my $self  = shift;
	my @orderList = @_;
	my $maska01   = _GetMaska01(@orderList);
	my %hashJobs  = ();
	my $itemJob = 0; 
	
	foreach my $numOrder (@orderList) {

		if ( length($numOrder) > 6 ) {
			$itemJob = substr $numOrder, 0, 6;
		}

		my @arrTmp = HegMethods->GetAllByPcbId("$itemJob");
		my $termin = _GetNumberOfTerm( HegMethods->GetTermOfOrder($numOrder) );

		$hashJobs{$numOrder} = {
			'termin'       => $termin,
			'konstr_trida' => $arrTmp[0]->{'construction_class'}
		};
	}

	my @tmpPole = (
		sort { $hashJobs{$a}{'termin'} <=> $hashJobs{$b}{'termin'} }
		  keys %hashJobs
	);

	if ( _CheckMasterReady( $tmpPole[0] ) ) {
		return ( $tmpPole[0], $maska01 );
	}
	else { # v pripade neuspechu otestuji dalsi zakazku v poradi na stejne datum
		if ( _CheckMasterReady( $tmpPole[1] )
			and $hashJobs{ $tmpPole[1] }{'termin'} eq
			$hashJobs{ $tmpPole[0] }{'termin'} )
		{
			return ( $tmpPole[1], $maska01 );
		}
		else {
			my @mess = 'Nelze vybrat MASTER zakázku.
S nejbližším termínem je již ve výrobì jako MASTER a další zakázky nemají stejný termín. Vyøeš situaci na obchodì, zmìnou termínu nebo novým èíslem pro MASTERA';

			my $messMngr = MessageMngr->new('MASTER');
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION,
				\@mess );

			exit;
		}
	}
}



###########################################################################################################
# LOCAL SUBROUTINE
###########################################################################################################
sub _GetMaska01 {
	my @orderList = @_;
	my $res       = 0;

	foreach my $itemJob (@orderList) {

		if ( length($itemJob) > 6 ) {
			$itemJob = substr $itemJob, 0, 6;
		}

		my @arrTmp    = HegMethods->GetAllByPcbId("$itemJob");
		my $outputDir = $arrTmp[0]->{'archiv'};
		$outputDir =~ s/\\/\//g;

		open( AREA, "$outputDir/$itemJob.nif" );
		while (<AREA>) {
			if ( $_ =~ /rel\(22305,L\)=2814075/ ) {
				$res = 1;
			}
		}
		close AREA;
	}
	return ($res);
}

sub _GetNumberOfTerm {
	my $termin = shift;

	my @splitDatumTime = split /\s/, $termin;
	my @termPole       = split /\-/, $splitDatumTime[0];
	my $hourTERM  = 12;                    # termin je pocitan do 12 hod.
	my $yearTERM  = $termPole[0] - 1900;
	my $mountTERM = $termPole[1] - 1;
	my $dayTERM   = $termPole[2];

	my $unixtimeTERM =
	  mktime( 0, 0, $hourTERM, $dayTERM, $mountTERM, $yearTERM, 0, 0 );

	return ($unixtimeTERM);
}

sub _CheckMasterReady {
	my $orderId = shift;
	my $res     = 1;
	my $itemJob = 0;

	if ( length($orderId) > 6 ) {
		$itemJob = substr $orderId, 0, 6;
	}

	my $lastOrderNum = HegMethods->GetNumberOrder($itemJob);

	my ($sufixNum) = $lastOrderNum =~ /\-(\d{2})/;

	for ( my $i = 1 ; $i <= $sufixNum ; $i++ ) {
		$i = sprintf( "%02d", $i );

		my $orderName = $itemJob . '-' . $i;

		if ( HegMethods->GetStatusOfOrder($orderName) eq 'Ve vyrobe' ) {
			if ( HegMethods->GetInfMasterSlave($orderName) eq 'M' ) {
				$res = 0;
			}
		}
	}

	return ($res);
}


sub _CreatePoolFile {
	my $jobId               = shift;
	my (%completeInfoPanel) = @_;
	my $masterPool          = 0;


	my @pole      = HegMethods->GetAllByPcbId("$jobId");
	my $outputDir = $pole[0]->{'archiv'};
	$outputDir =~ s/\\/\//g;

	push( my @joblist, keys $completeInfoPanel{'order'} );

	foreach my $itemTemp (@joblist) {
		__WriteStavHelios($itemTemp);
	}

	foreach my $itemTemp (@joblist) {
		if ( $itemTemp =~ /$jobId/ ) {
			$masterPool = $itemTemp;
			last;
		}
	}

	@joblist = grep { $_ !~ /$masterPool/ } @joblist;

	open( POOLFILE, ">$outputDir/$jobId.pool" );
	print POOLFILE "[POOL]\n";
	print POOLFILE "master = $masterPool\n";
	$" = ",";
	print POOLFILE "slaves = @joblist";
	print POOLFILE "\n\n";
	while ( my ( $job, $nas ) = each( $completeInfoPanel{'order'} ) ) {
		print POOLFILE "[$job]\n";
		print POOLFILE "nasobnost = $nas\n\n";
	}
	close POOLFILE;

}

sub _CountOfFile {
	my $inputFile  = shift;
	my %returnHash = ();

	if ( $inputFile =~ /\.[Xx][Mm][Ll]$/ ) {
		%returnHash = __XMLfile($inputFile);
	}
	else {
		%returnHash = __CSVfile($inputFile);
	}

	return (%returnHash);
}

sub _GetCountOfPcb {
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

# Write status "slouceno" to Helios
sub __WriteStavHelios {
	my $orderId = shift;
	my $state   = 'slouceno';

	require Connectors::HeliosConnector::HelperWriter;

	my $res =
	  Connectors::HeliosConnector::HelperWriter->OnlineWrite_order( "$orderId",
		$state, "aktualni_krok" );

	return $res;

}

sub __XMLfile {
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

sub __CSVfile {
	my $csvFile       = shift;
	my %getCSVHashtmp = ();

	open( CSV, "$csvFile" );
	while (<CSV>) {
		if ( $_ =~ /([FfDd]\d{5}-\d{2})/ ) {
			my $jobItem = $1;
			$getCSVHashtmp{'order'}->{ lc $jobItem } += 1;

			my $jobId = lc substr $jobItem, 0, 6;
			$getCSVHashtmp{'pcb'}->{$jobId} += 1;
		}
	}
	close CSV;

	return (%getCSVHashtmp);
}

1;

