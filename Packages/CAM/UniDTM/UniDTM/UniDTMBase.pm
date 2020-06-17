#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniDTM::UniDTMBase;

#3th party library
use strict;
use warnings;
use XML::Simple;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'Packages::CAM::UniDTM::UniTool::UniToolBase';
use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTM';
use aliased 'Packages::CAM::UniDTM::UniTool::UniToolDTMSURF';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::UniDTM::UniDTM::UniDTMCheck';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM = shift;
	my $jobId = shift;
	$self->{"step"}         = shift;
	$self->{"layer"}        = shift;
	$self->{"breakSR"}      = shift;
	$self->{"loadMagazine"} = shift // 0;    # Load tool magazine by material

	my @pilots = ();
	$self->{"pilotDefs"} = \@pilots;

	$self->{"magazineDef"}  = undef;
	$self->{"magazineSpec"} = undef;

	$self->{"materialName"} = HegMethods->GetMaterialKind($jobId);

	my @t = ();
	$self->{"tools"} = \@t;

	# 1) Init tools by InCAM DTM
	$self->__InitUniDTM( $inCAM, $jobId );

	# 2) Load magazine code by magazine info and PCB material
	$self->__LoadToolsMagazine( $inCAM, $jobId ) if ( $self->{"loadMagazine"} );

	$self->{"check"} = UniDTMCheck->new($self);

	return $self;
}

# Check if tools parameters are ok
sub CheckTools {
	my $self = shift;
	my $mess = shift;

	return $self->{"check"}->CheckTools($mess);
}

