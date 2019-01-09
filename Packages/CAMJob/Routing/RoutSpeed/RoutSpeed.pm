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

	# Parse csv file with rout speed
	my %routSpeedTab = $self->__ParseRoutSpeedFile($materialKind);

	# Only operation which contain rout layer

	my @ncOperations = grep { $_->{"isRout"} } $tif->GetNCOperations();

	foreach my $ncOper (@ncOperations) {

		next unless ( $ncOper->{"isRout"} );

		foreach my $m ( keys %{ $ncOper->{"machines"} } ) {

			my $ncFile = $ncPath . $jobId . "_" . $ncOper->{"opName"} . "." . $m;

			die "NCFile doesn't exist $ncFile" unless ( -e $ncFile );

			my $file = path($ncFile);
			my $data = $file->slurp_utf8;    # load nc file

			foreach my $toolKey ( keys %{ $ncOper->{"machines"}->{$m} } ) {

				my $t = $ncOper->{"machines"}->{$m}->{$toolKey};

				# 1) Get thickness of pcb packet

				# Get packet speeds for minimal rout tool (default, not special)
				my @minToolSpeeds;
				
				if( defined $ncOper->{"minSlotTool"}){
					
					my $minTool = $ncOper->{"minSlotTool"};
					
					# Check if min tool is defined in tabel
					die "Minimal slot tool: $minTool is not defined in \"RoutSpeedTable\"" unless ( defined $routSpeedTab{ $t->{"toolOperation"} }{ "d=$minTool" . "_type=def" } );
				 
					if(!$t->{"isOutline"}){
						@minToolSpeeds = @{$routSpeedTab{ $t->{"toolOperation"} }->{"d=$minTool" . "_type=def"}}[0..2];
					}else{
						@minToolSpeeds = @{$routSpeedTab{ $t->{"toolOperation"} }->{"d=$minTool" . "_type=def"}}[3..5];
					}
				}

				my $packetType =
				  $self->__GetPacketType( $ncOper->{"ncMatThick"}, $ncOper->{"minSlotTool"}, $totalPnlCnt, \@minToolSpeeds );
				  
				# for depth milling, take always rout speed for first (lowest) packet type
				if ( scalar( grep { $_ =~ /[rf]z[cs]/ } @{ $ncOper->{"layers"} } ) ) {
					$packetType = 0;    # packet type <= 1500µm
				}

				# 2) Get final rout speed
				my $speed = $self->__GetRoutSpeed( $t, $packetType, $routSpeedTab{ $t->{"toolOperation"} } );

				die "No speed defined for tool size: " . $t->{"drillSize"} . ", key: $toolKey" unless defined($speed);

				$data =~ s/\(F_$toolKey\)/F$speed/i;
			}

			# Do final check if all keys (F_<guid>) was replaced by speed
			if ( $data =~ /\(F_[\w-]+\)/i ) {

				$data =~ s/\(F_[\w-]+\)/\(F_not_defined)/ig;
				$result = 0;
				$$errMess .= "NC operation: $ncOper, machine: $m, speed is not defined.\n";
			}

			$file->spew_utf8($data);    # store changes
		}
	}

	return $result;
}

sub __GetRoutSpeed {
	my $self         = shift;
	my $t            = shift;
	my $packetType   = shift;
	my $routSpeedTab = shift;

	my $drillSize    = $t->{"drillSize"};                                          # µm
	my $toolType     = ( $t->{"magazineInfo"} ? $t->{"magazineInfo"} : "def" );    # def/magazine info
	my $isOutline    = $t->{"isOutline"};
	my $isDuplicated = $t->{"isDuplicate"};

	my $key = "d=$drillSize" . "_type=$toolType";                                  # diameter + type

	# Get rout speed, consider if is outline
	my $speed;
	if ($isOutline) {
		$speed = $routSpeedTab->{$key}->[ $packetType + 3 ];                       # outline spped stars on the third position
	}
	else {
		$speed = $routSpeedTab->{$key}->[$packetType];
	}

	# Consider if rout is duplicated
	if ($isDuplicated) {

		$speed = RoutDuplicated->GetRoutSpeed($drillSize);
	}

	return $speed;

}

