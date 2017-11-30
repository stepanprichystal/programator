#-------------------------------------------------------------------------------------------#
# Description: Package contains helper function for InCAM hooks such as: ncd/outfile, ncr/outfile etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamNCHooks;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Create log when export drill or rout file
sub LogExportResult {
	my $self      = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $machine   = shift;
	my $setName   = shift;
	my $type      = shift;
	my $result    = shift;
	my $desc      = shift;

	my $logFile = EnumsPaths->Client_INCAMTMPNC . $jobId;

	unless ( -e EnumsPaths->Client_INCAMTMPNC ) {
		mkdir( EnumsPaths->Client_INCAMTMPNC ) or die "Can't create dir: " . EnumsPaths->Client_INCAMTMPNC . $_;
	}

	#my $newLog = "$jobId/$stepName/$layerName/$machine/$setName/$type = " . $result."\n";
	my $newLog = "$jobId/$stepName/$layerName/$machine/$type = " . $result . "; $desc\n";
	my $f;

	open( $f, "<$logFile" );
	my @lines = <$f>;
	close($f);

	open( $f, "+>$logFile" ) or die "Can't open log file $_";
	my $logAdded = 0;

	#delete already existing logs for sam type
	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l   = $lines[$i];
		my $key = "$jobId/$stepName/$layerName/$machine/$type";
		$l =~ /(.*)\s=/;

		if ( $key eq $1 ) {

			print $f $newLog;
			$logAdded = 1;
		}
		else {
			print $f $l;
		}
	}

	unless ($logAdded) {
		print $f $newLog;
	}

	close($f);
}

