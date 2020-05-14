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
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Stackup::StackupBase::StackupBase';

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
	my $attName   = shift;            # either string("abc") or Regex type (qr/abc/)

	my %point = ();
	my $id    = undef;

	if ( ref $attName eq 'Regexp' ) {
		$id = ( grep { $scanMarks[$_]->{"att"}{".pnl_place"} =~ m/$attName/ } 0 .. $#scanMarks )[0];
	}
	else {
		$id = ( grep { $scanMarks[$_]->{"att"}{".pnl_place"} eq $attName } 0 .. $#scanMarks )[0];
	}

	if ( defined $id ) {

		$point{"x"} = $scanMarks[$id]->{"x1"};
		$point{"y"} = $scanMarks[$id]->{"y1"};

		return %point;
	}
	else {

		die "Scan mark point was not found for attribute \".pnl_place\" and attribute value: \"$attName\"";
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
			if ( $magazine eq "-" ) {
				$magazine = "";
			}

			$line .= $magazine;

		}
		else {

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

	my $toolType = $tool->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE ? "drill" : "rout";
	my $special = $tool->GetSpecial() ? "spec" : "def";

	# Build tool key
	my $toolKey = "c" . sprintf( "%d", $tool->GetDrillSize() );
	$toolKey .= "_" . $tool->GetMagazineInfo() if ( $tool->GetSpecial() );

	# Get tool parameter line
	$line = $par->{$toolType}->{$special}->{$toolKey};

	return undef if ( !defined $line );

	# If tool is special, remove magazine info from line
	# Example of line: C6.50F0.1U25.0S7.0H500special=W11;6.5 90st
	$line =~ s/special=.*//i if ( $tool->GetSpecial() );

	if ($line) {
		chomp($line);
	}

	return $line;
}

# Return material parameters for specific machine and material
# If layer is type of drill, return drill parameters
# If layer is type of rout, return drill + rout parameters
sub GetMaterialParams {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $layer        = shift;
	my $materialName = shift;
	my $machine      = shift;
	my $path         = shift // GeneralHelper->RootHooks($inCAM);    # root path of hooks (user hooks / server hooks)

	my %params = ();
	$params{"ok"} = 1;

	# Get info about exported layer
	my %lInfo = CamDrilling->GetNCLayerInfo( $inCAM, $jobId, $layer, 1, 1 );

	# 1/0
	my $layerType = $lInfo{"gROWlayer_type"};                        # rout/drill

	# Dir name of default machine parameters
	my $macDefName = "machine_default";

	# Get proper material file
	if ( $lInfo{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill ) {

		$materialName = "PREPREG";
	}
	elsif ( $lInfo{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill || $lInfo{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ) {

		$materialName = "COVERLAY";
	}

	if ( $materialName =~ /Hybrid/i ) {

		# Get proper material type from stackup

		my $stackup = StackupBase->new($jobId);
		my @types   = $stackup->GetStackupHybridTypes();

		if (    scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @types )
			 && scalar( grep { $_ =~ /(PYRALUX)/i } @types ) )
		{
			$materialName = "HYBRID_PYRALUX-FR4";
		}
		elsif (    scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @types )
				&& scalar( grep { $_ =~ /(RO3)/i } @types ) )
		{
			$materialName = "HYBRID_RO3-FR4";
		}
		elsif (    scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @types )
				&& scalar( grep { $_ =~ /(RO4)/i } @types ) )
		{
			$materialName = "HYBRID_RO4-FR4";
		}
		elsif (    scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @types )
				&& scalar( grep { $_ =~ /(R58X0)/i } @types ) )
		{
			$materialName = "HYBRID_R58X0-FR4";
		}
	}

	# 1) parse Drilling parameter
	my $drillOp   = CamDrilling->GetToolOperation( $inCAM, $jobId, $layer, EnumsDrill->TypeProc_HOLE );
	my $drillDef  = {};
	my $drillSpec = {};

	# parse default parems
	my $drillDefFile = $path . "\\ncd\\parametersFile\\$macDefName\\" . $materialName;
	my $drillDefRes = $self->__ParseMaterialParams( $drillDefFile, $drillDef, $drillSpec, "drill", $drillOp );

	# parse special params for machine
	my $drillMachFile = $path . "\\ncd\\parametersFile\\$machine\\" . $materialName;
	my $drillMachRes = $self->__ParseMaterialParams( $drillMachFile, $drillDef, $drillSpec, "drill", $drillOp );

	# check if drill was parsed
	$params{"ok"} = 0 if ( !$drillDefRes && !$drillMachRes );

	$params{"drill"}->{"def"}  = $drillDef;
	$params{"drill"}->{"spec"} = $drillSpec;

	# 2) parse Routing parameter

	if ( $layerType eq "rout" ) {

		my $routOp   = CamDrilling->GetToolOperation( $inCAM, $jobId, $layer, EnumsDrill->TypeProc_CHAIN );
		my $routDef  = {};
		my $routSpec = {};

		# parse default parems
		my $routDefFile = $path . "\\ncr\\parametersFile\\$macDefName\\" . $materialName;
		my $routDefRes = $self->__ParseMaterialParams( $routDefFile, $routDef, $routSpec, "rout", $routOp );

		# parse special params for machine
		my $routMachFile = $path . "\\ncr\\parametersFile\\$machine\\" . $materialName;
		my $routMachRes = $self->__ParseMaterialParams( $routMachFile, $routDef, $routSpec, "rout", $routOp );

		# check if drill was parsed
		$params{"ok"} = 0 if ( !$routDefRes && !$routMachRes );

		$params{"rout"}->{"def"}  = $routDef;
		$params{"rout"}->{"spec"} = $routSpec;
	}

	return %params;
}

# Parse parameter file from specific path
sub __ParseMaterialParams {
	my $self     = shift;
	my $file     = shift;
	my $defPar   = shift;
	my $specPar  = shift;
	my $toolType = shift;        # drill/rout
	my $toolOp   = lc(shift);    # EnumsDrill->ToolOp_xxx

	my $result = 1;

	if ( open( my $fMat, "$file" ) ) {

		my $readLine = 0;
		my $parSection;
		my @lines = <$fMat>;
		for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {
			my $l = $lines[$i];

			$l =~ s/\s*//g;

			next if ( $l eq "" );

			# Tools header block lines:
			#
			# # DEFINITION OF TOOL PARAMETERS
			# # -----------------------------
			# # - TOOLS      = <ROUT/DRILL>
			# # - TYPE       = <DEFAULT/SPECIAL>
			# # - OPERATIONS = xxxxxx, yyyyyyy, zzzzzzz

			if ( $l =~ /DEFINITION/i ) {

				my $headLine1 = lc( $lines[ $i + 2 ] );
				$headLine1 =~ s/\s*//g;

				my $headLine2 = lc( $lines[ $i + 3 ] );
				$headLine2 =~ s/\s*//g;

				my $headLine3 = lc( $lines[ $i + 4 ] );
				$headLine3 =~ s/\s*//g;

				$i += 4;

				my $parToolType = ( $headLine1 =~ /TOOLS=(\w+)/i )[0];
				$parSection = ( $headLine2 =~ /TYPE=(\w+)/i )[0];
				my @parToolOps = split( ";", ( $headLine3 =~ /OPERATIONS=(.*)/i )[0] );

				# Check if parameters are difined and not empty
				die "Tool process type <DRILL/ROUT> is not defined in parameter file ($file)"
				  if ( !defined $parToolType || $parToolType eq "" );
				die "Tool type <DEFAULT/SPECIAL> is not defined in parameter file ($file)"
				  if ( !defined $parSection || $parSection eq "" );

				# Check tool type in parameter files
				die "Parameter file ($file) should contain only parameters for tool type: $toolType, but file contain type: $parToolType"
				  if ( $parToolType !~ /$toolType/i );
				die "Parameter file ($file), wrong parameter tool type: $parSection at line: $l"
				  if ( $parSection ne "special" && $parSection ne "default" );

				if ( grep { $_ eq lc($toolOp) } @parToolOps ) {
					$readLine = 1;
				}
				else {
					$readLine = 0;
				}
			}

			# Tools line
			elsif ( $l =~ /C(.*)F.*/i ) {

				my $key = "c" . sprintf( "%d", $1 * 1000 );

				if ( $parSection eq "special" && $l =~ /^C(.*)F.*special=(.*)/i ) {

					$key .= "_" . $2;

					$specPar->{$key} = $l if ($readLine);
				}
				elsif ( $parSection eq "default" ) {

					$defPar->{$key} = $l if ($readLine);

				}
				else {

					die "Error during parsing line. Section: $parSection in parameter file: $file, line: $l";
				}

			}
			else {

				die "Wrong line format ($l) in parameter file: $file";
			}
		}

		close($fMat);
	}
	else {

		$result = 0;
	}

	return $result;
}

# Return line which contain cooridnates with drilled number
sub GetDrilledNumber {
	my $self       = shift;
	my $jobId      = shift;
	my $position   = shift;            # vvframe - number placed in vv frame / stdframe  - number in standard frame
	my $machine    = shift;
	my @scanMarks  = @{ shift(@_) };
	my %nullPoint  = %{ shift(@_) };
	my $cuThick    = shift;
	my $coreNumber = shift;

	die "No drilled number position defined" if ( !defined $position );
	die "No machine defined"                 if ( !defined $machine );

	# Add job id
	my $numberStr = $jobId;

	# Add Cu thickness
	if ( defined $cuThick ) {

		if ( $cuThick == 0 ) {
			$numberStr .= "--";
		}
		elsif ( $cuThick <= 17 ) {
			$numberStr .= "/";
		}
		elsif ( $cuThick <= 34 ) {
			$numberStr .= "-";
		}
		elsif ( $cuThick <= 69 ) {
			$numberStr .= ":";
		}
		elsif ( $cuThick <= 104 ) {
			$numberStr .= "+";
		}
		else {
			$numberStr .= "++";
		}
	}
	else {
		$numberStr .= " ";
	}

	# Add machine letter
	$machine =~ m/machine_(\w)/;
	$numberStr .= uc($1);

	# Add core number
	$numberStr .= " J$coreNumber" if ( defined $coreNumber );

	my $scanMark = "";

	# select
	if ( $position eq "vvframe" ) {

		$scanMark = qr/^drilled_pcbId_v2/; # attribut value can have suffix
	}
	elsif ( $position eq "stdframe" ) {

		$scanMark = qr/^drilled_pcbId_c/;    # attribut value can have suffix
	}
	else {

		die "Wrong drilled number position: $position";
	}

	$numberStr = $self->GetScanMark( \@scanMarks, \%nullPoint, $scanMark ) . "M97," . $numberStr . "\n";

	return $numberStr;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamNCHooks';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::CAM::UniDTM::UniDTM';

	my $inCAM = InCAM->new();

	my $jobId    = "d270787";
	my $stepName = "panel";

	my $materialName = "Hybrid";
	my $machine      = "machine_c";
	my $layer        = "f";

	my $uniDTM = UniDTM->new( $inCAM, $jobId, $stepName, $layer, 1 );
	my @t = $uniDTM->GetTools();

	my $path = "\\\\incam\\incam_server\\users\\stepan\\hooks\\";

	my %toolParams = CamNCHooks->GetMaterialParams( $inCAM, $jobId, $layer, $materialName, $machine, $path );

	my $magazineOk = 0;
	my $parameters = CamNCHooks->GetToolParam( $t[0], \%toolParams, \$magazineOk );

	print 1;

}

1;
