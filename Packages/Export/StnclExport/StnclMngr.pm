
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::StnclMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::NifExport::NifMngr';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Programs::StencilCreator::Helpers::Helper' => 'StencilHelper';
use aliased 'Programs::StencilCreator::Enums'           => 'StnclEnums';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportEtch';
use aliased 'Packages::Export::StnclExport::DataOutput::ExportLaser';

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

	# PROPERTIES

	my %stencilInfo = StencilHelper->GetStencilInfo($self->{"jobId"} );

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

			$export = ExportEtch->new( $inCAM, $jobId, $self->{"stencilThick"} );

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
		die "define item count";
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