# Read all pads in layer which has .pnl_place attribut
# and return their coordiantes
sub GetLayerCamMarks {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;
	my $mirrorX  = shift;

	my @features = ();

	my $fFeatures = $inCAM->INFO(
								  units       => 'mm',
								  entity_type => 'layer',
								  entity_path => "$jobId/$stepName/$layer",
								  data_type   => 'FEATURES',
								  options     => 'feat_index+f0',
								  parse       => 'no'
	);

	#print "Su zde $fFeatures 2 \n";
	my $INFOFILE;
	open( $INFOFILE, $fFeatures );

	while ( my $l = <$INFOFILE> ) {

		my %featInfo;

		if ( $l =~ /###/ ) { next; }

		#If features is not type PAD
		unless ( $l =~ /#P\s?/ ) { next; }

		$l =~ m/^#(\d*)\s*#(\w)\s*((-?[0-9]*\.?[0-9]*\s)*)\s*[\w\d\s]*;?(.*)/;

		$featInfo{"id"}   = $1;
		$featInfo{"type"} = $2;

		my @points = split( /\s/, $3 );

		$featInfo{"x1"} = $points[0];
		$featInfo{"y1"} = $points[1];

		my @attr = split( ",", $5 );

		foreach my $at (@attr) {
			my @attValue = split( "=", $at );
			$featInfo{"att"}{ $attValue[0] } = $attValue[1];
		}

		push( @features, \%featInfo );
	}

	# mirror cam marks by center x
	if ($mirrorX) {

		my %profLimits = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName, $layer );
		my $centerX = abs( $profLimits{"xMax"} - $profLimits{"xMin"} ) / 2;

		foreach my $f (@features) {

			# get distance of null point from x center of panel
			my $v = ( $centerX - $f->{"x1"} );

			$f->{"x1"} += 2 * $v;
		}
	}

	return @features;
}

# return line with coordinates of scanmark, by scanmark attributes
# scanmark coordinates are recomputed according nullpoint
# If marks are for NC operation from bot, consider pcb is turned on the machine table
sub GetScanMark {
	my $self      = shift;
	my @scanMarks = @{ shift(@_) };
	my %nullPoint = %{ shift(@_) };
	my $attName   = shift;

	my %point = $self->GetScanMarkPoint( \@scanMarks, $attName );

	print STDERR "point x:" . $point{"x"} . "\n\n";
	print STDERR "point y:" . $point{"y"} . "\n\n";

	$point{"x"} -= $nullPoint{"x"};
	$point{"y"} -= $nullPoint{"y"};

	print STDERR "null x:" . $nullPoint{"x"} . "\n\n";
	print STDERR "null y:" . $nullPoint{"y"} . "\n\n";

	return sprintf( "X%.3f", $point{"x"} ) . sprintf( "Y%.3f", $point{"y"} );
}

# return coordinates of scanmark in hash
# null point is [0, 0]
sub GetScanMarkPoint {
	my $self      = shift;
	my @scanMarks = @{ shift(@_) };
	my $attName   = shift;

	my %point = ();

	my $id = ( grep { $scanMarks[$_]->{"att"}{".pnl_place"} eq $attName } 0 .. $#scanMarks )[0];
	if ( defined $id ) {

		$point{"x"} = $scanMarks[$id]->{"x1"};
		$point{"y"} = $scanMarks[$id]->{"y1"};

		return %point;
	}

}

# Return description for special tool, from Universal tool object
sub GetSpecialToolDesc {
	my $self = shift;
	my $tool = shift;    # universal tool

	my $str = undef;

	if ( $tool->GetSpecial() ) {

		$str = sprintf( "%.2f", $tool->GetDrillSize() / 1000 ) . " " . $tool->GetAngle() . "st";
	}

	return $str;
}

# Return complete tool parameter for tool
# format eg.: C0.10F1.8U2.0S300.0H500(W1)
sub GetToolParam {
	my $self       = shift;
	my $tool       = shift;    # Universal tool object
	my $par        = shift;    # arametters of given material
	my $magazineOk = shift;    # set 1, if magazine code was found

	my $line = $self->__GetToolParamLine( $tool, $par );

	if ($line) {

		# Example of line: C0.10F1.8U2.0S300.0H500
		my $magazine = $tool->GetMagazine();    # number of magazine

		if ( defined $magazine && $magazine ne "" ) {
			
			# if magazine is "-", replace by empty string
			if($magazine eq "-"){
				$magazine = "";
			}
			
			$line .=  $magazine;
		
		}else{
			
			$$magazineOk = 0;
		}

		$line =~ m/(f.*)/i;
		$line = $1;
	}

	return $line;
}

#Return complete line with all parameters for particular tool and flag
sub __GetToolParamLine {
	my $self = shift;
	my $tool = shift;    # tool in µm
	my $par  = shift;    # arametters of given material

	my $line;

	unless ($par) {
		return undef;
	}

	my $toolSize     = $tool->GetDrillSize() / 1000;
	my $magazineInfo = $tool->GetMagazineInfo();

	if ( $tool->GetSpecial() ) {

		# Example of line: C6.50F0.1U25.0S7.0H500special=W11;6.5 90st
		foreach my $l ( @{ $par->{"special"} } ) {

			$l =~ m/C(.*)F.*special=(.*)/i;

			if ( $1 == $toolSize && $2 eq $magazineInfo ) {
				$line = $l;

				#remove special
				$line =~ s/special=.*//i;
				last;
			}
		}
	}
	else {

		my @par = undef;

		if ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_HOLE ) {
			@par = @{ $par->{"drill"} };

		}
		elsif ( $tool->GetTypeProcess() eq DTMEnums->TypeProc_CHAIN ) {
			@par = @{ $par->{"rout"} };
		}

		# Example of line: C6.50F0.1U25.0S7.0H500
		foreach (@par) {

			$_ =~ m/C(.*)F/i;

			my $t = $1;

			if ( defined $t && $t == $toolSize ) {
				$line = $_;
				last;
			}
		}
	}

	if ($line) {
		chomp($line);
	}

	return $line;
}

##Return description of tool, how is defined on NC department
## table is defined for each special tool:
## - Material,
## - tool size,
## - flag
#sub GetSpecialToolByFlag {
#	my $self     = shift;
#	my $material = shift;
#	my $toolSize = shift;    #as float number
#	my $magazine = shift;
#
#	my $res = 0;
#
#	my %table = ();
#
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"1"} = "IW1";
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"2"} = "IW2";
#
#	$res = $table{$material}{$toolSize}{$magazine};
#
#	unless ($res) {
#		return 0;
#	}
#
#	return $res;
#}

