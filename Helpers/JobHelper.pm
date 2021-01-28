#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::JobHelper;

#3th party library
use strict;
use warnings;
use XML::Simple;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsDrill';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'Packages::Stackup::Enums' => "StackEnums";

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return base cu thick by layer
sub GetBaseCuThick {
	my $self      = shift;
	my $jobId     = shift;
	my $layerName = shift;

	my $cuThick;

	if ( HegMethods->GetBasePcbInfo($jobId)->{"pocet_vrstev"} > 2 ) {

		my $stackup = StackupBase->new($jobId);

		my $cuLayer = $stackup->GetCuLayer($layerName);
		$cuThick = $cuLayer->GetThick();
	}
	else {

		$cuThick = HegMethods->GetOuterCuThick($jobId);
	}

	return $cuThick;
}

#Return 1 if stackup for pcb exist
sub StackupExist {
	my $self  = shift;
	my $jobId = shift;

	my $inStack = ( -e EnumsPaths->Jobs_COUPONS . "$jobId.xml" );

	my $multicall = ( FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $jobId . "_" ) );

	if ( $inStack || $multicall ) {

		return 1;
	}
	else {

		return 0;
	}

}

sub GetJobArchive {
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->Jobs_ARCHIV . substr( $jobId, 0, -3 ) . "\\" . $jobId . "\\";
}

# Return if job id is in old format /[df]{5}/i
# If so, prepare new format  /d{6}/i
# If so, prepare old job id  /d{6}/i
sub FormerPcbId {
	my $self      = shift;
	my $jobId     = shift;
	my $oldArchiv = shift;    # ref, where old job archiv will be stored
	my $oldJobId  = shift;    # ref, where old pcb id will be stored

	my $isFormer = 0;

	my $name = substr( $jobId, 0, 1 );
	my $num  = substr( $jobId, 1, length($jobId) - 1 );

	if ( length($jobId) == 7 && $name =~ /D/i && $num < 200000 ) {

		$isFormer = 1;

		# New D0..... => Former "D00000-D99999"
		# New D1..... => Former "F00000-F99999"

		$$oldJobId = $self->ConvertJobIdNew2Old($jobId);

		my $oldJobIdUC = lc($$oldJobId);
		$$oldArchiv = EnumsPaths->Jobs_ARCHIVOLD . substr( $oldJobIdUC, 0, -3 ) . "\\" . $oldJobIdUC . "\\";
	}

	return $isFormer;
}

sub ConvertJobIdOld2New {
	my $self  = shift;
	my $jobId = shift;

	my $newJobId = "d";

	# convert
	if ( $jobId !~ /^[df]\d{5}$/i ) {
		die "Jobid ($jobId) is not old formated.";
	}

	my $name = substr( $jobId, 0, 1 );
	my $num  = substr( $jobId, 1, length($jobId) - 1 );

	if ( $name =~ /d/i ) {
		$newJobId .= "0" . $num;
	}
	elsif ( $name =~ /f/i ) {
		$newJobId .= "1" . $num;
	}

	return $newJobId;
}

sub ConvertJobIdNew2Old {
	my $self  = shift;
	my $jobId = shift;

	my $oldJobId = undef;

	# convert
	if ( $jobId !~ /^d\d{6}$/i ) {

		die "Jobid ($jobId) is not in new format DXXXXXX.";
	}

	my $name = substr( $jobId, 0, 1 );
	my $num  = substr( $jobId, 1, length($jobId) - 1 );

	if ( $num >= 200000 ) {

		die "Jobid ($jobId) is in new format, but old format doesn't exist for numbers > D200000.";
	}

	# New D0..... => Former "D00000-D99999"
	# New D1..... => Former "F00000-F99999"

	my $nameOld = substr( $jobId, 1, 1 ) eq "0" ? "d" : "f";

	$oldJobId = $nameOld . substr( $jobId, 2, length($jobId) - 2 );

	return $oldJobId;
}

# return path of job el test
sub GetJobElTest {
	my $self   = shift;
	my $jobId  = shift;
	my $kooper = shift // 0;

	my $p = EnumsPaths->Jobs_ELTESTS . substr( $jobId, 0, 4 ) . "\\" . $jobId . "t";
	$p .= "_kooperace" if ($kooper);
	$p .= "\\";
	return $p

}

