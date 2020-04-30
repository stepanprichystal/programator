#-------------------------------------------------------------------------------------------#
# Description:

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Other::TableDrawing::TableDrawing';
use aliased 'Packages::Other::TableDrawing::Enums'                  => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BorderStyle';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub DefaultSectionsLayout {
	my $self        = shift;
	my $secMngr     = shift;
	my $stackupMngr = shift;



	# Define styles

	my $leftEdgeBackg  = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 0,   0,   255 ) );
	my $rightEdgeBackg = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 0,   255, 255 ) );
	my $ncBackg        = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 100, 0,   255 ) );
	my $matTitleBackg  = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new(EnumsStyle->Clr_LEFTCLMNBACK ) );
	
	my $borderStyle = BorderStyle->new();
	$borderStyle->AddEdgeStyle( "left",  TblDrawEnums->EdgeStyle_DASHED, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ), 0.8, 0.9 );
	

	# Sec_BEGIN

	my $secBEGIN = $secMngr->AddSection( Enums->Sec_BEGIN );
	$secBEGIN->AddColumn( "leftMargin", 1, $matTitleBackg);
	$secBEGIN->AddColumn( "matTitle", EnumsStyle->ClmnWidth_matname, $matTitleBackg);
	$secBEGIN->AddColumn( "cuUsage",  EnumsStyle->ClmnWidth_culayer );

	# Sec_A_MAIN

	my $secA_MAIN = $secMngr->AddSection( Enums->Sec_A_MAIN );
	#$secA_MAIN->AddColumn( "leftEdge", EnumsStyle->ClmnWidth_overlap, $leftEdgeBackg );
	$secA_MAIN->AddColumn( "leftEdge", EnumsStyle->ClmnWidth_overlap, undef, $borderStyle );
	$secA_MAIN->AddColumn( "matType",  EnumsStyle->ClmnWidth_mattype );
	$secA_MAIN->AddColumn( "matThick", EnumsStyle->ClmnWidth_matthick );
	$secA_MAIN->AddColumn( "NCStartCol", EnumsStyle->ClmnWidth_ncdrill );

	my @NC = $stackupMngr->GetPlatedNC();

	foreach my $nc (@NC) {

		#$secA_MAIN->AddColumn( "nc_".$nc->{"gROWname"},          EnumsStyle->ClmnWidth_ncdrill, $ncBackg, undef );    # material type
			$secA_MAIN->AddColumn( "nc_".$nc->{"gROWname"},          EnumsStyle->ClmnWidth_ncdrill, undef, undef );    # material type
		$secA_MAIN->AddColumn( "nc_".$nc->{"gROWname"} . "_gap", EnumsStyle->ClmnWidth_ncdrill, undef,    undef );    # material type
	}

	#$secA_MAIN->AddColumn( "rightEdge", EnumsStyle->ClmnWidth_overlap, $rightEdgeBackg );
	$secA_MAIN->AddColumn( "rightEdge", EnumsStyle->ClmnWidth_overlap );

	# Sec_B_FLEX

	my $sec_B_FLEX = $secMngr->AddSection( Enums->Sec_B_FLEX );
	$sec_B_FLEX->AddColumn( "matType",  EnumsStyle->ClmnWidth_mattype, undef, $borderStyle );
	$sec_B_FLEX->AddColumn( "matThick", EnumsStyle->ClmnWidth_matthick );

	# Sec_C_RIGIDFLEX

	my $sec_C_RIGIDFLEX = $secMngr->AddSection( Enums->Sec_C_RIGIDFLEX );
	#$sec_C_RIGIDFLEX->AddColumn( "leftEdge",  EnumsStyle->ClmnWidth_overlap, $leftEdgeBackg );
	$sec_C_RIGIDFLEX->AddColumn( "leftEdge",  EnumsStyle->ClmnWidth_overlap, undef, $borderStyle );
	$sec_C_RIGIDFLEX->AddColumn( "matType",   EnumsStyle->ClmnWidth_mattype );
	$sec_C_RIGIDFLEX->AddColumn( "rightEdge", EnumsStyle->ClmnWidth_overlap );
	#$sec_C_RIGIDFLEX->AddColumn( "rightEdge", EnumsStyle->ClmnWidth_overlap, $rightEdgeBackg );

	# Sec_D_FLEXTAIL

	my $sec_D_FLEXTAIL = $secMngr->AddSection( Enums->Sec_D_FLEXTAIL );
	 
	$sec_D_FLEXTAIL->AddColumn( "matType",  EnumsStyle->ClmnWidth_mattype , undef, $borderStyle);
	$sec_D_FLEXTAIL->AddColumn( "matThick", EnumsStyle->ClmnWidth_matthick );

	# Sec_E_STIFFENER

	my $sec_E_STIFFENER = $secMngr->AddSection( Enums->Sec_E_STIFFENER );
	$sec_E_STIFFENER->AddColumn( "matType",  EnumsStyle->ClmnWidth_mattype , undef, $borderStyle);
	$sec_E_STIFFENER->AddColumn( "matThick", EnumsStyle->ClmnWidth_matthick );
	

	# Sec_END
	my $sec_END = $secMngr->AddSection( Enums->Sec_END );
	$sec_END->AddColumn( "end",  EnumsStyle->ClmnWidth_end , undef, $borderStyle);

	

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

