
#-------------------------------------------------------------------------------------------#
# Description: Responsible for prepariong pdf files with produce information
# and layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::OutputPdf;

#3th party library
use threads;
use strict;
use warnings;
use File::Copy;
use Time::localtime;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::OutputData::Enums' => "EnumsOutput";
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"filesDir"} = shift;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	$self->__PrepareStackup();

}

# Preapare stackup PDF if pcb is multilayer
sub __PrepareStackup {
	my $self = shift;

	if ( $self->{"layerCnt"} > 2 ) {

		my $stackup      = StackupPdf->new( $self->{"inCAM"}, $self->{"jobId"} );
		my $resultCreate = $stackup->Create(0,1,0);

		my $path = $stackup->GetStackupPath();
		move( $path, $self->{"filesDir"} . "\\" . $self->{"jobId"} . "stackup.pdf" );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
