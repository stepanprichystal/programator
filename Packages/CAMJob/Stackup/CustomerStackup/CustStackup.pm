#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::Stackup::Enums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupBuilders::Builder1V';
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupBuilders::Builder2V';
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupBuilders::BuilderVV';
use aliased 'Packages::CAMJob::Stackup::CustStackup::StackupBuilders::BuilderRigidFlex';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"tblDraw"}     = TableDrawing->new();
	

	return $self;
}

sub Build {
	my $self = shift;




	# 2) Choose proper stackup builder
	my $builderMngr = undef;

	my $pcbType = CamHelper->GetPcbType( $self->{"jobId"} );

	if (    $pcbType eq EnumsGeneral->PcbType_NOCOPPER
		 || $pcbType eq EnumsGeneral->PcbType_1V
		 || $pcbType eq EnumsGeneral->PcbType_1VFLEX )
	{

		$builderMngr = BuilderMngr1V->new();
	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_2V
			|| $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	{

		$builderMngr = BuilderMngr2V->new();
	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_MULTI
			|| $pcbType eq EnumsGeneral->PcbType_2VFLEX )
	{

		$builderMngr = BuilderMngrVV->new();
	}
	elsif (    $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXO
			|| $pcbType eq EnumsGeneral->PcbType_RIGIDFLEXI )
	{

		$builderMngr = BuilderMngrRigidFlex->new();
	}
	else {

		die "Unknow type of pcb" . $pcbType;
	}

	$builderMngr->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"tblDraw"} );
	
	# 3) Define section style by builder and init sectiopn columns

	my $secMngr = $self->__GetSectionMngr();
	$builderMngr->BuildSections($secMngr);
	
 
	
	$builderMngr->Build($secMngr);

}

sub __GetSectionMngr {
	my $self = shift;

	my $secMngr = SectionStyleMngr->new();


	my $colCont = 0;

	#	my %stles = ();
	#			   Section_BEGIN       => "section_begin",          # Begining of table with material text
	#			   Section_A_MAIN      => "section_A_Main",         # Main stackup section with layer names and drilling
	#			   Section_B_FLEX      => "section_B_Flex",         # Flex part of RigidFlex pcb
	#			   Section_C_RIGIDFLEX => "section_C_RigidFlex",    # Second Rigid part of RigidFLex
	#			   Section_D_FLEXTAIL  => "section_D_FlexTail",     # Flexible tail of rigid flex section
	#			   Section_E_STIFFENER => "section_E_STIFFENER",    # Flex with stiffeners
	#			   Section_END         => "section_end"             # End of table

 
	# Section_BEGIN

	my $secBEGIN = $secMngr->AddSection( Enums->Section_BEGIN );
	$secBEGIN->AddColumn( "matTitle", 22 );
	$secBEGIN->AddColumn( "cuUsage",  22 );

	# Section_A_MAIN

	my $secA_MAIN = $secMngr->AddSection( Enums->Section_A_MAIN );
	$secBEGIN->AddColumn( undef,     10 );     # left margin
	$secBEGIN->AddColumn( "matType", 100 );    # material type
	
	return $secMngr;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

