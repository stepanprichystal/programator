
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::CheckGroup::CheckHelper;

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::NifFile::NifFile';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

sub PoolJobsExist {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @jobList = CamJob->GetJobList($inCAM);

	my @jobNames = $self->{"poolInfo"}->GetJobNames();

	foreach my $n (@jobNames) {

		my $exist = scalar( grep { $_ =~ /^$n$/i } @jobList );

		unless ($exist) {

			$result = 0;
			$$mess .= "Job \"" . $n . "\" doesn't exist in InCAM database. First, import the job";
		}
	}

	return $result;
}

sub JobsContainStep {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @jobNames = $self->{"poolInfo"}->GetJobNames();

	foreach my $n (@jobNames) {

		# check if exist step o+1
		unless ( CamHelper->StepExists( $inCAM, $n, "o+1" ) ) {

			$result = 0;
			$$mess .= "Job \"" . $n . "\" doesn't contain step \"o+1\". Repair job.";
		}
	}

	return $result;
}

sub DimensionsAreOk {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @orders = $self->{"poolInfo"}->GetOrdersInfo();

	foreach my $order (@orders) {

		my %lim = CamJob->GetProfileLimits2( $inCAM, $order->{"jobName"}, "o+1" );

		my $rW = abs( $lim{"xMax"} - $lim{"xMin"} );
		my $rH = abs( $lim{"yMax"} - $lim{"yMin"} );

		# compare width and height from pool file with real dim in job
		# tolerance 0.1mm

		if ( abs( $rW - $order->{"width"} ) > 0.1 || abs( $rH - $order->{"height"} ) > 0.1 ) {

			$result = 0;
			$$mess .=
			    "Pcb \""
			  . $order->{"jobName"}
			  . "\" real dimension ($rW x $rH) in InCAM doesn't match with pcb dimension in Helios ("
			  . $order->{"width"} . " x "
			  . $order->{"height"}
			  . "), step \"o+1\".\n";
			$$mess .= "Repair dimension in Helios and create \"pool panel\" again.";
		}
	}

	return $result;
}

# nif exist + values are ok
sub CheckNifAreOk {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @jobNames = $self->{"poolInfo"}->GetJobNames();

	foreach my $n (@jobNames) {

		my $nif = NifFile->new($n);

		unless ( $nif->Exist() ) {

			$result = 0;
			$$mess .= "Jobs \"nif file\" doesn't exist in archive. Job \"$n\". Repair it.\n";
		}
	}

	return $result;
}

sub CheckChildJobStatus {
	my $self        = shift;
	my $masterOrder = shift;
	my $mess        = shift;

	my @orderNames = $self->{"poolInfo"}->GetOrderNames();
	@orderNames = grep { $_ !~ /^$masterOrder/i } @orderNames;

	my $result = 1;

	# 1) check if child jobs has current step "k paneliyaci"
	foreach my $orderName (@orderNames) {

		my $curStep = HegMethods->GetCurStepOfOrder($orderName);

		if ( $curStep !~ /k panelizaci/i ) {
			$result = 0;
			$mess .= "Objednávka \"$orderName\" nemá nastavený sloupec \"Aktualni krok\" na hodnotu \"k panelizaci\". Aktuální hodnota je \"$curStep\". Oprav to.\n";
		}
	}

	# 2) check if child jobs has current state is  "Predvyrovni priprava"
	foreach my $orderName (@orderNames) {

		my $curState = HegMethods->GetStatusOfOrder($orderName);

		if ( $curState !~ /Predvyrobni priprava/i ) {
			$result = 0;
			$mess .=
			  "Objednávka \"$orderName\" nemá nastavený sloupec \"Stav\" na hodnotu \"Předvýrobní příprava\". Aktuální hodnota je \"$curState\". Oprav to.\n";
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