# Return step names, which are special helper steps for compare netlists. (steplist are generated and can be deleted)
# o+1_panel_ref_netlist
# mpanel_netlist
# mpanel_ref_netlist
sub GetNetlistStepNames {
	my $self = shift;

	my @s = ( "o+1_panel", "panel_ref_netlist", "mpanel_netlist", "mpanel_ref_netlist" );
	return @s;
}

# Return step names, which are special coupon steps
# coupon_impedance
# coupon_drill
sub GetCouponStepNames {
	my $self = shift;

	my @s = ( EnumsGeneral->Coupon_IMPEDANCE, EnumsGeneral->Coupon_DRILL );
	return @s;
}

sub GetJobOutput {
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->InCAM_jobs . $jobId . "\\output\\";

}

# Return listo of all jobs in incam database (default)
sub GetJobList {
	my $self   = shift;
	my $dbName = shift;

	my @jobList = $self->GetJobListAll($dbName);

	@jobList = grep { $_->{"name"} =~ /^d\d{6}$/ } @jobList;

	return @jobList;
}

# Return listo of all jobs in incam database (default)
sub GetJobListAll {
	my $self   = shift;
	my $dbName = shift;

	unless ( defined $dbName ) {
		$dbName = "incam";
	}

	my $path = EnumsPaths->InCAM_server . "config\\joblist.xml";

	my $xmlString = FileHelper->ReadAsString($path);

	my $xml = XMLin(
		$xmlString,

		ForceArray => undef,
		KeyAttr    => undef,
	);

	my @jobList = @{ $xml->{"job"} };

	@jobList = grep { $_->{"dbName"} eq $dbName } @jobList;

	return @jobList;
}

sub GetPcbType {
	my $self = shift;

	my $jobId = shift;

	my $isType = HegMethods->GetTypeOfPcb( $jobId, 1 );
	my $type;

	if ( $isType eq '0' ) {

		$type = EnumsGeneral->PcbType_NOCOPPER;
	}
	elsif ( $isType eq '1' ) {

		$type = EnumsGeneral->PcbType_1V;

	}
	elsif ( $isType eq '2' ) {

		$type = EnumsGeneral->PcbType_2V;

	}
	elsif ( $isType eq 'N' ) {

		$type = EnumsGeneral->PcbType_MULTI;

	}
	elsif ( $isType eq "F" ) {

		$type = EnumsGeneral->PcbType_1VFLEX;
	}
	elsif ( $isType eq "G" ) {

		$type = EnumsGeneral->PcbType_2VFLEX;

	}
	elsif ( $isType eq "H" ) {

		$type = EnumsGeneral->PcbType_MULTIFLEX;
	}
	elsif ( $isType eq "Q" ) {

		$type = EnumsGeneral->PcbType_RIGIDFLEXO;
	}
	elsif ( $isType eq "R" ) {

		$type = EnumsGeneral->PcbType_RIGIDFLEXI;

	}
	elsif ( $isType eq "T" ) {

		$type = EnumsGeneral->PcbType_STENCIL;
	}
	else {

		die "Unknow type of IS PCB type: $isType";
	}

	return $type;
}

