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
use aliased 'Helpers::FileHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::CAMJob::Routing::RoutDuplicated::RoutDuplicated';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::TifFile::TifNCOperations';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Complete rout speed to exported NC files
sub CompleteRoutSpeed {
	my $self         = shift;
	my $jobId        = shift;
	my $totalPnlCnt  = shift;
	my $materialKind = shift;
	my $errMess      = shift;

	my $result = 1;

	my $ncPath = JobHelper->GetJobArchive($jobId) . "nc\\";

	my $tif = TifNCOperations->new($jobId);

	return 0 unless ( $tif->TifFileExist() );

	# Only operation which contain rout layer

	my @ncOperations = grep { $_->{"isRout"} } $tif->GetNCOperations();

	foreach my $ncOper (@ncOperations) {

		my %routSpeedTab =
		  $self->__GetRoutSpeedTable( $ncOper->{"ncMatThick"}, $ncOper->{"minSlotTool"}, $totalPnlCnt, $materialKind, $ncOper->{"layers"} );

		next unless ( $ncOper->{"isRout"} );

		foreach my $m ( keys %{ $ncOper->{"machines"} } ) {

			my $ncFile = $ncPath . $jobId . "_" . $ncOper->{"opName"} . "." . $m;

			die "NCFile doesn't exist $ncFile" unless ( -e $ncFile );

			my $file = path($ncFile);

			my $data = $file->slurp_utf8;

			foreach my $toolKey ( keys %{ $ncOper->{"machines"}->{$m} } ) {

				my $t = $ncOper->{"machines"}->{$m}->{$toolKey};

				my $speed =
				  $self->__GetRoutSpeed( $t->{"drillSize"}, $t->{"isOutline"}, $t->{"isDuplicate"},
										 ($t->{"magazineInfo"} ? $t->{"magazineInfo"} : "std"),
										 \%routSpeedTab );

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
	my $toolType = shift; # std/magazine info
	my $routSpeedTab = shift;

	my $key = "d=$drillSize"."_type=$toolType"; # diameter + type

	my $speed;
	if ($isOutline) {
		$speed = $routSpeedTab->{$key}->{"outline"};
	}
	else {
		$speed = $routSpeedTab->{$key}->{"standard"};
	}

	if ($isDuplicated) {

		$speed = RoutDuplicated->GetRoutSpeed($drillSize);
	}

	return $speed;

}

sub __GetRoutSpeedTable {
	my $self         = shift;
	my $matThick     = shift;    # µm
	my $minTool      = shift;    #µm
	my $totlaPnlCnt  = shift;
	my $materialKind = shift;
	my $layers       = shift;

	# Rout speed
	my %routSpeedTab        = $self->__ParseRoutSpeedTable( $materialKind );
	 

	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $packetType = $self->__GetPacketType( $matThick, \%routSpeedTab, $minTool, $totlaPnlCnt );

	if ( scalar( grep { $_ =~ /[rf]z[cs]/ } @{$layers} ) ) {
		$packetType = 0;
	}

	my %tSpeed = ();

	foreach my $t ( keys %routSpeedTab ) {

		$tSpeed{$t} = {
						"standard" => $routSpeedTab{$t}->[$packetType],
						"outline"  => $routSpeedOutlineTab{$t} ? $routSpeedOutlineTab{$t}->[$packetType] : undef
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

			$defPaketIdx = scalar(@paketThick) - 1;
			last;
		}

		die "Minimal slot tool: $minTool is not defined in \"RoutSpeedTable\"" unless ( defined $routSpeedTable{ "d=$minTool" . "_type=std" } );

		if ( defined $routSpeedTable{ "d=$minTool" . "_type=std" }->[$i] ) {
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

		# if  at least one panel not match minimum panel count per packet (depand on minimal rout tool)
		# set default one panel per paket
		if ( $pnlPerPacket == 0 ) {
			$pnlPerPacket = 1;
		}

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
	my $self         = shift;
	my $materialKind = shift;
 
	my $p = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutSpeed\\RoutSpeed.csv";

	my @lines = @{ FileHelper->ReadAsLines($p) };

	my %tools        = ();
	my %toolsByMat   = ();
	my @curMaterials = ();

	foreach my $line (@lines) {

		$line =~ s/\s//g;

		if ( $line =~ /Materials=(.*)/i ) {

			if (%toolsByMat) {
				foreach my $mat (@curMaterials) {
					%{ $tools{$mat} } = %toolsByMat;
				}
				%toolsByMat = ();
			}

			@curMaterials = split( ";", $1 );
		}

		next if ( $line =~ /#/ || $line eq "" );

		my @vals = split( ";", $line );
		chomp(@vals);

		my $t = int( ( shift @vals ) * 1000 );    # tool diameter
		my $tType = shift @vals;                  # tool type if tool is special

		die "Wrong parsed tool size at $p, line $line" unless ($t);

		my $pakThick1 = $vals[0] eq "-" ? undef : $vals[0];
		my $pakThick2 = $vals[1] eq "-" ? undef : $vals[1];
		my $pakThick3 = $vals[2] eq "-" ? undef : $vals[2];

		my $key = "d=$t" . "_type=$tType"; # diameter + type
		$toolsByMat{ $key } = [ $pakThick1, $pakThick2, $pakThick3 ];
	}

	if (%toolsByMat) {
		foreach my $mat (@curMaterials) {
			$tools{$mat} = \%toolsByMat;
		}
	}

	if ( $tools{$materialKind} ) {

		return %{ $tools{$materialKind} };
	}
	else {

		return %{ $tools{"default"} };
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';
	use aliased 'Packages::InCAM::InCAM';

	my $errMess = "";
	my $result = RoutSpeed->CompleteRoutSpeed( "d113608", 20, "AL_CORE", \$errMess );

	print STDERR "Result is: $result";

}

1;
