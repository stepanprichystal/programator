#-------------------------------------------------------------------------------------------#
# Description: Computing drill duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutSpeed::RoutSpeed;

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
sub GetRoutSpeedTable {
	my $self        = shift;
	my $matThick    = shift;    # µm
	my $minTool     = shift;    #µm
	my $totlaPnlCnt = shift;
	my $layers      = shift;

	# Rout speed
	my %routSpeedTab        = $self->__ParseRoutSpeedTable("RoutSpeed.csv");
	my %routSpeedOutlineTab = $self->__ParseRoutSpeedTable("RoutSpeedOutline.csv");

	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $packetType        = $self->__GetPacketType( $matThick, \%routSpeedTab,        $minTool, $totlaPnlCnt );
	my $packetTypeOutline = $self->__GetPacketType( $matThick, \%routSpeedOutlineTab, $minTool, $totlaPnlCnt );

	if(scalar(grep{$_->{"gROWname"} =~ /[rf]z[cs]/} @{$layers})){
		$packetType = 0;
		$packetTypeOutline = 0;
	}


	my %tSpeed = ();

	foreach my $t ( keys %routSpeedTab ) {

		$tSpeed{$t} = {
						"standard" => $routSpeedTab{$t}->[$packetType],
						"outline"  => $routSpeedOutlineTab{$t}->[$packetType]
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

	for ( my $i = scalar(@paketThick) - 1 ; $i >= 0 ; $i-- ) {

		die "Minimal slot tool: $minTool is not defined in \"RoutSpeedTable\"" unless ( defined $routSpeedTable{$minTool} );

		if ( defined $routSpeedTable{$minTool}->[$i] ) {
			$defPaketIdx = $i;
			last;
		}

		last if ( defined $defPaketIdx );
	}

	# find real paket height by total product panel
	my $totalOrderThick = $totlaPnlCnt * $matThick;

	# Order in one packet
	my $realPaketIdx = $defPaketIdx;

	# produc pnl thickness per packet
	#my $pnlPerPacketThick = int( $totalOrderThick / $paketThick[$defPaketIdx] );
	if ( $totalOrderThick < $paketThick[$defPaketIdx] ) {

		for ( my $i = $defPaketIdx ; $i >= 0 ; $i-- ) {

			if ( $totalOrderThick < $paketThick[$i] ) {
				$realPaketIdx = $i;
			}
			else {
				last;
			}
		}
	}
	else {
		my $pnlPerPacket = int( $paketThick[$defPaketIdx] / $matThick );

		if ( ceil( $totlaPnlCnt / $pnlPerPacket ) == 2 ) {

			$pnlPerPacket = ceil( $totlaPnlCnt / 2 );
		}

		# search smallest packet treshold thockness
		for ( my $i = $defPaketIdx ; $i >= 0 ; $i-- ) {

			if ( $pnlPerPacket * $matThick < $paketThick[$i] ) {
				$realPaketIdx = $i;
			}
			else {
				last;
			}
		}
	}

	# here is exception, if two packet,
	# try to split panels amount equally among theses two packets
	# in order get smaller height of packets and than heigher speed of rout

	return $realPaketIdx;

}

sub __ParseRoutSpeedTable {
	my $self = shift;
	my $file = shift;

	my $p = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutSpeed\\" . $file;

	my @lines = @{ FileHelper->ReadAsLines($p) };
	@lines = grep { defined $_ } @lines[ 2 .. scalar(@lines) ];

	my %tools = ();

	foreach my $line (@lines) {
		my @vals = split( ";", $line );
		chomp(@vals);

		my $t = int( ( shift @vals ) * 1000 );

		die "Wrong parsed tool size at $p" unless ($t);

		my $pakThick1 = $vals[0] eq "-" ? undef : $vals[0];
		my $pakThick2 = $vals[1] eq "-" ? undef : $vals[1];
		my $pakThick3 = $vals[2] eq "-" ? undef : $vals[2];

		$tools{$t} = [ $pakThick1, $pakThick2, $pakThick3 ];
	}

	return %tools;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';
	use aliased 'Packages::InCAM::InCAM';

	my $result = RoutSpeed->GetRoutSpeedTable( 1600, 1000, 8, ["f"] );

	print STDERR "Result is: $result";

}

1;
