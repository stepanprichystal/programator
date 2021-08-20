
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::GerMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::PreExport::LayerInvert';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Export::GerExport::ExportGerMngr';
use aliased 'Packages::Export::GerExport::ExportPasteMngr';
use aliased 'Packages::Export::GerExport::ExportJetprintMngr';
use aliased 'Packages::Export::PreExport::FakeLayers';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId = __PACKAGE__;
	my $createFakeL = 1;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL);
	bless $self;
 
	$self->{"exportLayers"} = shift;
	$self->{"layers"}       = shift;
	$self->{"paste"}        = shift;
	$self->{"jetprintInfo"} = shift;

	$self->{"gerberMngr"} = ExportGerMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"exportLayers"}, $self->{"layers"} );
	$self->{"gerberMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	$self->{"pasteMngr"} = ExportPasteMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"paste"} );
	$self->{"pasteMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	$self->{"jetprintMngr"} = ExportJetprintMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"jetprintInfo"} );
	$self->{"jetprintMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	return $self;
}

sub Run {
	my $self = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 

	$self->__DeleteOldFiles();

	# Create fake layers which will be exported, but are created automatically
	#FakeLayers->CreateFakeLayers( $inCAM, $jobId );

	$self->{"gerberMngr"}->Run();
	$self->{"pasteMngr"}->Run();
	$self->{"jetprintMngr"}->Run();

	#  Remove fake layers after export
	#FakeLayers->RemoveFakeLayers( $inCAM, $jobId );

}

# Before export , delete MDI gerber and JetPrint gerber
sub __DeleteOldFiles {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	my @file2del = ();


	# delete Jet print files;

	my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_JETPRINT, $jobId );
	push( @file2del, @f2 );

	foreach (@file2del) {
		unless ( unlink($_) ) {
			die "Can not delete mdi file $_.\n";
		}
	}
}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += $self->{"exportLayers"}      ? 1 : 0;    #gerbers
	$totalCnt += $self->{"paste"}->{"export"} ? 1 : 0;    # paste
	$totalCnt += $self->{"jetprintMngr"}->GetExportLayerCnt();    # paste

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

