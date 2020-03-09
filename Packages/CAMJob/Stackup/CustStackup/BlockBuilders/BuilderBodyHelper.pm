
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

	if ( $topSpec{cvrlAdh} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Stiffener is on top Cu or above coverlay + coverlay adh
			if ( !scalar( grep { $_ eq cvrlAdh && $_ eq cvrl } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[$i] }, stiffAdh );
			}
		}
	}

	# Add cvrl above cvrlAdh
	if ( $topSpec{cvrl} ) {

		for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

			# Stiffener is on top Cu or above coverlay + coverlay adh
			if ( scalar( grep { $_ eq cvrlAdh } @{ $topOuter[$i] } ) ) {
				push( @{ $topOuter[ $i + 1 ] }, cvrl );
			}
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

	my %t = ();
	for ( my $i = 0 ; $i < scalar(@topOuter) ; $i++ ) {

		next unless(scalar(@{ $topOuter[$i] }));

		my $row = $tblMain->AddRowDef( $outerSide . "outer" . ( $i + 1 ), EnumsStyle->RowHeight_STANDARD );

		foreach my $l  (@{ $topOuter[$i] }){
			$t{$l} = $row
		} 
	}
	
	return %t;

}
 

1;

