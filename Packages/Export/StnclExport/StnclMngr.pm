
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for export data for stencil production
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::StnclMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use utf8;
use strict;
use warnings;
use File::Copy;

#local library

use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Programs::Stencil::StencilCreator::Helpers::Helper' => 'StencilHelper';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportEtch';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportLaser';
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Packages::Pdf::ControlPdf::StencilControlPdf::ControlPdf';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"exportNif"}    = shift;
	$self->{"exportData"}   = shift;
	$self->{"exportPdf"}    = shift;
	$self->{"stencilThick"} = shift;
	$self->{"fiducInfo"}    = shift;

	# PROPERTIES

	my %stencilInfo = StencilHelper->GetStencilInfo( $self->{"jobId"} );

	$self->{"stencilInfo"} = \%stencilInfo;

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};



	# Export nif
	if ( $self->{"exportNif"} ) {

		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "o+1" );

		my %data = (
					 "stencilThick" => $self->{"stencilThick"},
					 "single_x"     => sprintf( "%.1f", abs( $lim{"xMax"} - $lim{"xMin"} ) ),
					 "single_y"     => sprintf( "%.1f", abs( $lim{"yMax"} - $lim{"yMin"} ) ),
					 "nasobnost"    => 1,
					 "zpracoval"    => CamAttributes->GetJobAttrByName( $inCAM, $jobId, "user_name" )
		);

		my $nif = NifMngr->new( $inCAM, $jobId, \%data );
		$nif->{"onItemResult"}->Add( sub { $self->__OnNifExport(@_) } );
		$nif->Run();
	}

	# Export data
	if ( $self->{"exportData"} ) {

		my $export = undef;

		if ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_ETCH ) {

			$export = ExportEtch->new( $inCAM, $jobId, $self->{"stencilThick"}, $self->{"fiducInfo"} );

		}
		elsif ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_LASER ) {

			$export = ExportLaser->new( $inCAM, $jobId );

		}
		elsif ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_DRILL ) {

			$export = ExportDrill->new( $inCAM, $jobId );

		}

		$export->{"onItemResult"}->Add( sub { $self->__OnDataExport(@_) } );

		$export->Output();

	}

	# Export pdf
	if ( $self->{"exportPdf"} ) {

		# choose language
		my $defLang = "en";

		my %inf = %{ HegMethods->GetCustomerInfo($jobId) };
 		
 		# 25 is CZ
		if ( $inf{"zeme"} eq 25 ) {
			$defLang = "cz";
		}
		
		# Decide if ptv user info to pdf
		my $note = CustomerNote->new( $inf{"reference_subjektu"} );
		my $userInfo = 1;
 
		if ($note->NoInfoToPdf()) {
			$userInfo = 0;
		}

		my $pdf = ControlPdf->new( $inCAM, $jobId, "o+1", $defLang, $userInfo );
		$pdf->Create();

		my $result1 = $self->_GetNewItem( "Preview image", "Export pdf" );
		my $mess1 = "";
		unless ( $pdf->CreatePreview( \$mess1 ) ) {
			$result1->AddError($mess1);
		}
		$self->_OnItemResult($result1);

		my $result2 = $self->_GetNewItem( "Produce data", "Export pdf" );
		my $mess2 = "";
		unless ( $pdf->CreatePreviewSingle( \$mess2 ) ) {
			$result2->AddError($mess2);
		}
		$self->_OnItemResult($result2);

		my $result3 = $self->_GetNewItem( "Finalisation", "Export pdf" );
		my $mess3 = "";
		unless ( $pdf->GeneratePdf( \$mess3 ) ) {
			$result2->AddError($mess3);
		}
		$self->_OnItemResult($result3);

		# copy  pdf control to archive
		my $outputPdf = $pdf->GetOutputPath();

		unless ( -e $outputPdf ) {
			die "Output pdf control doesnt exist. Failed to create control pdf.\n";
		}

		my $archivePath = JobHelper->GetJobArchive($jobId) . "zdroje\\" . $self->{"jobId"} . "-control.pdf";

		if ( -e $archivePath ) {
			unless ( unlink($archivePath) ) {
				die "Can not delete old pdf control file (" . $archivePath . "). Maybe file is still open.\n";
			}
		}

		copy( $outputPdf, $archivePath );
		unlink($outputPdf);

	}

}

sub __OnNifExport {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Export Nif");

	$self->_OnItemResult($item);

}

sub __OnDataExport {
	my $self = shift;
	my $item = shift;

	if ( $self->{"stencilInfo"}->{"tech"} eq StnclEnums->Technology_DRILL ) {

		$item->SetGroup("Export NC");
	}
	else {

		$item->SetGroup("Export gerbers");

	}

	$self->_OnItemResult($item);

}

sub TaskItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	if ( $self->{"exportNif"} ) {
		$totalCnt += 2;    # nif export contain 2 items
	}

	if ( $self->{"exportData"} ) {

		$totalCnt += 3;    # NC export OR gerbers
	}

	if ( $self->{"exportPdf"} ) {
		$totalCnt += 3;    # pdf export
	}

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::StnclMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $mngr = StnclMngr->new( $inCAM, $jobId, 1, 1, 0, 0.125 );
	$mngr->Run();
}

1;

