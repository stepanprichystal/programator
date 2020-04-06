
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BuilderMngrs::BuilderMngrBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"step"}    = shift;
	$self->{"tblMain"} = shift;

	return $self;
}

sub _AddBlock {
	my $self  = shift;
	my $block = shift;

	$block->Build();
}

sub _CreateSectionClmns {
	my $self        = shift;
	my $sectionMngr = shift;

	my @columns = map { $_->GetAllColumns() } $sectionMngr->GetAllSections();

	foreach my $sec ( $sectionMngr->GetAllSections(1) ) {

		foreach my $col ( $sec->GetAllColumns() ) {

			#			my $border = BorderStyle->new();
			#			$border->AddEdgeStyle( "left", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.1, Color->new( 0, 200, 0 ) );
			#			$col->{"borderStyle"} = $border;

			$self->{"tblMain"}->AddColDef( $sec->GetType() . "__" . $col->GetKey(), $col->GetWidth(), $col->GetBackgStyle(), $col->GetBorderStyle() );
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

