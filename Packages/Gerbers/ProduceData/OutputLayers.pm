
#-------------------------------------------------------------------------------------------#
# Description: Output prepared layers as gerber
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Gerbers::ProduceData::OutputLayers;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Gerbers::Export::ExportLayers';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"filesDir"} = shift;

	return $self;
}

sub Output {
	my $self      = shift;
	my $layerList = shift;

	my @layers   = $layerList->GetLayers();
	my $stepName = $layerList->GetStepName();

	my @files = $self->__Export( \@layers, $stepName );

	return @files;

}

sub __Export {
	my $self     = shift;
	my @layers   = @{ shift(@_) };
	my $stepName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
 

	# function, which build output layer name, based on layer info

	my $resultItemGer = $self->_GetNewItem("Layers");

	my @hashLayers = ();

	foreach my $l (@layers) {
		
		# do not export layer, which doesnt't contain any symbol
		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $l->GetOutput() );
		
		if($fHist{"total"} == 0 ){
			next;
		}

		my %lInfo = (
					  "name"     => $l->GetOutput(),
					  "fileName" => $l->GetName()
		);
		push( @hashLayers, \%lInfo );
	}

	my $nameFunc = sub {

		my $l = shift;

		my $fileName = $l->{"fileName"} . ".ger";

		return $fileName;
	};

	ExportLayers->ExportLayers2( $resultItemGer, $inCAM, $stepName, \@hashLayers, $self->{"filesDir"}, $nameFunc, 1, 1 );

	$self->_OnItemResult($resultItemGer);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
