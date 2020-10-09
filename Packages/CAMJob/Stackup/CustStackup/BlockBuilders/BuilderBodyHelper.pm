
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
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::TextStyle';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::Color';
use aliased 'Packages::Other::TableDrawing::TableLayout::StyleLayout::BackgStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';

use constant tapeStiff => "tapeStiff";
use constant stiff     => "stiff";
use constant stiffAdh  => "stiffAdh";
use constant tape      => "tape";
use constant cvrl      => "cvrl";
use constant cvrlAdh   => "cvrlAdh";
use constant sm        => "sm";
use constant smFlex    => "smFlex";

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

	$topSpec{tapeStiff} = $stckpMngr->GetExistTapeStiff($outerSide);
	$topSpec{stiff}     = $stckpMngr->GetExistStiff($outerSide);
	$topSpec{stiffAdh}  = $stckpMngr->GetExistStiff($outerSide);
	$topSpec{tape}      = $stckpMngr->GetExistTape($outerSide);
	$topSpec{cvrl}      = $stckpMngr->GetExistCvrl($outerSide);
	$topSpec{cvrlAdh}   = $stckpMngr->GetExistCvrl($outerSide);
	$topSpec{sm}        = $stckpMngr->GetExistSM($outerSide);
	$topSpec{smFlex}    = $stckpMngr->GetExistSMFlex($outerSide);

	# go from PCB nearest layer to most outer layer @r1 nearest layer, @r3 most oter layer
	# @r\d array contain more materials, which can be displayed in same row in stackup
	# (they are next to eaxh other not above/belov)
	my ( @r1, @r2, @r3, @r4, @r5 ) = ();
	my @topOuter = ( \@r1, \@r2, \@r3, \@r4, \@r5 );

	# 1) Add soldermask always directly to Copper
	push( @{ $topOuter[0] }, sm ) if ( $topSpec{sm} );    # Solder mask alway on top Cu

	# 2) Add flexible always soldermask directly to Copper
	push( @{ $topOuter[0] }, smFlex ) if ( $topSpec{smFlex} );    # Solder mask Flex alway on top Cu

	# 3) Add cvrl directly above cu OR sm
	if ( $topSpec{cvrl} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Stiffener is on top Cu or above coverlay + coverlay adh
			if ( !scalar( @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[$i] }, cvrlAdh );
				push( @{ $topOuter[$i+1] }, cvrl );
				last;
			}
			elsif ( scalar( grep { $_ eq sm } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[ $i + 1 ] }, cvrlAdh );
				push( @{ $topOuter[ $i + 2 ] }, cvrl );
				last;
			}
		}
	}

	# 4) Add stiff directly above cu OR sm
	if ( $topSpec{stiff} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			if ( !scalar( @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[$i] }, stiffAdh );
				push( @{ $topOuter[$i+1]  }, stiff );
				last;

			}
			elsif ( scalar( grep { $_ eq cvrl || $_ eq sm } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[ $i + 1 ] }, stiffAdh );
				push( @{ $topOuter[ $i + 2 ] }, stiff );
				last;
			}
		}
	}

	# 5) Add double sided tape
	if ( $topSpec{tape} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Add  on the same row as stiffener adh or above Cu or
			if ( scalar( grep { $_ eq stiffAdh } @{ $topOuter[$i] } ) || !scalar( @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[$i] }, tape );
				last;
			}
		}
	}

	# 6) Add double sided tape sticked to stiffener
	if ( $topSpec{tapeStiff} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Add  on the same row as stiffener adh or above Cu or
			if ( scalar( grep { $_ eq stiff } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[$i+1] }, tapeStiff );
				last;
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

