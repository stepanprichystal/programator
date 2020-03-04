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
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub DefaultSectionsLayout {
	my $self        = shift;
	my $secMngr     = shift;
	my $stackupMngr = shift;

	my $colCont = 0;

	my $leftEdgeBackg  = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 0, 0,   255 ) );
	my $rightEdgeBackg = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 0, 255, 255 ) );
	my $ncBackg  = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( 100, 0,   255 ) );

	# Sec_BEGIN

	my $secBEGIN = $secMngr->AddSection( Enums->Sec_BEGIN );
	$secBEGIN->AddColumn( "matTitle", 20.7 );
	$secBEGIN->AddColumn( "cuUsage",  10 );

	# Sec_A_MAIN

	my $secA_MAIN = $secMngr->AddSection( Enums->Sec_A_MAIN );
	$secA_MAIN->AddColumn( "leftEdge", 1.6,  $leftEdgeBackg );
	$secA_MAIN->AddColumn( "matType",  16 );
	$secA_MAIN->AddColumn( "matThick", 10 );
	$secA_MAIN->AddColumn( "NC_left_gap", 1.15 );

	my @NC = $stackupMngr->GetPlatedNC();

	foreach my $nc (@NC) {

		$secA_MAIN->AddColumn( $nc->{"gROWname"},          1.15, $ncBackg, undef );    # material type
		$secA_MAIN->AddColumn( $nc->{"gROWname"} . "_gap", 1.15, undef, undef );    # material type
	}

	$secA_MAIN->AddColumn( "rightEdge", 1.6, $rightEdgeBackg );

	# Sec_B_FLEX

	my $sec_B_FLEX = $secMngr->AddSection( Enums->Sec_B_FLEX );
	$sec_B_FLEX->AddColumn( "matType",  16 );
	$sec_B_FLEX->AddColumn( "matThick", 10 );

	# Sec_C_RIGIDFLEX

	my $sec_C_RIGIDFLEX = $secMngr->AddSection( Enums->Sec_C_RIGIDFLEX );
	$sec_C_RIGIDFLEX->AddColumn( "leftEdge",  1.6,  $leftEdgeBackg );
	$sec_C_RIGIDFLEX->AddColumn( "matType",   20 );
	$sec_C_RIGIDFLEX->AddColumn( "rightEdge", 1.6, $rightEdgeBackg );

	# Sec_D_FLEXTAIL

	my $sec_D_FLEXTAIL = $secMngr->AddSection( Enums->Sec_D_FLEXTAIL );
	$sec_D_FLEXTAIL->AddColumn( "leftEdge", 1.6,  $leftEdgeBackg );
	$sec_D_FLEXTAIL->AddColumn( "matType",  16 );
	$sec_D_FLEXTAIL->AddColumn( "matThick", 10 );

	# Sec_E_STIFFENER

	my $sec_E_STIFFENER = $secMngr->AddSection( Enums->Sec_E_STIFFENER );
	$sec_E_STIFFENER->AddColumn( "matType",  16 );
	$sec_E_STIFFENER->AddColumn( "matThick", 10 );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