#sub GetSpecialToolFlag {
#	my $self     = shift;
#	my $material = shift;
#	my $toolSize = shift;    #as float number
#	my $magazine     = shift;
#	my $code     = shift;
#	my $desc     = shift;
#
#	my $res = 0;
#
#	my %table = ();
#
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"1"}{"code"} = "IW1";
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"1"}{"desc"} = "6.5 90st";
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"2"}{"code"} = "IW2";
#	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"2"}{"desc"} = "6.5 120st";
#
#	$$code = $table{$material}{$toolSize}{$magazine}{"code"};
#	$$desc = $table{$material}{$toolSize}{$magazine}{"desc"};
#
#	if ($code && $desc) {
#		$res = 1;
#	}
#
#	return $res;
#}

#return array with tool parameters for drilling according material
sub GetMaterialParams {
	my $self         = shift;
	my $materialName = shift;
	my $machine      = shift;
	my $ncPath       = shift;    # \\incam\incam_server\site_data\hooks\<ncr OR ncd>\

	my $materialFile = undef;

	my @d = ();                  # drilling params
	my @r = ();                  # routing params
	my @s = ();                  # special params

	my %params = ( "drill" => \@d, "rout" => \@r, "special" => \@s, "ok" => 1 );

	#load parameters only when material exist
	if ($materialName) {

		if ( $materialName =~ /FR4/i ) {

			$materialFile = "FR4";

		}
		elsif ( $materialName =~ /IS410/i ) {

			$materialFile = "IS410";

		}
		elsif ( $materialName =~ /IS400/i ) {

			$materialFile = "IS400";

		}
		elsif ( $materialName =~ /Al/i ) {

			$materialFile = "AL";

		}
		elsif ( $materialName =~ /G200/i ) {

			$materialFile = "G200";
			
		}elsif ( $materialName =~ /PCL370HR/i ) {

			$materialFile = "PCL370HR";
		
		}elsif ( $materialName =~ /DUROID/i ) {

			$materialFile = "R58X0-DUROID";
		}

		print STDERR "\n\n$materialName - $ncPath - $materialFile\n\n";
	}

	#IS420
	#G200
	#RO4
	#RO3
	#AL_CORE
	#CU_CORE
	#P96
	#P97
	#LAMBDA450
	#FOSFORBRONZ
	#ALPAKA
	#NEREZ
	#NEREZOVA_OCEL

	unless ($materialFile) {
		$params{"ok"} = 0;
	}

	$materialFile = $ncPath . "parametersFile\\" . $machine . "\\" . $materialFile;

	if ( open( my $fMat, "$materialFile" ) ) {

		print STDERR "\n\n file opened $materialFile\n\n";

		my $section = undef;

		while ( my $l = <$fMat> ) {

			if ( $l =~ /#\s*drill/i ) {
				$section = "drill";

				print STDERR "\n\n section drill \n\n";
			}
			elsif ( $l =~ /#\s*rout/i ) {
				$section = "rout";
			}
			elsif ( $l =~ /#\s*special/i ) {
				$section = "special";
			}

			if ( $section && ( $l =~ /C(.*)F.*/i ) ) {
				push( @{ $params{$section} }, $l );
			}
		}

		close($fMat);

	}
	else {

		$params{"ok"} = 0;

	}

	return %params;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#		use aliased 'CamHelpers::CamNCHooks';
#		use aliased 'Packages::InCAM::InCAM';
#	
#		my $inCAM = InCAM->new();
#	
#		my $jobId     = "f50251";
#		my $stepName  = "panel";
#		
#		my $materialName = "PCL370HR"; 
#		my $machine = "machine_a";
#		my $path = "\\\\incam\\incam_server\\site_data\\hooks\\ncd\\";
#		
#		
#		my %toolParams = CamNCHooks->GetMaterialParams( $materialName, $machine, $path );
#	
#		my $parameters = CamNCHooks->GetToolParam( $uniTool, \%toolParams, \$magazineOk );
#	
#		print 1;

}



1;
