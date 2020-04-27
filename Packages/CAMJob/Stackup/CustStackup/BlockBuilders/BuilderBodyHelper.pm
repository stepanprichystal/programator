
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBodyHelper;

#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';

use constant stiff    => "stiff";
use constant stiffAdh => "stiffAdh";
use constant cvrl     => "cvrl";
use constant cvrlAdh  => "cvrlAdh";
use constant sm       => "sm";
use constant smFlex   => "smFlex";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"tblMain"}     = shift;
	$self->{"stackupMngr"} = shift;
	$self->{"sectionMngr"} = shift;

	return $self;
}

sub BuildRowsStackupOuter {
	my $self      = shift;
	my $outerSide = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	my %topSpec = ();

	$topSpec{stiff}    = $stckpMngr->GetExistStiff($outerSide);
	$topSpec{stiffAdh} = $stckpMngr->GetExistStiff($outerSide);
	$topSpec{cvrl}     = $stckpMngr->GetExistCvrl($outerSide);
	$topSpec{cvrlAdh}  = $stckpMngr->GetExistCvrl($outerSide);
	$topSpec{sm}       = $stckpMngr->GetExistSM($outerSide);
	$topSpec{smFlex}   = $stckpMngr->GetExistSMFlex($outerSide);

	# go from PCB nearest layer to most outer layer @r1 nearest layer, @r3 most oter layer
	my ( @r1, @r2, @r3 ) = ();
	my @topOuter = ( \@r1, \@r2, \@r3 );

	push( @{ $topOuter[0] }, sm )      if ( $topSpec{sm} );         # Solder mask alway on top Cu
	push( @{ $topOuter[0] }, cvrlAdh ) if ( $topSpec{cvrlAdh} );    # Coverlay adhesive alway on top Cu
	push( @{ $topOuter[0] }, smFlex )  if ( $topSpec{smFlex} );     # Solder mask Flex alway on top Cu

	# Add cvrl above cvrlAdh
	if ( $topSpec{cvrl} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Stiffener is on top Cu or above coverlay + coverlay adh
			if ( scalar( grep { $_ eq cvrlAdh } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[ $i + 1 ] }, cvrl );
			}
		}
	}

	if ( $topSpec{stiffAdh} ) {
		if ( $topSpec{cvrlAdh} ) {

			for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

				# Stiffener is on top Cu or above coverlay + coverlay adh
				if ( !scalar( grep { $_ eq cvrlAdh || $_ eq cvrl } @{ $topOuter[$i] } ) ) {
					push( @{ $topOuter[$i] }, stiffAdh );
					last;
				}
			}
		}
		else {

			push( @{ $topOuter[0] }, stiffAdh );    # Put stiffener adhesive on top cu
		}
	}

	# Add stiff above stiffAdh
	if ( $topSpec{stiff} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Stiffener is on top Cu or above coverlay + coverlay adh
			if ( scalar( grep { $_ eq stiffAdh } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[ $i + 1 ] }, stiff );
			}
		}
	}

	@topOuter = reverse(@topOuter) if ( $outerSide eq "top" );

	my %t = ();
	for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

		next unless ( scalar( @{ $topOuter[$i] } ) );

		my $row = $tblMain->AddRowDef( "outer_$outerSide" . "_" . ( $i + 1 ), EnumsStyle->RowHeight_STANDARD );

		foreach my $l ( @{ $topOuter[$i] } ) {
			$t{$l} = $row;
		}
	}

	return %t;

}

sub AddMaterialLayerGaps {
	my $self     = shift;
	my $startRow = shift;
	my $endRow   = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	my $sRow = $tblMain->GetRowDefPos($startRow);
	my $eRow = $tblMain->GetRowDefPos($endRow);

	my @rows = $tblMain->GetRowsDef();

	my $nameNext  = undef;
	my $matGapNum = 1;
	for ( my $i = $eRow - 1 ; $i > $sRow ; $i-- ) {

		my $name = $rows[$i]->GetKey();
		$nameNext = $rows[ $i + 1 ]->GetKey();

		my $addGapAbove = 1;

		if (    ( $name =~ /^copper_/ && defined $nameNext && $nameNext =~ /^core_/ )
			 || ( $name =~ /^core_/ && defined $nameNext && $nameNext =~ /^copper_/ ) )
		{
			$addGapAbove = 0;
		}

		if (    ( $name =~ /^prepreg_cvrl_adh/ && defined $nameNext && $nameNext =~ /^prepreg_cvr/ )
			 || ( $name =~ /^prepreg_cvr/ && defined $nameNext && $nameNext =~ /^prepreg_cvrl_adh/ ) )
		{
			$addGapAbove = 0;
		}
		if ( $name =~ /^outer_/ && defined $nameNext && $nameNext =~ /^outer_/ ) {
			$addGapAbove = 0;
		}

		if ($addGapAbove) {

			$tblMain->InsertRowDef( "matGap_$matGapNum", $i + 1, EnumsStyle->RowHeight_MATGAP );
			$matGapNum++;

		}

	}

}

sub AddPlatedDrilling {
	my $self = shift;

	my $tblMain   = $self->{"tblMain"};
	my $stckpMngr = $self->{"stackupMngr"};
	my $secMngr   = $self->{"sectionMngr"};

	return 0 unless ( $secMngr->GetSection( Enums->Sec_A_MAIN )->GetIsActive() );

	# Do not add Drill, when PCB is not plated
	my $type = $stckpMngr->GetPcbType();

	return 0
	  if (    $type eq EnumsGeneral->PcbType_NOCOPPER
		   || $type eq EnumsGeneral->PcbType_1V
		   || $type eq EnumsGeneral->PcbType_1VFLEX );

	my $txtStandardStyle = TextStyle->new( TblDrawEnums->TextStyle_LINE,
										   EnumsStyle->TxtSize_STANDARD,
										   Color->new( 255, 255, 255 ),
										   TblDrawEnums->Font_BOLD, undef,
										   TblDrawEnums->TextHAlign_CENTER,
										   TblDrawEnums->TextVAlign_TOP );

	my $backgStyle = BackgStyle->new( TblDrawEnums->BackgStyle_SOLIDCLR, Color->new( EnumsStyle->Clr_NCDRILL ) );

	# Sorted plated drilling
	my @NC = $stckpMngr->GetPlatedNC();

	my @colls = $tblMain->GetCollsDef();
	my @rows  = $tblMain->GetRowsDef();

	my @letters = ( "A" .. "Z" );
	foreach my $ncL (@NC) {

		my $start = $ncL->{"gROWdrl_dir"} eq "bot2top" ? $ncL->{"NCSigEndOrder"}   : $ncL->{"NCSigStartOrder"};
		my $end   = $ncL->{"gROWdrl_dir"} eq "bot2top" ? $ncL->{"NCSigStartOrder"} : $ncL->{"NCSigEndOrder"};

		my $sRowPos = $tblMain->GetRowDefPos( $tblMain->GetRowByKey("copper_$start") );
		my $eRowPos = $tblMain->GetRowDefPos( $tblMain->GetRowByKey("copper_$end") );

		my $colPos = $secMngr->GetColumnPos( Enums->Sec_A_MAIN, "nc_" . $ncL->{"gROWname"} );

		my $let = shift @letters;

		$tblMain->AddCell( $colPos, $sRowPos, 1, $eRowPos - $sRowPos + 1, $let, $txtStandardStyle, $backgStyle );

	}
}

1;

