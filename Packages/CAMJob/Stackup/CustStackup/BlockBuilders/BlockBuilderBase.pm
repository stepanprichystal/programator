
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BlockBuilderBase;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Other::TableDrawing::Table::Style::BorderStyle';
use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
use aliased 'Packages::Other::TableDrawing::Table::Style::Color';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"tblMain"}     = shift;
	$self->{"stackupMngr"} = shift;
	$self->{"sectionMngr"} = shift;

	# Left border of section
	$self->{"secBorderStyle"} = BorderStyle->new();
	$self->{"secBorderStyle"}->AddEdgeStyle( "left", TblDrawEnums->EdgeStyle_SOLIDSTROKE, 0.3, Color->new( EnumsStyle->Clr_SECTIONBORDER ) );

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