# Return 1 if pcb is flex or rigid flex
sub GetIsFlex {
	my $self  = shift;
	my $jobId = shift;

	my $isFlex = 0;

	my $type = $self->GetPcbType($jobId);

	if (    $type eq EnumsGeneral->PcbType_1VFLEX
		 || $type eq EnumsGeneral->PcbType_2VFLEX
		 || $type eq EnumsGeneral->PcbType_MULTIFLEX
		 || $type eq EnumsGeneral->PcbType_RIGIDFLEXO
		 || $type eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{
		$isFlex = 1;
	}

	return $isFlex;
}

# Return info if flex core is placed very or botttom at stackup
# Return value = felxtop/flexbot
sub GetORigidFlexType {
	my $self    = shift;
	my $jobId   = shift;
	my $stackup = shift // StackupBase->new($jobId);

	my $type = undef;

	my @allC = $stackup->GetAllCores();

	if ( $allC[0]->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {
		$type = "flextop";

	}
	elsif ( $allC[-1]->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {

		$type = "flexbot";
	}
	else {

		die "Neither top nor bot core is not flex";

	}
	return $type;
}

# Return signal layers which are covered by coverlay (source is IS)
sub GetCoverlaySigLayers {
	my $self  = shift;
	my $jobId = shift;

	my @sigLayers = ();

	my %coverlayType = HegMethods->GetCoverlayType($jobId);

	my $sigLayer;

	if ( $coverlayType{"top"} ) {

		my $stackup = StackupBase->new($jobId);

		# find flexible inner layers
		my $core = ( $stackup->GetAllCores(1) )[0];
		$sigLayer = $core->GetTopCopperLayer()->GetCopperName();

		push( @sigLayers, $sigLayer );
	}

	if ( $coverlayType{"bot"} ) {

		my $stackup = StackupBase->new($jobId);

		# find flexible inner layers
		my $core = ( $stackup->GetAllCores(1) )[0];
		$sigLayer = $core->GetBotCopperLayer()->GetCopperName();

		push( @sigLayers, $sigLayer );
	}

	return @sigLayers;
}

# Hybrid DPS are DPS which:
# - a) has got IS material kind Hybrid (hybrid)
# - b) has not got IS material kind Hybrid and contains additional special layers eg. coverlay  (semi-hybrid)
sub GetIsHybridMat {
	my $self         = shift;
	my $jobId        = shift;
	my $matKind      = shift // HegMethods->GetMaterialKind($jobId);
	my $matKinds     = shift // [];                                  # Array ref, where all found mat kinds will by stored
	my $isSemiHybrid = shift;                                        # Reference where is stored 1 if material is special type of hybrid - semi-hybrid

	my $isHybrid = 0;
	$$isSemiHybrid = 0 if ( defined $isSemiHybrid );

	if ( $matKind =~ /Hybrid/i ) {

		$isHybrid = 1;                                               # a) Hybrid

		my $stackup = StackupBase->new($jobId);
		my @types   = $stackup->GetStackupHybridTypes();
		push( @{$matKinds}, @types );

	}
	elsif ( !$self->GetIsFlex($jobId) ) {
		
		# whole flexible PCB do not consider as hybrid even 
		# if there is more tzpes of material (PYRALUX, THINFLEX,..)

		push( @{$matKinds}, $matKind );

		# Check additional special layers

		# 1) Coverlay top
		my %cvrl = HegMethods->GetCoverlayType($jobId);
		if ( ( defined $cvrl{"top"} && $cvrl{"top"} ) ) {

			$isHybrid = 1;                                     # b) Semi-hybrid
			$$isSemiHybrid = 1 if ( defined $isSemiHybrid );

			my $matInfo = HegMethods->GetPcbCoverlayMat( $jobId, "top" );
			if ( defined $matInfo->{"dps_druh"} && $matInfo->{"dps_druh"} ne "" ) {

				push( @{$matKinds}, $matInfo->{"dps_druh"} );
			}

		}

		# 2) Coverlay bot
		if ( defined $cvrl{"bot"} && $cvrl{"bot"} ) {

			$isHybrid = 1;                                     # b) Semi-hybrid
			$$isSemiHybrid = 1 if ( defined $isSemiHybrid );

			my $matInfo = HegMethods->GetPcbCoverlayMat( $jobId, "bot" );
			if ( defined $matInfo->{"dps_druh"} && $matInfo->{"dps_druh"} ne "" ) {

				push( @{$matKinds}, $matInfo->{"dps_druh"} );
			}
		}
	}

	# Check if there are really different materials
	if ($isHybrid) {

		$_ = uc for @{$matKinds};

		@{$matKinds} = uniq( @{$matKinds} );

		$isHybrid      = 0 if ( scalar( @{$matKinds} ) == 1 );    # only one type of material
		$$isSemiHybrid = 0 if ( scalar( @{$matKinds} ) == 1 );

	}

	return $isHybrid;
}

# Material codes for hybrid materials
# Hybrid DPS are DPS which:
# - a) has got IS material kind Hybrid (hybrid)
# - b) has not got IS material kind Hybrid and contains additional special layers eg. coverlay  (semi-hybrid)
# This code clearly describes which materials are combined together
sub GetHybridMatCode {
	my $self     = shift;
	my $jobId    = shift;
	my $matKinds = shift;

	die "Material is not hybrid => number of materials:" . scalar( @{$matKinds} ) if ( scalar($matKinds) <= 1 );

	my $matCode = undef;

	if (    scalar( grep { $_ =~ /(PYRALUX)/i } @{$matKinds} )
		 && scalar( grep { $_ =~ /(FR4)|(IS400)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_PYRALUX__FR4;
	}
	elsif (    scalar( grep { $_ =~ /(THINFLEX)/i } @{$matKinds} )
			&& scalar( grep { $_ =~ /(FR4)|(IS400)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_THINFLEX__FR4;
	}
	elsif (    scalar( grep { $_ =~ /(RO3)/i } @{$matKinds} )
			&& scalar( grep { $_ =~ /(FR4)|(IS400)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_RO3__FR4;
	}
	elsif (    scalar( grep { $_ =~ /(RO4)/i } @{$matKinds} )
			&& scalar( grep { $_ =~ /(FR4)|(IS400)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_RO4__FR4;
	}
	elsif (    scalar( grep { $_ =~ /(R58X0)/i } @{$matKinds} )
			&& scalar( grep { $_ =~ /(FR4)|(IS400)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_R58X0__FR4;

	}
	elsif (    scalar( grep { $_ =~ /(I-TERA)/i } @{$matKinds} )
			&& scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @{$matKinds} ) )
	{
		$matCode = EnumsDrill->HYBRID_ITERA__FR4;

	}
	else {

		die "Hybrid material code was not found for material kinds: " . join( ";", @{$matKinds} );
	}

	return $matCode;
}

## Material codes for semi-hybrid materials
## Hybrid DPS are DPS which has IS material kind not equal to Hybrid but contains additional special layers (eg. coverlay)
## This code clearly describes which materials are combined together
#sub GetSemiHybridMatCode {
#	my $self  = shift;
#	my $jobId = shift;
#
#	my $matCode = undef;
#
#	my $matKind = HegMethods->GetMaterialKind($jobId);
#
#	die "Material kind is not defined in IS" if ( !defined $matKind || $matKind eq "" );
#	die "Material kind is Hybrid. This is not semi-hybrid" if ( $matKind =~ /hybrid/i );
#
#	my @types = ($matKind);
#
#	my %cvrl = HegMethods->GetCoverlayType($jobId);
#
#	if ( defined $cvrl{"top"} && $cvrl{"top"} ) {
#
#		my $matInfo = HegMethods->GetPcbCoverlayMat( $jobId, "top" );
#		if ( defined $matInfo->{"dps_druh"} && $matInfo->{"dps_druh"} ne "" ) {
#
#			push( @types, $matInfo->{"dps_druh"} );
#		}
#	}
#	if ( defined $cvrl{"bot"} && $cvrl{"bot"} ) {
#
#		my $matInfo = HegMethods->GetPcbCoverlayMat( $jobId, "bot" );
#		if ( defined $matInfo->{"dps_druh"} && $matInfo->{"dps_druh"} ne "" ) {
#
#			push( @types, $matInfo->{"dps_druh"} );
#		}
#	}
#
#	if (    scalar( grep { $_ =~ /(PYRALUX)/i } @types )
#		 && scalar( grep { $_ =~ /(IS400)|(DE104)|(PCL370)/i } @types ) )
#	{
#		$matCode = EnumsDrill->HYBRID_PYRALUX__FR4;
#	}
#	else {
#
#		die "Hybrid material code was not found for material types: " . join( ";", @types );
#	}
#
#	return $matCode;
#}

sub GetIsolationByClass {
	my $self  = shift;
	my $class = shift;

	my $isolation;

	if ( $class <= 3 ) {

		$isolation = 400;

	}
	elsif ( $class <= 4 ) {

		$isolation = 300;

	}
	elsif ( $class <= 5 ) {

		$isolation = 200;

	}
	elsif ( $class <= 6 ) {

		$isolation = 150;

	}
	elsif ( $class <= 7 ) {

		$isolation = 125;

	}
	elsif ( $class <= 8 ) {

		$isolation = 100;

	}
	elsif ( $class <= 9 ) {

		$isolation = 75;
	}

	return $isolation;
}

sub BuildSignalLayerName {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $name = "";

	$name .= "outer" if ($outerCore);
	$name .= "plg"   if ($plugging);
	$name .= $copperName;

	return $name;
}

sub ParseSignalLayerName {
	my $self        = shift;
	my $copperLName = shift;

	my %lInfo = ();

	$lInfo{"sourceName"} = ( $copperLName =~ /([csv]\d*)/ )[0];
	$lInfo{"outerCore"}  = $copperLName =~ /outer([csv]\d*)/ ? 1 : 0;
	$lInfo{"plugging"}   = $copperLName =~ /plg([csv]\d*)/ ? 1 : 0;

	return %lInfo;
}

# If job name starts with X, job is price offer
sub GetJobIsOffer {
	my $self  = shift;
	my $jobId = shift;

	return $jobId =~ /^x/i ? 1 : 0;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Helpers::JobHelper';

	print STDERR JobHelper->GetSemiHybridMatCode("d293099");

}

1;

