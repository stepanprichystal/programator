#-------------------------------------------------------------------------------------------#
# Description: Package contains helper function for InCAM hooks such as: ncd/outfile, ncr/outfile etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamHooks;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamHooks';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

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

	open( INFOFILE, $fFeatures );

	while ( my $l = <INFOFILE> ) {

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
	return @features;
}

# return line with coordinates of scanmark, by scanmark attributes
# scanmark coordinates are recomputed according nullpoint
sub GetScanMark {
	my $self      = shift;
	my @scanMarks = @{ shift(@_) };
	my %nullPoint = %{ shift(@_) };
	my $attName   = shift;

	my %point = CamHooks->GetScanMarkPoint( \@scanMarks, $attName );

	$point{"x"} -= $nullPoint{"x"};
	$point{"y"} -= $nullPoint{"y"};

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

#Return complete line with all parameters for particular tool and flag
sub GetToolParamLine {
	my $self         = shift;
	my $tool         = shift;             #tool in µm
	my $flag         = shift;             #int number, sign special tool
	my $materialName = shift;
	my @par          = @{ shift(@_) };    #parametters

	my $line;

	unless ( @par || scalar(@par) == 0 ) {

		#print "GetToolParByDiameter\n";
		return $line;
	}

	$tool = $tool / 1000;

	#compare float numbers
	my ( $t, $c );
	if ($flag) {

		my $toolCode = CamHooks->GetSpecialToolByFlag( $materialName, $tool, $flag );

		# Example of line: C0.10F1.8U2.0S300.0H500flag1
		foreach my $l (@par) {

			if ( $l !~ /special=/i ) {
				next;
			}

			$l =~ m/C(.*)F.*special=([\w\d]+);?/i;
			$t = $1;
			$c = $2;

			if ( $t == $tool && $c eq $toolCode ) {
				$line = $l;
				last;
			}
		}
	}
	else {

		# Example of line: C0.10F1.8U2.0S300.0H500
		foreach (@par) {

			$_ =~ m/C(.*)F/i;
			$t = defined $1 ? $1 : -1;

			if ( $t == $tool && $_ !~ /special=/i ) {
				$line = $_;
				last;
			}
		}
	}

	chomp($line);
	return $line;
}

# Return description for special tool
# Description is located behind parameters after comma
sub GetSpecialToolDesc {
	my $self         = shift;
	my $tool         = shift;             #tool in µm
	my $flag         = shift;             #int number, sign special tool
	my $materialName = shift;
	my @par          = @{ shift(@_) };    #parametters
	my $desc         = shift;
	my $result       = 1;

	my $line = CamHooks->GetToolParamLine( $tool, $flag, $materialName, \@par );

	#if special tool is present, check for description
	if ( $line && $line =~ m/C(.*)F.*special=([\w\d]+);?/i ) {

		# Example of line: C6.50F0.1U25.0S7.0H500special=IW1;6.5 90st
		#description is all after comma
		my ($tmp) = $line =~ m/C.*F.*special=[\w\d]+;(.+)/i;
		chomp($tmp);
		if ( !$tmp || $tmp eq "" ) {
			$result = 0;

		}
		else {
			$$desc = $tmp;
		}
	}

	return $result;

}

# Return complete tool parameter for tool
sub GetToolParam {
	my $self         = shift;
	my $layerName    = shift;             #layer of exported nc
	my $tool         = shift;             #tool in µm
	my $type         = shift;             # hole/chain
	my $flag         = shift;             #int number, sign special tool
	my $materialName = shift;
	my @par          = @{ shift(@_) };    #parametters
	my $result       = "";

	#find out, if layer is plated or not

	my %lHash = ( "gROWname" => $layerName );
	my @layers = ( \%lHash );
	CamDrilling->AddNCLayerType( \@layers );

	my $plated = $layers[0]->{"plated"};

	my $line = CamHooks->GetToolParamLine( $tool, $flag, $materialName, \@par );

	if ($line) {

		# Example of line: C0.10F1.8U2.0S300.0H500

		#remove and remember flag if exist
		my $specT;
		if ($flag) {
			($specT) = $line =~ m/C.*F.*special=([\w\d]+);/i;
			$line =~ s/special=.*//i;
		}

		#if flag, add them according special table contains special tools
		if ($flag) {
			$line .= "(" . $specT . ")";
		}
		else {

			#add letter which tell if tool is hole/chain
			if ( $type eq "chain" ) {
				$line .= "(R)";
			}
			else {

				#if layer is not plated, add "I1", else "D"
				if ($plated) {
					$line .= "(D)";
				}
				else {
					$line .= "(I1)";
				}

			}
		}

		$line =~ m/(f.*)/i;
		$result = $1;

		return $result;
	}
}

#Return description of tool, how is defined on NC department
# table is defined for each special tool:
# - Material,
# - tool size,
# - flag
sub GetSpecialToolByFlag {
	my $self     = shift;
	my $material = shift;
	my $toolSize = shift;    #as float number
	my $flag     = shift;

	my $res = 0;

	my %table = ();

	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"1"} = "IW1";
	$table{ EnumsGeneral->Mat_FR4 }{6.5}{"2"} = "IW2";

	$res = $table{$material}{$toolSize}{$flag};

	unless ($res) {
		return 0;
	}

	return $res;
}

#sub GetSpecialToolFlag {
#	my $self     = shift;
#	my $material = shift;
#	my $toolSize = shift;    #as float number
#	my $flag     = shift;
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
#	$$code = $table{$material}{$toolSize}{$flag}{"code"};
#	$$desc = $table{$material}{$toolSize}{$flag}{"desc"};
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
	my @params       = undef;

	#load parameters only when material exist
	if ($materialName) {

		if ( $materialName =~ /FR4/i ) {

			$materialFile = "FR4";

		}
		elsif ( $materialName =~ /IS410/i ) {

			$materialFile = "IS410";

		}
		elsif ( $materialName =~ /Al/i ) {

			$materialFile = "AL";

		}
		elsif ( $materialName =~ /G200/i ) {

			$materialFile = "G200";
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

		if ($materialFile) {

			$materialFile = $ncPath . "parametersFile\\" . $machine . "\\" . $materialFile;

			#print "Material file path: $materialFile\n";

			if ( open( MATERIAL, "$materialFile" ) ) {

				@params = <MATERIAL>;
				close(MATERIAL);

			}
			else {

				print STDERR "Cant open material file for machine: $machine $_.";

				@params = ();
				return @params;
			}

		}
	}

	return @params;
}

1;
