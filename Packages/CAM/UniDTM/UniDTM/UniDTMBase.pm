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
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAM::UniDTM::PilotDef::PilotDef';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"step"}    = shift;
	$self->{"layer"}   = shift;
	$self->{"breakSR"} = shift;

	my @pilots = ();
	$self->{"pilotDefs"} = \@pilots;

	$self->{"magazineDef"}  = undef;
	$self->{"magazineSpec"} = undef;

	$self->{"materialName"} = HegMethods->GetMaterialKind( $self->{"jobId"} );

	my @t = ();
	$self->{"tools"} = \@t;

	$self->__LoadMagazineXml();

	$self->__InitUniDTM();

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

# Return unique tool by drillsize and type chain/hole
sub GetTool {
	my $self        = shift;
	my $drillSize   = shift;
	my $typeProcess = shift;

	unless ($typeProcess) {
		$typeProcess = Enums->TypeProc_HOLE;
	}

	my $mess = "";

	 

	my @tools = $self->GetUniqueTools();
	@tools = grep { $_->GetDrillSize() eq $drillSize && $_->GetTypeProcess() eq $typeProcess } @tools;

	if ( scalar(@tools) ) {

		return $tools[0];

	}
	else {

		return 0;
	}
}

# Return class for checking tool definition
sub GetChecks {
	my $self = shift;

	return $self->{"check"};
}



# Return object which contain pilot diameters for specified diameter
sub GetPilots {
	my $self        = shift;
	my $drillSize   = shift;
	
	my @diameters = ();
	
	my $pDef = (grep { $_->GetDrillSize() == $drillSize } @{$self->{"pilotDefs"}})[0];	
	
	if($pDef){
		 @diameters = $pDef->GetPilotDiameters();
	}
 
	return @diameters;
}


sub __InitUniDTM {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
	my $layer = $self->{"layer"};

	my @DTMTools = CamDTM->GetDTMTools( $inCAM, $jobId, $step, $layer, $self->{"breakSR"} );
	my @DTMSurfTools = CamDTMSurf->GetDTMTools( $inCAM, $jobId, $step, $layer, $self->{"breakSR"} );

	# 1) Process tool from standard DTM

	foreach my $t (@DTMTools) {

		my $drillSize = $t->{"gTOOLdrill_size"};
		my $typeProc = $t->{"gTOOLshape"} eq "hole" ? Enums->TypeProc_HOLE : Enums->TypeProc_CHAIN;

		my $uniT = UniToolDTM->new( $drillSize, $typeProc, Enums->Source_DTM );

		# depth

		$uniT->SetDepth( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } );
		$uniT->SetMagazineInfo( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGINFO } );
		$uniT->SetTolPlus( $t->{"gTOOLmin_tol"} );
		$uniT->SetTolPlus( $t->{"gTOOLmax_tol"} );

		# special standard DTM property

		$uniT->SetTypeTool( $t->{"gTOOLtype"} );
		$uniT->SetTypeUse( $t->{"gTOOLtype2"} );
		$uniT->SetFinishSize( $t->{"gTOOLfinish_size"} );

		push( @{ $self->{"tools"} }, $uniT );

	}

	# 2) Process tool from DTM surface

	foreach my $t (@DTMSurfTools) {

		my $drillSize = $t->{".rout_tool"};
		my $typeProc  = Enums->TypeProc_CHAIN;

		my $uniT = UniToolDTMSURF->new( $drillSize, $typeProc, Enums->Source_DTMSURF );

		# depth

		$uniT->SetDepth( $t->{ EnumsDrill->DTMatt_DEPTH } );
		$uniT->SetMagazineInfo( $t->{ EnumsDrill->DTMatt_MAGINFO } );

		# special  DTM  surface property
		$uniT->SetDrillSize2( $t->{".rout_tool2"} );
		$uniT->SetSurfaceId( $t->{"id"} );

		push( @{ $self->{"tools"} }, $uniT );
	}

	# 3) Add pilot hole definitions if tools diameter is bigger than 5.3mm
	$self->__AddPilotHolesDefinition();

	# 4) Load magazine code by magazine info

	$self->__LoadToolsMagazine();

}

