#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::BaseFilmCreator;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::RuleResult';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	my @rules = ();
	$self->{"rules"} = \@rules;

	my @resultRules = ();
	$self->{"resultRules"} = \@resultRules;

	my @layers = ();
	$self->{"layers"} = \@layers;

	return $self;
}

 

sub _AddRule {
	my $self = shift;

	my $rule = Rule->new();

	push( @{ $self->{"rules"} }, $rule );

	return $rule;
}

sub _RunRules {
	my $self = shift;

	my @layers = @{ $self->{"layers"} };    # not processed layers
	my @rules  = @{ $self->{"rules"} };

	my $ruleIdx = 0;
	my $rule;

	while ( scalar(@layers) ) {

		$rule = $rules[$ruleIdx];

		# process all layers, which suit to this layer
		$self->__RunRule( $rule, \@layers );

		$ruleIdx++;

	}

}

sub __RunRule {
	my $self   = shift;
	my $rule   = shift;
	my $layers = shift;    # not processed layers

	my $resultSet = RuleResult->new();

	my @layerTypes = $rule->GetLayerTypes();

	foreach my $lType (@layerTypes) {

		# go through layer type and check if some layer match this "type"
		for ( my $i = 0 ; $i < scalar( ${$layers}[$i] ) ; $i++ ) {

			my $layer = ${$layers}[$i];

			if ( $layer->{"plotType"} eq $lType ) {

				# add this type to result set
				$resultSet->AddLayer($layer);

				# remove layer, bacause is already used in this Result set
				splice @{$layers}, $i, 1;

				last;

			}
		}
	}

	push( @{ $self->{"resultRules"} }, $resultSet );
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'HelperScripts::DirStructure';

	DirStructure->Create();

}

1;
