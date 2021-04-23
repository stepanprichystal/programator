
#-------------------------------------------------------------------------------------------#
# Description: Export of MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportMdiMngr;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::Enums';
use aliased 'Packages::Gerbers::Mdi::ExportFiles::ExportFiles';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::ExportFiles' => "ExportFilesTT";
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
	$self->{"mdiInfo"} = shift;

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	{
		my $export = ExportFiles->new( $self->{"inCAM"}, $self->{"jobId"}, "panel" );
		$export->{"onItemResult"}->Add( sub { $self->__OnExportLayer(@_) } );

		my %types = (
					  Enums->Type_SIGNAL => $self->{"mdiInfo"}->{"exportSignal"},
					  Enums->Type_MASK   => $self->{"mdiInfo"}->{"exportMask"},
					  Enums->Type_PLUG   => $self->{"mdiInfo"}->{"exportPlugs"},
					  Enums->Type_GOLD   => $self->{"mdiInfo"}->{"exportGold"}
		);

		$export->Run( \%types );
	}

#	{
#		my $export = ExportFilesTT->new( $self->{"inCAM"}, $self->{"jobId"}, "panel" );
#		$export->{"onItemResult"}->Add( sub { $self->__OnExportLayerTT(@_) } );
#
#		my %types = (
#					  Enums->Type_SIGNAL => $self->{"mdiInfo"}->{"exportSignal"},
#					  Enums->Type_MASK   => $self->{"mdiInfo"}->{"exportMask"},
#					  Enums->Type_PLUG   => $self->{"mdiInfo"}->{"exportPlugs"},
#					  Enums->Type_GOLD   => $self->{"mdiInfo"}->{"exportGold"}
#		);
#
#		$export->Run( \%types );
#	}

	return 1;
}

sub __OnExportLayer {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Mdi data");

	$self->{"onItemResult"}->Do($item);
}


sub __OnExportLayerTT {
	my $self = shift;
	my $item = shift;

	$item->SetGroup("Mdi data TT");

	$self->{"onItemResult"}->Do($item);
}

# Return number of exported layers
sub GetExportLayerCnt {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	my $layerNumber = 0;

	if ( $self->{"mdiInfo"}->{"exportSignal"} ) {

		my @l = grep { $_->{"gROWname"} =~ /^[csv]\d*$/ } @layers;
		$layerNumber += scalar(@l);
	}

	if ( $self->{"mdiInfo"}->{"exportMask"} ) {

		my @l = grep { $_->{"gROWname"} =~ /^m[cs]$/ } @layers;
		$layerNumber += scalar(@l);

	}

	if ( $self->{"mdiInfo"}->{"exportPlugs"} ) {

		my @l = grep { $_->{"gROWname"} =~ /^plg[cs]$/ } @layers;
		$layerNumber += scalar(@l);

	}

	if ( $self->{"mdiInfo"}->{"exportGold"} ) {

		my @l = grep { $_->{"gROWname"} =~ /^gold[cs]$/ } @layers;
		$layerNumber += scalar(@l);

	}

	return $layerNumber;

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

