#-------------------------------------------------------------------------------------------#
# Description: Fill rout speed to NC programs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutSpeed::RoutSpeed;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use POSIX qw(floor ceil);
use Path::Tiny qw(path);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::CAMJob::Routing::RoutDuplicated::RoutDuplicated';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::TifFile::TifNCOperations';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Complete rout speed to exported NC files
sub CompleteRoutSpeed {
	my $self        = shift;
	my $jobId       = shift;
	my $totalPnlCnt = shift;
	my $errMess     = shift;

	my $result = 1;

	my $ncPath = JobHelper->GetJobArchive($jobId) . "nc\\";

	my $tif = TifNCOperations->new($jobId);

	return 0 unless ( $tif->TifFileExist() );

	# Only operation which contain rout layer

	my @ncOperations = grep { $_->{"isRout"} } $tif->GetNCOperations();

	foreach my $ncOper (@ncOperations) {

		my %routSpeedTab = $self->__GetRoutSpeedTable( $ncOper->{"ncMatThick"}, $ncOper->{"minSlotTool"}, $totalPnlCnt, $ncOper->{"layers"} );

		next unless ( $ncOper->{"isRout"} );

		foreach my $m ( keys %{ $ncOper->{"machines"} } ) {

			my $ncFile = $ncPath . $jobId . "_" . $ncOper->{"opName"} . "." . $m;

			die "NCFile doesn't exist $ncFile" unless ( -e $ncFile );

			my $file = path($ncFile);

			my $data = $file->slurp_utf8;

			foreach my $toolKey ( keys %{ $ncOper->{"machines"}->{$m} } ) {

				my $t = $ncOper->{"machines"}->{$m}->{$toolKey};

				my $speed = $self->__GetRoutSpeed( $t->{"drillSize"}, $t->{"isOutline"}, $t->{"isDuplicate"}, \%routSpeedTab );

				die "No speed defined for tool size: " . $t->{"drillSize"} . ", key: $toolKey" unless defined($speed);

				$data =~ s/\(F_$toolKey\)/F$speed/i;
			}

			# Do final check if all keys (F_<guid>) was replaced by speed
			if ( $data =~ /\(F_[\w-]+\)/i ) {

				$data =~ s/\(F_[\w-]+\)/\(F_not_defined)/ig;
				$result = 0;
				$$errMess .= "NC operation: $ncOper, machine: $m, speed is not defined.\n";
			}

			$file->spew_utf8($data);

		}
	}

	return $result;
}

sub __GetRoutSpeed {
	my $self         = shift;
	my $drillSize    = shift;    # µm
	my $isOutline    = shift;
	my $isDuplicated = shift;
	my $routSpeedTab = shift;

	my $speed;
	if ($isOutline) {
		$speed = $routSpeedTab->{$drillSize}->{"outline"};
	}
	else {
		$speed = $routSpeedTab->{$drillSize}->{"standard"};
	}

	if ($isDuplicated) {

		$speed = RoutDuplicated->GetRoutSpeed($drillSize);
	}

	return $speed;

}

sub __GetRoutSpeedTable {
	my $self        = shift;
	my $matThick    = shift;    # µm
	my $minTool     = shift;    #µm
	my $totlaPnlCnt = shift;
	my $layers      = shift;

	# Rout speed
	my %routSpeedTab        = $self->__ParseRoutSpeedTable("RoutSpeed.csv");
	my %routSpeedOutlineTab = $self->__ParseRoutSpeedTable("RoutSpeedOutline.csv");

	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $packetType = $self->__GetPacketType( $matThick, \%routSpeedTab, $minTool, $totlaPnlCnt );

	if ( scalar( grep { $_ =~ /[rf]z[cs]/ } @{$layers} ) ) {
		$packetType = 0;
	}

	my %tSpeed = ();

	foreach my $t ( keys %routSpeedTab ) {

		$tSpeed{$t} = {
						"standard" => $routSpeedTab{$t}->[$packetType],
						"outline"  => $routSpeedOutlineTab{$t}->[$packetType]
		};

	}

	return %tSpeed

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

		unless ( defined $minTool ) {
			die "";
		}
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

		# here is exception, if two packet,
		# try to split panels amount equally among theses two packets
		# in order get smaller height of packets and than heigher speed of rout
		if ( ceil( $totlaPnlCnt / $pnlPerPacket ) == 2 ) {

			# each packet will contain max panel cnt: $pnlPerPacket
			$pnlPerPacket = ceil( $totlaPnlCnt / 2 );

			# search smallest packet treshold thickness for new packet
			for ( my $i = $defPaketIdx ; $i >= 0 ; $i-- ) {

				if ( $pnlPerPacket * $matThick < $paketThick[$i] ) {
					$realPaketIdx = $i;
				}
				else {
					last;
				}
			}
		}

	}

	return $realPaketIdx;

}

sub __ParseRoutSpeedTable {
	my $self = shift;
	my $file = shift;

	my $p = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutSpeed\\" . $file;

	my @lines = @{ FileHelper->ReadAsLines($p) };
 
	my %tools = ();

	foreach my $line (@lines) {
		
		chomp($line);
		
		next if($line =~ /#/);
		
		my @vals = split( ";", $line );
		chomp(@vals);

		my $t = int( ( shift @vals ) * 1000 );

		die "Wrong parsed tool size at $p, line $line" unless ($t);

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

	my $result = RoutSpeed->__GetRoutSpeedTable( 1600, 1000, 8, ["f"] );

	print STDERR "Result is: $result";

}

1;