# Return all tools. Tools can be duplicated
sub GetTools {
	my $self = shift;

	my $mess = "";

	unless ( $self->{"check"}->CheckTools( \$mess ) ) {

		die "Tools definition in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}

	# Tools, some can be duplicated (eg surface can have same diameter like slot)
	my @tools = @{ $self->{"tools"} };

	return @tools;
}

# Return reduced unique tools
# If tool parameters are wrong, script die
sub GetUniqueTools {
	my $self = shift;

	my $mess = "";

	unless ( $self->{"check"}->CheckTools( \$mess ) ) {

		die "Tools definition in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}

	# Tools, some can be duplicated
	# Do distinst by "tool key" (drillSize + typeProcess)
	my %seen;
	my @toolsUniq = grep { !$seen{ $_->GetDrillSize() . $_->GetTypeProcess() }++ } @{ $self->{"tools"} };

	my @tools = ();

	foreach my $t (@toolsUniq) {

		my $tNew = UniToolBase->new( $t->GetDrillSize(), $t->GetTypeProcess() );
		$tNew->SetToolOperation( $t->GetToolOperation() );
		$tNew->SetDepth( $t->GetDepth() );
		$tNew->SetMagazine( $t->GetMagazine() );
		$tNew->SetMagazineInfo( $t->GetMagazineInfo() );
		$tNew->SetSpecial( $t->GetSpecial() );
		$tNew->SetAngle( $t->GetAngle() );

		push( @tools, $tNew );
	}

	return @tools;
}

# Return distinct tools by drillsize + processtype
# Tools can be wrong defined!
# Parameter check is not done!
# This is used only for checking, when we want finale listo of diameters
#sub GetReducedTools {
#	my $self = shift;
#
#	my $mess = "";
#
#	# Tools, some can be duplicated
#	# Do distinst by "tool key" (drillSize + typeProcess)
#	my %seen;
#	my @toolsUniq = grep { !$seen{ $_->GetDrillSize() . $_->GetTypeProcess() }++ } @{ $self->{"tools"} };
#
#	my @tools = ();
#
#	foreach my $t (@toolsUniq) {
#
#		my $tNew = UniToolBase->new( $t->GetDrillSize(), $t->GetTypeProcess() );
#		push( @tools, $tNew );
#	}
#
#	return @tools;
#}

# Return UNIQUE tool by drillsize and type chain/hole
# Note 1: Unique tool is unique by pair: drill size + process type
# Note 2: All tools which are surface tool are considered as process type: TypeProc_CHAIN
sub GetTool {
	my $self        = shift;
	my $drillSize   = shift;
	my $typeProcess = shift;

	unless ($typeProcess) {
		$typeProcess = EnumsDrill->TypeProc_HOLE;
	}

	my $mess = "";

	my @tools = $self->GetUniqueTools();
	@tools = grep { $_->GetDrillSize() eq $drillSize && $_->GetTypeProcess() eq $typeProcess } @tools;

	if ( scalar(@tools) ) {

		return $tools[0];

	}
	else {

		return undef;
	}
}

# Return class for checking tool definition
sub GetChecks {
	my $self = shift;

	return $self->{"check"};
}

# Return object which contain pilot diameters for specified diameter
sub GetPilots {
	my $self      = shift;
	my $drillSize = shift;

	my @diameters = ();

	my $pDef = ( grep { $_->GetDrillSize() == $drillSize } @{ $self->{"pilotDefs"} } )[0];

	if ($pDef) {
		@diameters = $pDef->GetPilotDiameters();
	}

	return @diameters;
}

sub __InitUniDTM {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, $self->{"breakSR"} );
	my @DTMSurfTools = CamDTMSurf->GetDTMTools( $inCAM, $jobId, $step, $layer, $self->{"breakSR"} );
	

	# 1) Process tool from standard DTM

	foreach my $t (@DTMTools) {

		my $drillSize = $t->{"gTOOLdrill_size"};
		my $typeProc = $t->{"gTOOLshape"} eq "hole" ? EnumsDrill->TypeProc_HOLE : EnumsDrill->TypeProc_CHAIN;

		my $uniT = UniToolDTM->new( $drillSize, $typeProc, Enums->Source_DTM );

		# depth

		$uniT->SetDepth( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } );
		$uniT->SetMagazineInfo( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGINFO } );
		$uniT->SetTolMinus( $t->{"gTOOLmin_tol"} );
		$uniT->SetTolPlus( $t->{"gTOOLmax_tol"} );

		# special standard DTM property

		$uniT->SetTypeTool( $t->{"gTOOLtype"} );
		$uniT->SetTypeUse( $t->{"gTOOLtype2"} );
		$uniT->SetFinishSize( $t->{"gTOOLfinish_size"} );
		$uniT->SetToolNum( $t->{"gTOOLnum"} );

		push( @{ $self->{"tools"} }, $uniT );

	}

	# 2) Process tool from DTM surface

	foreach my $t (@DTMSurfTools) {

		my $drillSize = $t->{".rout_tool"};
		my $typeProc  = EnumsDrill->TypeProc_CHAIN;

		my $uniT = UniToolDTMSURF->new( $drillSize, $typeProc, Enums->Source_DTMSURF );

		# depth

		$uniT->SetDepth( $t->{ EnumsDrill->DTMatt_DEPTH } );
		$uniT->SetMagazineInfo( $t->{ EnumsDrill->DTMatt_MAGINFO } );

		# special  DTM  surface property
		$uniT->SetDrillSize2( $t->{".rout_tool2"} );
		$uniT->SetSurfacesId( $t->{"surfacesId"} );

		push( @{ $self->{"tools"} }, $uniT );
	}

	# 3) Set tool operation
	foreach my $uniT ( @{ $self->{"tools"} } ) {

		my $operation = CamDrilling->GetToolOperation( $inCAM, $jobId, $layer, $uniT->GetTypeProcess() );
		$uniT->SetToolOperation($operation);
	}

	# 4) Set special tool parameters
	$self->__LoadToolSpecMagazineXml();
	foreach my $t ( @{ $self->{"tools"} } ) {

		my $mInfo = $t->GetMagazineInfo();

		# load special tool
		if ( defined $mInfo && $mInfo ne "" ) {

			my $xmlTool = $self->{"magazineSpec"}->{"tool"}->{$mInfo};

			# if exist geven magazine info eg "6.5_90st";
			if ($xmlTool) {

				$t->SetSpecial(1);
				$t->SetAngle( $xmlTool->{"angle"} );
			}
		}
	}

	# 5) Add pilot hole definitions if tools diameter is bigger than 5.3mm
	$self->__AddPilotHolesDefinition( $inCAM, $jobId );

}

