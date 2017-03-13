
#-------------------------------------------------------------------------------------------#
# Description:
# Author:RVI
#-------------------------------------------------------------------------------------------#
use warnings;
use strict;

package Packages::ProductionPanel::MergePoolPcb;

use POSIX qw(mktime);
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::ProductionPanel::MergeHelper::CountHelper';


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

	my %panelHash = CountHelper -> GetCountJobsOnPanel( $inCAM, $jobId );

	my %getXmlHash = CountHelper -> GetCountJobsInFile($file);
								

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
# Return order able to be MASTER
sub GetMasterJob {
	my $self  = shift;
	my @orderList = @_;
	my $maska01   = _GetMaska01(@orderList);
	my $konstClass = 0;
	my %hashJobs  = ();
	
	foreach my $numOrder (@orderList) {

		(my $itemJob) = $numOrder =~ /([DdFf]\d{5,})/;

		my @arrTmp = HegMethods->GetAllByPcbId("$itemJob");
		my $termin = _GetNumberOfTerm( HegMethods->GetTermOfOrder($numOrder) );

		$hashJobs{$numOrder} = {
			'termin'       => $termin,
			'konstr_trida' => $arrTmp[0]->{'construction_class'}
		};
	}
	
	# tmpPole jsou jobs serazene dle terminu
	my @tmpPole = (
		sort { $hashJobs{$a}{'termin'} <=> $hashJobs{$b}{'termin'} }
		  keys %hashJobs
	);

	# tmpField jsou jobs sezazene dle konstrukcni tridy (od nejvyssi po nejnizssi)
	my @tmpField = (
		sort { $hashJobs{$b}{'konstr_trida'} <=> $hashJobs{$a}{'konstr_trida'} }
		  keys %hashJobs
	);
	
	$konstClass = $hashJobs{$tmpField[0]}{'konstr_trida'};
	
	if ( _CheckMasterReady( $tmpPole[0] ) ) {
		return ( $tmpPole[0], $maska01, $konstClass );
	}
	else { # v pripade neuspechu otestuji dalsi zakazku v poradi na stejne datum
		if ( _CheckMasterReady( $tmpPole[1] )
			and $hashJobs{ $tmpPole[1] }{'termin'} eq
			$hashJobs{ $tmpPole[0] }{'termin'} )
		{
			return ( $tmpPole[1], $maska01, $konstClass );
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

sub GUImerge1 {
	my $self  = shift;
	my $file;

	my $mainPool = MainWindow->new();
	$mainPool->title('pool servis - inport CSV / XML');

	my $csvFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $masterFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $midleFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $inportButton = $csvFrame->Button(
		-width => 82,
		-text  => "...import csv jobs...",
		-font  => 'normal 9 {bold }',

		-command => sub {
			my @types =
			  ( [ "jobs data", [qw/.xml csv/] ], [ "All files", '*' ] );

			$file = $mainPool->getOpenFile(
				-filetypes  => \@types,
				-initialdir => 'c:\Export'
			);

			$mainPool->destroy;
		}
	)->pack( -padx => 5, -pady => 5, -side => 'top' );

	my $infoFrame =
	  $mainPool->Frame( -width => 100, -height => 20, -bg => 'lightblue' )
	  ->pack( -side => 'bottom', -fill => 'x' );
	my $statusLabel = sprintf "inportuj CSV z GatemaOptimizer";
	my $status      = $infoFrame->Label(
		-textvariable => \$statusLabel,
		-bg           => 'lightblue',
		-font         => 'normal 9 {bold }'
	)->pack( -side => 'top' );

	$mainPool->MainLoop();

	if ($file) {
		return ($file);
	}
	else {
		exit;
	}
}

sub GUImerge2 {
	my $self  = shift;
	my $file        = shift;
	my $orderMaster = shift;
	my @orderList   = @_;
	my $clickButton = 0;

	my $mainPool = MainWindow->new();
	$mainPool->title('pool servis - inport CSV / XML');

	my $csvFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $masterFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $midleFrame = $mainPool->Frame( -width => 100, -height => 20 )
	  ->pack( -side => 'top', -fill => 'both' );
	my $button = $midleFrame->Button(
		-width   => 40,
		-text    => "OK",
		-command => sub { $clickButton = 1; $mainPool->destroy }
	)->pack( -padx => 5, -pady => 5, -side => 'right' );
	my $inportButton = $csvFrame->Button(
		-width => 82,
		-text  => "...nacteno... $file",
		-font  => 'normal 9 {bold }',
		-fg    => 'blue'
	)->pack( -padx => 5, -pady => 5, -side => 'top' );

	my $selectMaster = $masterFrame->BrowseEntry(
		-label    => "Master - Matka",
		-variable => \$orderMaster,
		-state    => "readonly",
		-width    => '15',
		-font     => 'normal 8 {bold }'
	)->pack( -padx => 10, -pady => 10, -side => 'top' );
	$selectMaster->insert( "end", @orderList );

	my $infoFrame =
	  $mainPool->Frame( -width => 100, -height => 20, -bg => 'lightblue' )
	  ->pack( -side => 'bottom', -fill => 'x' );
	my $statusLabel = sprintf "Master - matka vybrana = $orderMaster";
	my $status      = $infoFrame->Label(
		-textvariable => \$statusLabel,
		-bg           => 'lightblue',
		-font         => 'normal 9 {bold }'
	)->pack( -side => 'top' );

	$mainPool->MainLoop();

	( my $returnMaster ) = $orderMaster =~ /([FfDd]\d{5,}-\d{2})/;
	if ($clickButton) {
		return ($returnMaster);
	}
	else {
		exit;
	}

}





###########################################################################################################
# LOCAL SUBROUTINE
###########################################################################################################
sub _GetMaska01 {
	my @orderList = @_;
	my $res       = 0;

	foreach my $itemJob (@orderList) {

		($itemJob) = $itemJob =~ /([DdFf]\d{5,})/;

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

	($itemJob) = $orderId =~ /([DdFf]\d{5,})/;

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

1;

