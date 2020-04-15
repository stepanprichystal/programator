#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::LamSTIFFPRODUCT;
use base('Packages::CAMJob::Stackup::ProcessStackup::BoxBuilders::BuilderMain::BuilderMainBase');

 
#3th party library
use strict;
use warnings;
use Time::localtime;
use Storable qw(dclone);
use List::Util qw(first);

#local library
#use aliased 'Enums::EnumsGeneral';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::Enums';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::EnumsStyle';
#use aliased 'Packages::Other::TableDrawing::Table::Style::TextStyle';
#use aliased 'Packages::Other::TableDrawing::Table::Style::Color';
#use aliased 'Packages::Other::TableDrawing::Table::Style::BackgStyle';
#use aliased 'Packages::Other::TableDrawing::Enums' => 'TblDrawEnums';
#use aliased 'Packages::CAMJob::Stackup::CustStackup::BlockBuilders::BuilderBodyHelper';
#use aliased 'Packages::Stackup::Enums' => 'StackEnums';
#use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"stckpBody"} = BuilderBodyHelper->new( $self->{"tblMain"}, $self->{"stackupMngr"}, $self->{"sectionMngr"} );

	return $self;
}

sub Build {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__BuildHeadRow();

	$self->__BuildStackupRows();

}
 
 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