# Add pilot tool definitions (2.8mm + 4.6 mm) if tools diameter is bigger than 5.3mm
sub __AddPilotHolesDefinition {
	my $self = shift;
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	# Add pilot holes only for plated
	my $lType = CamHelper->LayerType($inCAM, $jobId, $self->{"layer"});
 
	if($lType ne "drill" ){
		return 0;
	}
 
	my @bigTools = grep { $_->GetDrillSize() > 5300 && $_->GetTypeProcess() eq Enums->TypeProc_HOLE } @{ $self->{"tools"} };

	# 1) add poliot diameters to big hole
	foreach my $t (@bigTools) {

		my $pilotDef = PilotDef->new( $t->GetDrillSize() );

		if ( $t->GetDrillSize() > 5300 ) {
			
			$pilotDef->AddPilotDiameter(1500);
			
			# From 8.6.2017 pilot 1500�m
			#$pilotDef->AddPilotDiameter(2800);
			#$pilotDef->AddPilotDiameter(4600);
		}

		push( @{ $self->{"pilotDefs"} }, $pilotDef );
	}

	# 2) Go throught pilot holes and add their tool definition

	foreach my $pDef ( @{ $self->{"pilotDefs"} } ) {

		foreach my $d ( $pDef->GetPilotDiameters() ) {

			my $uniT = UniToolDTM->new( $d, Enums->TypeProc_HOLE, Enums->Source_DTM );

			push( @{ $self->{"tools"} }, $uniT );
		}
	}
}

sub __LoadToolsMagazine {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	my $materialName = $self->{"materialName"};
	

	foreach my $t ( @{ $self->{"tools"} } ) {
		
		my $operation    = $self->__GetOperationByLayer($t);

		my $mInfo = $t->GetMagazineInfo();

		# load special tool
		if ( defined $mInfo && $mInfo ne "" ) {

			my $xmlTool = $self->{"magazineSpec"}->{"tool"}->{$mInfo};

			# if exist geven magazine info eg "6.5_90st";
			if ($xmlTool) {
				
				$t->SetSpecial(1);
				$t->SetAngle( $xmlTool->{"angle"} );

				my @mArr = @{ $xmlTool->{"magazine"} };
				my $matIs = $_->{"material"};
				my $m = ( grep { $materialName =~ /$matIs/i || $matIs =~ /$materialName/i } @mArr )[0];

				if ( defined $m ) {
					
					$t->SetMagazine( $m->{"content"} );
				}
			}
		}

		# load default tool
		else {

			unless ( defined $operation ) {
				next;
			}

			my @mArr = @{ $self->{"magazineDef"}->{"operation"}->{$operation}->{"magazine"} };
			my $m = ( grep { $_->{"material"} =~ /$materialName/i } @mArr )[0];

			if ( defined $m ) {

				$t->SetMagazine( $m->{"content"} );
			}
		}
	}
}

sub __GetOperationByLayer {
	my $self = shift;
	my $tool = shift;
	
	my $typeProc = $tool->GetTypeProcess();

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my %l     = ( "gROWname" => $self->{"layer"} );

	# add NC type
	my @lArr = ( \%l );
	CamDrilling->AddNCLayerType( \@lArr );

	# add layer type
	$l{"gROWlayer_type"} = CamHelper->LayerType( $inCAM, $jobId, $self->{"layer"} );

	my $operation = undef;
	
	

	if ( $l{"plated"} && $typeProc eq Enums->TypeProc_HOLE ) {

		$operation = "PlatedDrill";

	}
	elsif ( $l{"plated"} && $typeProc eq Enums->TypeProc_CHAIN ) {

		$operation = "PlatedRout";

	}
	elsif ( !$l{"plated"} && $typeProc eq Enums->TypeProc_HOLE ) {

		$operation = "NPlatedDrill";

	}
	elsif ( !$l{"plated"} && $typeProc eq Enums->TypeProc_CHAIN) {

		$operation = "NPlatedRout";

	}

	if ( $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
		$operation = "RoutBeforeEtch";
	}

	return $operation;
}

sub __LoadMagazineXml {
	my $self = shift;

	my $templPath1 = GeneralHelper->Root() . "\\Config\\MagazineDef.xml";
	my $templXml1  = FileHelper->Open($templPath1);

	$self->{"magazineDef"} = XMLin(
		$templXml1,

		ForceArray => 1,
		# KeepRoot   => 1
	);

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

