#-------------------------------------------------------------------------------------------#
# Description: Creator, which create sets, contain 1 layers - horizontal
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::SingleFilmCreator;
use base('Packages::Export::PlotExport::FilmCreator::BaseFilmCreator');

use Class::Interface;
&implements('Packages::Export::PlotExport::FilmCreator::IFilmCreator');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'Packages::Export::PlotExport::Enums';
use aliased 'Packages::Export::PlotExport::FilmCreator::Helper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;

	my $inCAM    = shift;    #board layers
	my $jobId    = shift;    #board layers
	my $layers   = shift;    #board layers
	my $smallLim = shift;
	my $bigLim   = shift;

	#my $pcbsizeProfile = shift; #board layers
	#my $pcbsizeFrame = shift; #board layers

	my $self = $class->SUPER::new( $inCAM, $jobId, $layers );
	bless $self;

	Helper->AddLayerPlotSize( Enums->Size_FRAME, $layers, $smallLim, $bigLim );

	return $self;
}

sub GetRuleSets {
	my $self       = shift;
	my $usedLayers = shift;    #layer name of layers used in other ruleset

	$self->__BuildRules();

	return $self->_RunRules($usedLayers);

}

sub __BuildRules {
	my $self = shift;
	my $rule;

 
	# Add rule, only if layer type "SILKTOP" is not already used in result set created by "multiCreator"
	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL, 1 );
	$rule->AddSingleTypes( Enums->LType_SILKTOP );

	# Add rule, only if layer type "SILKBOT" is not already used in result set created by "multiCreator"
	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL, 1 );
	$rule->AddSingleTypes( Enums->LType_SILKBOT );

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL );
	$rule->AddSingleTypes( Enums->LType_MASKTOP );

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL );
	$rule->AddSingleTypes( Enums->LType_MASKBOT );

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL );
	$rule->AddSingleTypes( Enums->LType_SIGOUTER );

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL );
	$rule->AddSingleTypes( Enums->LType_SIGINNER );

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL );
	$rule->AddSingleTypes( Enums->LType_GOLDFINGER );

	# add PEELABLE layers only  if is not already used in result set created by "multiCreator"

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL, 1 );
	$rule->AddSingleTypes( Enums->LType_PEELABLE );

	# add other layers only  if is not already used in result set created by "multiCreator"

	$rule = $self->_AddRule( Enums->Ori_HORIZONTAL, 1 );
	$rule->AddSingleTypes( Enums->LType_ALL );

}

# Tell if plot type is already used in rulesets created by "multi creator"
sub __PlotTypeUsed {
	my $self     = shift;
	my @ruleSets = @{ shift(@_) };
	my $plotType = shift;

	my $used = 0;

	foreach my $rulSet (@ruleSets) {

		my @ruleLayers = $rulSet->GetLayers();

		my @exist = grep { $_->{"plotType"} eq $plotType } @ruleLayers;

		if ( scalar(@exist) ) {

			$used = 1;
			last;
		}
	}
	return $used;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	#use aliased 'HelperScripts::DirStructure';

	#DirStructure->Create();

}

1;
