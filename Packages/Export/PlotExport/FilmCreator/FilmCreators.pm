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
	my $self = shift;
	my $layers = shift;


	# We have to create deep copy of layer list for each "creator"
	# Because, some values are saved to each item of list and it will be influence creator each other

	my $layersMulti = dclone($layers);
	my $layersSingle =  dclone($layers);

	my $multi = MultiFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $layersMulti );
	# Single cerator create rules, based on results from multi creator
	my $single = SingleFilmCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $layersSingle, $multi);
	
	push( @{ $self->{"filmCreators"} }, $multi );
	push( @{ $self->{"filmCreators"} }, $single );
}

#-------------------------------------------------------------------------------------------#
# 	Methods, which are requested by Intefrace IFilmCreator
#-------------------------------------------------------------------------------------------#

sub GetRuleSets {
	my $self       = shift;
	my $creatorNum = shift;    # creator nums, start from number 1

	my @ruleSets;

	# if ceator number is not specified, return rulesets from all creators
	if ( !defined $creatorNum ) {

		foreach my $creator ( @{ $self->{"filmCreators"} } ) {

			my @sets = $creator->GetRuleSets();
			push( @ruleSets, @sets );
		}
	}
	else {

		if ( $creatorNum - 1 >= 0 ) {
			my $creator = @{ $self->{"filmCreators"} }[ $creatorNum - 1 ];
			@ruleSets = $creator->GetRuleSets();
		}

	}

	return @ruleSets;

}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;
#	use aliased 'Packages::InCAM::InCAM';
#	use aliased 'Packages::Export::PlotExport::FilmCreator::MultiFilmCreator';
#
#	use aliased 'CamHelpers::CamJob';
#	my $inCAM = InCAM->new();
#
#	my $jobId = "f13609";
#
#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
#
#	my $creator = MultiFilmCreator->new( $inCAM, $jobId, \@layers );

	#$creator->GetPlotterSets();

}

1;
