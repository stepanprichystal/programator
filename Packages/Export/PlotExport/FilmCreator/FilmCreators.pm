#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::FilmCreators;

use Class::Interface;
&implements('Packages::Export::PlotExport::FilmCreator::IFilmCreator');

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library
use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
use aliased 'Packages::Export::PlotExport::FilmCreator::SingleFilmCreator';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	my @rules = ();
	$self->{"filmCreators"} = \@rules;

	return $self;
}

sub Init {
	my $self     = shift;
	my $layers   = shift;
	my $smallLim = shift;
	my $bigLim   = shift;

	# We have to create deep copy of layer list for each "creator"
	# Because, some values are saved to each item of list and it will be influence creator each other

	my $layersMulti  = dclone($layers);
	my $layersSingle = dclone($layers);

	# add reference on arraz where rulesets is stored (rulesets where layer is present in)
	for ( my $i = 0 ; $i < scalar( @{$layers} ) ; $i++ ) {

		my @ruleSet = ();
		$layersMulti->[$i]->{"inRuleSets"}  = \@ruleSet;
		$layersSingle->[$i]->{"inRuleSets"} = \@ruleSet;
	}

	my $multi = MultiFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $layersMulti, $smallLim, $bigLim );

	# Single cerator create rules, based on results from multi creator
	my $single = SingleFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $layersSingle, $smallLim, $bigLim, $multi );

	push( @{ $self->{"filmCreators"} }, $multi );
	push( @{ $self->{"filmCreators"} }, $single );
}

#-------------------------------------------------------------------------------------------#
# 	Methods, which are requested by Intefrace IFilmCreator
#-------------------------------------------------------------------------------------------#

sub GetRuleSets {
	my $self       = shift;
	my $creatorNum = shift;          # creator nums, start from number 1
	my $usedLayers = shift // [];    # consider only if $creatorNum defined

	my @ruleSets;

	# if ceator number is not specified, return rulesets from all creators
	if ( !defined $creatorNum ) {

		my @usedL = ();
		foreach my $creator ( @{ $self->{"filmCreators"} } ) {

			my @sets = $creator->GetRuleSets( \@usedL );

			push( @ruleSets, @sets );

			push( @usedL, map { $_->{"name"} } map { $_->GetLayers() } @ruleSets )
			  if (@ruleSets);    # Get used layers from first creator
		}
	}
	else {

		if ( $creatorNum - 1 >= 0 ) {
			my $creator = @{ $self->{"filmCreators"} }[ $creatorNum - 1 ];
			@ruleSets = $creator->GetRuleSets($usedLayers);
		}

	}

	return @ruleSets;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::Export::PlotExport::FilmCreator::FilmCreators';

	#	use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
	use aliased 'CamHelpers::CamJob';

	#	use aliased 'Packages::Export::PlotExport::FilmCreator::SingleFilmCreator'
	use aliased 'Packages::Export::PlotExport::FilmCreator::Helper';

	my $inCAM = InCAM->new();
	#
	my $jobId = "f81829";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	my $creator = MultiFilmCreator->new( $inCAM, $jobId, \@layers );

	#$creator->GetPlotterSets();

	my %smallLim = ();
	my %bigLim   = ();
	my @layers   = CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	my $fc = FilmCreators->new( $inCAM, $jobId );

	my $result = Helper->GetPcbLimits( $inCAM, $jobId, \%smallLim, \%bigLim );
	$fc->Init( \@layers, \%smallLim, \%bigLim );

	my @rs = $fc->GetRuleSets();

	print "test";

}

1;
