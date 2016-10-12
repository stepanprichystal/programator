
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PlotExport::PlotMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
use aliased 'Packages::Export::PlotExport::PlotSet::PlotSet';
use aliased 'Packages::Export::PlotExport::PlotSet::PlotLayer';
use aliased 'Packages::Export::PlotExport::OpfxCreator::OpfxCreator';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"layers"} = shift;

	my @creators = ();
	$self->{"filmCreators"} = \@creators;

	$self->{"opfxCreator"} = OpfxCreator->new($self->{"inCAM"}, $self->{"jobId"});

	$self->__InitCreators();

	return $self;
}

sub Run {
	my $self = shift;

	my @requested = @{ $self->{"layers"} };

	my @resultSets = ();

	foreach my $creator ( @{ $self->{"filmCreators"} } ) {

		my @sets = $creator->GetRuleSets();
		push( @resultSets, @sets );
	}

	# Filter possible resultsets
	# Take only theses, which contain layerfrom <layers>
	my @filterResultSets = ();

	foreach my $resultSet (@resultSets) {

		my $plot       = 1;
		my @ruleLayers = $resultSet->GetLayers();

		foreach my $rl (@ruleLayers) {

			my @exist = grep { $_->{"name"} eq $rl->{"gROWname"} } @requested;

			unless ( scalar(@exist) ) {
				$plot = 0;
				last;

			}
		}

		if ($plot) {
			push( @filterResultSets, $resultSet );
		}
	}

	# Create plotter sets
	$self->__InitOpfxCreator(\@filterResultSets);

	# Export
	$self->{"opfxCreator"}->Export();

}

sub __InitCreators {
	my $self = shift;

	my @layers = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );

	# Set rout mirror, compenyation

	my $multi = MultiFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, \@layers );

	push( @{ $self->{"filmCreators"} }, $multi );

}

sub __InitOpfxCreator {
	my $self       = shift;
	my @resultSets = @{ shift(@_) };

	foreach my $resultSet (@resultSets) {

		my $ori        = $resultSet->GetOrientation();
		my $size       = $resultSet->GetFilmSize();
		my @plotLayers = ();

		foreach my $l ( $resultSet->GetLayers() ) {

			my $lInfo = (grep { $_->{"name"} eq $l->{"gROWname"} } @{ $self->{"layers"} })[0] ;

			my $plotL = PlotLayer->new( $lInfo->{"gROWname"}, $lInfo->{"polarity"}, $lInfo->{"mirror"}, $lInfo->{"compensation"}, $l->{"pcbSize"}, $l->{"pcbLimits"} );

			push( @plotLayers, $plotL );

		}

		# create new plot set
		my $plotSet = PlotSet->new( $resultSet, \@plotLayers, $self->{"jobId"});

		$self->{"opfxCreator"}->AddPlotSet($plotSet);
	}

}

sub ExportItemsCount {
	  my $self = shift;

	  my $totalCnt = 0;

	  $totalCnt += 1;                      # getting sucesfully AOI manager
	  $totalCnt += $self->{"layerCnt"};    #export each layer

	  return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	  use aliased 'Packages::Export::PlotExport::PlotMngr';

	  use aliased 'Packages::InCAM::InCAM';

	  my $inCAM = InCAM->new();

	  my $jobId = "f13609";

	  my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	  foreach my $l (@layers) {

		  $l->{"polarity"}     = "positive";
		  $l->{"mirror"}       = 0;
		  $l->{"compensation"} = 0;
		  $l->{"name"}         = $l->{"gROWname"};
	  }

	  my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	  $mngr->Run();
}

1;

