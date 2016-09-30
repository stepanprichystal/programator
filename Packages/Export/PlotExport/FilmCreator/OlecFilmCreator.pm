#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::OlecFilmCreator;
use base('Packages::Export::PlotExport::FilmCreator::BaseFilmCreator');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	my @rules = ();
	$self->{"rules"} = \@rules;

	return $self;
}

sub GetPlotterSets {
	my $self = shift;

	$self->__BuildRules();

	#__CreateSets()
}

sub __BuildRules {
	my $self = shift;
	my $rule;

	# 1
	$rule = $self_AddRule ();
	$rule->AddSingleTypes( Enums->LType_SILKTOP, Enums->LType_SILKBOT);
 	# 2
 	$rule = $self_AddRule ();
	$rule->AddSingleTypes( Enums->LType_MASKTOP, Enums->LType_MASKBOT);
	# 3
	$rule = $self_AddRule ();
	$rule->AddSingleTypes( Enums->LType_SIGOUTER, Enums->LType_SIGOUTER);
	# 4
	$rule = $self_AddRule ();
	$rule->AddSingleTypes( Enums->LType_SIGINNER, Enums->LType_SIGINNER);
}



sub __CreateSets {
	my $self = shift;

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
