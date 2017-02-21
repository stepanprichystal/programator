
#-------------------------------------------------------------------------------------------#
# Description: Contain listo of all tools in layer, regardless it is tool from surface, pad,
# lines..
# Responsible for tools are unique (diameter + typeProc)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniDTMBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::CAM::UniDTM::UniTool';
use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::UniDTM::UniDTMCheck';

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

	my @t = ();
	$self->{"tools"} = \@t;
	
	$self->{"check"} = UniDTMCheck->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, $self->{"layer"}, $self->{"breakSR"}, $self->{"tools"});

	$self->__InitUniDTM();

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

	unless ( $self->{"check"}->CheckTools(\$mess) ) {

		die "Tools definition in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}
	
	# Tools, some can be duplicated (eg surface can have same diameter like slot)
	my @tools =  @{$self->{"tools"}};
	
	return @tools;
}

# Return reduced unique tools
sub GetUniqueTools {
	my $self = shift;

	my $mess = "";

	unless ( $self->{"check"}->CheckTools(\$mess) ) {

		die "Tools definition in layer: " . $self->{"layer"} . " is wrong.\n $mess";
	}
	
	# Tools, some can be duplicated
	# Do distinst by "tool key" (drillSize + typeProcess)
	my %seen;
	my @toolsUniq = grep { !$seen{ $_->GetDrillSize().$_->GetTypeProcess() }++ } @{$self->{"tools"}};
	
	my @tools = ();
	
	foreach my $t (@toolsUniq){
		
		my $tNew = UniTool->new($t->GetDrillSize(), $t->GetTypeProcess());
		$tNew->SetDepth($t->GetDepth());
		$tNew->SetMagazine($t->GetMagazine());
		
		push(@tools, $tNew);
	}
 
	return @tools;
}

# Return unique tool by drillsize and type chain/hole
sub GetTool {
	my $self = shift;
	my $drillSize = shift;
	my $typeProcess = shift;
	
	 my $mess = "";

	my @tools = $self->GetUniqueTools();
	@tools = grep { $_->GetDrillSize() eq $drillSize && $_->GetTypeProcess() eq $typeProcess } @tools;
	
	if(scalar(@tools)){
		
		return $tools[0];

	}else{
		
		return 0; 
	}
}

# Return class for checking tool definition
sub GetChecks{
	my $self = shift;
	
	return $self->{"check"};
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

		my $uniT = UniTool->new( $drillSize, $typeProc, Enums->Source_DTM );

		# depth
 
		$uniT->SetDepth( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_DEPTH } );
		$uniT->SetMagazine( $t->{"userColumns"}->{ EnumsDrill->DTMclmn_MAGAZINE } );
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

		my $uniT = UniTool->new( $drillSize, $typeProc, Enums->Source_DTMSURF );

		# depth

		$uniT->SetDepth( $t->{ EnumsDrill->DTMatt_DEPTH } );
		$uniT->SetMagazine( $t->{ EnumsDrill->DTMatt_MAGAZINE } );

		# special  DTM  surface property
		$uniT->SetDrillSize2( $t->{".rout_tool2"} );
		$uniT->SetSurfaceId( $t->{"id"} );

		push( @{ $self->{"tools"} }, $uniT );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
 

}

1;