# Return packet type by total pcb packet count, min rout tool
# - 0: packet type <= 1500
# - 1: packet type <= 3000
# - 2: packet type >= 3000
sub __GetPacketType {
	my $self           = shift;
	my $matThick       = shift;
	my $minTool        = shift;
	my $totlaPnlCnt    = shift;
	my $minToolSpeeds = shift;

	# Determine max possible paket height
	my @paketThick = ( 1500, 3000, 4000 );    # possible paket trasholds in µm

	my $defPaketIdx;                          # max possible paket height for given layer

	for ( my $i = scalar(@paketThick) - 1 ; $i >= 0 ; $i-- ) {

		unless ( defined $minTool ) {

			$defPaketIdx = scalar(@paketThick) - 1;
			last;
		}
 
		if ( defined $minToolSpeeds->[$i] ) {
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

sub __ParseRoutSpeedFile {
	my $self         = shift;
	my $materialKind = shift;

	my %operations = ();

	my $p     = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutSpeed\\RoutSpeed.csv";
	my @lines = @{ FileHelper->ReadAsLines($p) };

	my @curOperLines = ();
	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {
		my $line = $lines[$i];

		$line =~ s/\s//g;
		next if ( $line =~ /^#/ || $line eq "" );    # skip commentary

		if ( scalar(@curOperLines) == 0 && $line !~ /^OPERATIONS/i ) {
			die "Unexpected line text: \"$line\" in file: $p";

		}

		push( @curOperLines, $line );

		# Parse operation table
		if ( scalar(@curOperLines) > 1 && ( $line =~ /^OPERATIONS/i || $i == scalar(@lines) - 1 ) ) {

			# remove first line from next operation table
			if ( $line =~ /^OPERATION/i ) {
				pop(@curOperLines);
				$i--;
			}

			my %curOpers = $self->__ParseRoutSpeedByOperation( \@curOperLines, $materialKind );

			foreach my $k ( keys %curOpers ) {

				die "Operation with key: $k was already parsed. Check if file ($p) contain only unique operations."
				  if ( defined $operations{$k} );
				$operations{$k} = $curOpers{$k};
			}

			@curOperLines = ();

		}

	}

	return %operations;
}

sub __ParseRoutSpeedByOperation {
	my $self         = shift;
	my @lines        = @{ shift(@_) };
	my $materialKind = shift;

	my @operNames = split( ";", ( shift(@lines) =~ /OPERATIONS=(.*)/i )[0] );

	my %tools        = ();
	my %toolsByMat   = ();
	my @curMaterials = ();

	foreach my $line (@lines) {

		$line =~ s/\s//g;
		next if ( $line =~ /#/ || $line eq "" );

		if ( $line =~ /^MATERIALS=(.*)/i ) {

			if (%toolsByMat) {
				foreach my $mat (@curMaterials) {
					%{ $tools{$mat} } = %toolsByMat;
				}
				%toolsByMat = ();
			}

			@curMaterials = split( ";", $1 );

			next;
		}
		
		die "Bad formated rout stool speed line: \"$line\" (operation: " . join( "; ", @operNames ) . ")" unless($line =~ /\d+\.\d+;[\w\.]+(;[\d-]+){6}/); 

		my @vals = split( ";", $line );
		chomp(@vals);

		die "Bad formated rout speed table line: \"$line\". Line has to contain 8 columns" if ( scalar(@vals) != 8 );

		my $t = int( ( shift @vals ) * 1000 );    # tool diameter
		my $tType = shift @vals;                  # tool type if tool is special

		die "Wrong parsed tool size at rout speed table (operation: " . join( "; ", @operNames ) . "), line $line" unless ($t);

		my $key = "d=$t" . "_type=$tType";        # diameter + type

		$toolsByMat{$key} = [];
		push( @{ $toolsByMat{$key} }, $_ eq "-" ? undef : $_ ) foreach @vals;    # tool speed (inside = clmn 1- 3, outline = clmn 3 -)

	}

	# sore last materials
	if (%toolsByMat) {
		foreach my $mat (@curMaterials) {
			$tools{$mat} = \%toolsByMat;
		}
	}

	# Copy tools for all operations in table
	my %operations = ();

	my $t = defined $tools{$materialKind} ? $tools{$materialKind} : $tools{"default"};    # Choose final tool speed by material

	foreach my $oper (@operNames) {

		$operations{$oper} = $t;
	}

	return %operations;

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
	my $result = RoutSpeed->CompleteRoutSpeed( "d113609", 100, "IS400", \$errMess );

	print STDERR "Result is: $result, mess: $errMess";

}

1;
