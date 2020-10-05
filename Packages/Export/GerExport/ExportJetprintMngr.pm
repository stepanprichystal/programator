
#-------------------------------------------------------------------------------------------#
# Description: Export of MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportJetprintMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Gerbers::Jetprint::Enums';
use aliased 'Packages::Gerbers::Jetprint::ExportFiles';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"jetInfo"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	if ( $self->{"jetInfo"}->{"exportGerbers"} ) {
 
		my $export = ExportFiles->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"jetInfo"}->{"fiducType"}, $self->{"jetInfo"}->{"rotation"} );
		$export->{"onItemResult"}->Add( sub { $self->__OnExportLayer(@_) } );

		$export->Run();
	}

	return 1;
}

sub __OnExportLayer {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Jetprint data");

	$self->{"onItemResult"}->Do($item);
}

# Return number of exported layers
sub GetExportLayerCnt {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $layerNum = 0;

	if ( $self->{"jetInfo"}->{"exportGerbers"} ) {

		$layerNum = scalar( grep { $_->{"gROWname"} =~ /^p[cs]$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId ) );
	}

	return $layerNum;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