# Add pilot tool definitions
sub __AddPilotHolesDefinition {
	my $self = shift;

	my $inCAM = shift;
	my $jobId = shift;

	# Add pilot holes only for plated
	my $lType = CamHelper->LayerType( $inCAM, $jobId, $self->{"layer"} );

	if ( $lType ne "drill" ) {
		return 0;
	}

	# 1) add poliot diameters to big hole
	my $materialName = $self->{"materialName"};

	if ( $materialName =~ /AL_CORE|CU_CORE/i ) {

		# hole 4-6.5 add pilot hole 1.2mm
		my @tools1 =
		  grep { $_->GetDrillSize() >= 4000 && $_->GetDrillSize() <= 6500 && $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE }
		  @{ $self->{"tools"} };
		$self->__AddPilotHoles( \@tools1, 1200 );
	}
	else {

		# New version of pilot holes	27.1.2018
		# hole 4-6.5 add pilot hole 1.2mm
		my @tools1 =
		  grep { $_->GetDrillSize() >= 4000 && $_->GetDrillSize() <= 6500 && $_->GetTypeProcess() eq EnumsDrill->TypeProc_HOLE }
		  @{ $self->{"tools"} };
		$self->__AddPilotHoles( \@tools1, 1200 );
	}

	# 2) Go throught pilot holes and create their tool definition

	foreach my $pDef ( @{ $self->{"pilotDefs"} } ) {

		foreach my $d ( $pDef->GetPilotDiameters() ) {

			my $uniT = UniToolDTM->new( $d, EnumsDrill->TypeProc_HOLE, Enums->Source_DTM );

			push( @{ $self->{"tools"} }, $uniT );
		}
	}
}

# Add pilot hole to tool definitions
sub __AddPilotHoles {
	my $self      = shift;
	my @tools     = @{ shift(@_) };
	my $pilotHole = shift;

	foreach my $t (@tools) {

		my $pilotDef = PilotDef->new( $t->GetDrillSize() );
		$pilotDef->AddPilotDiameter($pilotHole);
		push( @{ $self->{"pilotDefs"} }, $pilotDef );
	}
}

sub __LoadToolsMagazine {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$self->__LoadToolDefMagazineXml();

	my $materialName = $self->{"materialName"};

	if ( $materialName =~ /^Hybrid$/i ) {

		# If material is hybrid, real used material is possible get only from stackup
		die "Stackup must exist to load tool magazine" unless ( JobHelper->StackupExist($jobId) );
		$materialName = JobHelper->GetHybridMatCode($jobId);
	}

	foreach my $t ( @{ $self->{"tools"} } ) {

		my $mInfo = $t->GetMagazineInfo();

		# load special tool
		if ( $t->GetSpecial() ) {

			my $xmlTool = $self->{"magazineSpec"}->{"tool"}->{$mInfo};

			# if exist geven magazine info eg "6.5_90st";
			if ($xmlTool) {

				# search magazine by materal of pcb
				my $m = undef;
				foreach my $magInfo ( @{ $xmlTool->{"magazine"} } ) {

					my $magMat = $magInfo->{"material"};

					if ( $materialName =~ /^$magMat/i ) {
						$m = $magInfo;
						last;
					}
				}

				if ( defined $m ) {

					$t->SetMagazine( $m->{"content"} );
				}
			}
		}

		# load default tool
		else {

			my $magazines = $self->{"magazineDef"}->{"tooloperation"}->{ $t->GetToolOperation() }->{"magazine"};

			if ( defined $magazines ) {
				my @mArr = @{$magazines};

				my $m = ( grep { $_->{"material"} =~ /^$materialName$/i } @mArr )[0];

				if ( defined $m ) {

					$t->SetMagazine( $m->{"content"} );
				}
			}

		}
	}
}

sub __LoadToolDefMagazineXml {
	my $self = shift;

	my $templPath1 = GeneralHelper->Root() . "\\Config\\MagazineDef.xml";
	my $templXml1  = FileHelper->Open($templPath1);

	$self->{"magazineDef"} = XMLin(
		$templXml1,

		ForceArray => 1,

		# KeepRoot   => 1
	);

}

sub __LoadToolSpecMagazineXml {
	my $self = shift;

	my $templPath2 = GeneralHelper->Root() . "\\Config\\MagazineSpec.xml";
	my $templXml2  = FileHelper->Open($templPath2);

	$self->{"magazineSpec"} = XMLin(
		$templXml2,

		#ForceArray => 1,
		# KeepRoot   => 1
	);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

