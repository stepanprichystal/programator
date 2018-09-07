#-------------------------------------------------------------------------------------------#
# Description: Computing drill duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::RoutSpeed::RoutSpeed;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use POSIX qw(floor ceil);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Return duration of job/step/layer in second
# Consider Pilot holes
sub GetRoutSpeed {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layerName = shift;

	my %l = ( "gROWname" => $layerName );
	my @larr = ( \%l );
	CamDrilling->AddNCLayerType( \@larr );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@larr );

	# Signal layer cnt
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my $minTool = CamRouting->GetMinSlotTool( $inCAM, $jobId, $step, $l{"type"} );

	# Rout speed
	my %routSpeedTab        = $self->__ParseRoutSpeedTable("RoutSpeed.csv");
	my %routSpeedOutlineTab = $self->__ParseRoutSpeedTable("RoutSpeedOutline.csv");

	# Thickness of drilled material
	my $matThick;
	if ( $layerCnt <= 2 ) {

		$matThick = HegMethods->GetPcbMaterialThick($jobId);
	}
	else {
		my $stackup = Stackup->new($jobId);
		$matThick = $stackup->GetThickByLayerName( $l{"gROWdrl_start_name"} );
	}

	# Total panel cnt of order
	my $totlaPnlCnt = JobDim->GetTotalPruductPnlCnt( $inCAM, $jobId );

	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $packetType = $self->__GetPacketType();

	my %tSpeed = {};

	foreach my $t ( keys %routSpeedTab ) {

		$tSpeed{$t} = {
						"standard" => %routSpeedTab{$t}->[$packetType],
						"outline"  => %routSpeedOutlineTab{$t}->[$packetType]
		};

	}

	return %routSpeedTab

}

sub __GetPacketType {
	my $self           = shift;
	my $matThick       = shift;
	my %routSpeedTable = %{ shift(@_) };
	my $minTool        = shift;
	my $totlaPnlCnt    = shift;

	# Determine max possible paket height
	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $defPaketIdx;                          # max possible paket height for given layer
	my $realPaketIdx;

	for ( my $i = scalar(@paketThick) - 1 ; $i >= 0 ; $i-- ) {

		foreach my $tSize ( keys %routSpeedTable ) {

			if ( defined $routSpeedTable{$minTool}{$tSize} ) {
				$defPaketIdx = $i;
				last;
			}
		}
		last if ( defined $defPaketIdx );
	}

	my $pnlPerPacket;

	# find real paket height by total product panel
	my $totalOrderThick = $totlaPnlCnt * $matThick;

	# Order in one packet
	if ( $totalOrderThick < $paketThick[$defPaketIdx] ) {

		# search for minimal possible packet trashold height
		$realPaketIdx = $defPaketIdx;

		$pnlPerPacket = int( $totalOrderThick / $paketThick[$realPaketIdx] );
	}

	# Order in more packets
	else {

		# produc pnl count by default packet
		$pnlPerPacket = int( $totalOrderThick / $paketThick[$defPaketIdx] );

		# here is exception, if two packet,
		# try to split panels amount equally among theses two packets
		# in order get smaller height of packets and than heigher speed of rout

		if ( ceil( $totlaPnlCnt / $pnlPerPacket ) == 2 ) {

			$pnlPerPacket = ceil( $totlaPnlCnt / 2 );
		}
	}

	# search smallest packet treshold thockness
	for ( my $i = $defPaketIdx ; $i >= 0 ; $i-- ) {

		if ( $pnlPerPacket * $matThick < $paketThick[$defPaketIdx] ) {
			$realPaketIdx = $i;
		}
		else {
			last;
		}
	}

	return $realPaketIdx;

}

sub __ParseRoutSpeedTable {
	my $self = shift;
	my $file = shift;

	my $p = GeneralHelper->Root() . "\\Packages\\CAMJob\\Drilling\\RoutSpeed\\" . $file;

	my @lines = @{ FileHelper->ReadAsLines($p) };
	@lines = @lines[ 2 .. scalar(@lines) ];

	my %tools = ();

	foreach my $line (@lines) {
		my @vals = split( ";", $line );
		chomp(@vals);

		my $t         = shift @vals;
		my $pakThick1 = $vals[1] ne "-" ? $vals[1] : undef;
		my $pakThick2 = $vals[2] ne "-" ? $vals[2] : undef;
		my $pakThick3 = $vals[3] ne "-" ? $vals[3] : undef;

		$tools{$t} = \@vals;
	}

	return \%tools;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Drilling::DrillDuration::DrillDuration';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";
	my $step  = "panel";
	my $layer = "m";

	my $result = DrillDuration->GetDrillDuration( $inCAM, $jobId, $step, $layer );

	print STDERR "Result is: " . int( $result / 60 ) . ":" . sprintf( "%02s", $result % 60 ) . " error \n";

}

1;
