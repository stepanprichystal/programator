
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for MDI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::MDIExport::MDIMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;
use File::Copy;
use Log::Log4perl qw(get_logger :levels);

#local library
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::ExportFiles' => "ExportFilesTT";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class       = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $packageId   = __PACKAGE__;
	my $createFakeL = 0;
	my $self        = $class->SUPER::new( $inCAM, $jobId, $packageId, $createFakeL );
	bless $self;

	$self->{"layerCouples"}  = shift;    # array of hash (couple + export)
	$self->{"layerSettings"} = shift;    # hash of settings for each layer

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->__DeleteOldFiles();

	my $export = ExportFilesTT->new( $self->{"inCAM"}, $self->{"jobId"}, "panel" );
	$export->{"onItemResult"}->Add( sub { $self->__OnExportLayerTT(@_) } );

	# Get only couples to export
	my @lCouples = map { $_->{"couple"} } grep { $_->{"export"} } @{ $self->{"layerCouples"} };

	$export->Run( \@lCouples, $self->{"layerSettings"} );

	return 1;
}

sub __OnExportLayerTT {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Mdi data TT");

	$self->{"onItemResult"}->Do($item);
}

# Before export , delete MDI gerber and JetPrint gerber
sub __DeleteOldFiles {
	my $self = shift;

	my $jobId = $self->{"jobId"};

	my @file2del = ();

	# delete MDI files;

	my @f1 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDITT,        $jobId );
	my @f2 = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITTWAIT, $jobId );
	push( @file2del, @f1 );
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

	$totalCnt += scalar( grep { $_->{"export"} } @{ $self->{"layerCouples"} } );

	return $totalCnt;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::ETExport::ETMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "d229010";
	#
	#	my $et = ETMngr->new( $inCAM, $jobId, "panel", 1 );
	#
	#	$et->Run()

}

1;

