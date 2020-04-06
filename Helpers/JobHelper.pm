#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::JobHelper;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsGeneral';

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

		$cuThick = HegMethods->GetOuterCuThick( $jobId );
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
	my $self  = shift;
	my $jobId = shift;

	return EnumsPaths->Jobs_ELTESTS . substr( $jobId, 0, 4 ) . "\\" . $jobId . "t\\";

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
	my $self  = shift;
	my $jobId = shift;
	my $stackup = shift // StackupBase->new($jobId);;

	my $type    = undef;
	 

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Helpers::JobHelper';

	print STDERR JobHelper->GetBaseCuThick("d222776");

}

1;

