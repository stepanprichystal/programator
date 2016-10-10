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
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#$self->{"pcbSize"} = shift;

	#$self->{"sizeFrame"} = shift;
	#$self->{"sizeType"} = shift;
	$self->{"layers"} = shift;

	my @rules = ();
	$self->{"rules"} = \@rules;

	my @resultRules = ();
	$self->{"resultRules"} = \@resultRules;

	$self->__AddLayerTypes();
	#$self->__AddLayerSize();

	return $self;
}

sub _AddRule {
	my $self = shift;
	my $orientation = shift;
	my $rule = Rule->new($orientation);

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

		# for sure, test if all layertypes are used
		if ( $ruleIdx == scalar(@rules) ) {
			last;
		}

	}

}

sub __RunRule {
	my $self   = shift;
	my $rule   = shift;
	my $layers = shift;    # not processed layers

	my $createResultSet = 1;

	#create "Result set" based on this rule
	while ($createResultSet) {

		# try create new result set
		my $resultSet = RuleResult->new($rule);

		# go through all rule types
		my @ruleTypes = $rule->GetLayerTypes();
		foreach my $ruleLType (@ruleTypes) {

			# go through layer type and check if some layer match this "type"

			foreach my $layer ( @{$layers} ) {

				if ( $layer->{"used"} ) {
					next;
				}

				# set of conditions, if layer suits to rule
				if ( $layer->{"plotType"} eq $ruleLType ) {

					# check dimension

					my $y = $layer->{"pcbSize"}->{"ySize"};
					my $x = $layer->{"pcbSize"}->{"xSize"};

					#check if is possible to plot

					if ( $rule->GetOrientation() eq Enums->Ori_VERTICAL ) {

						my $xSum = $x + $resultSet->GetTotalX();

						# text if pcb size exceeds fil dimension
						if ( $xSum > Enums->FilmSize_BigX || $y > Enums->FilmSize_BigY ) {
							next;
						}

						if ( $y > Enums->FilmSize_SmallY ) {
							$resultSet->SetDimenison( Enums->FilmSize_Big );
						}
						else {
							$resultSet->SetDimenison( Enums->FilmSize_Small );
						}

					}
					elsif ( $rule->{"position"} eq Enums->Ori_HORIZONTAL ) {

						# text if pcb size exceeds fil dimension
						if ( $y > Enums->FilmSize_BigX || $x > Enums->FilmSize_BigY ) {
							next;
						}
						if ( $x > Enums->FilmSize_SmallY ) {
							$resultSet->SetDimenison( Enums->FilmSize_Big );
						}
						else {
							$resultSet->SetDimenison( Enums->FilmSize_Small );
						}

					}

					# add this type to result set
					$resultSet->AddLayer($layer);
					$layer->{"used"} = 1;
					last;
				}
			}
		}

		unless ( $resultSet->Complete() ) {

			# stop creating another resultsets
			$createResultSet = 0;

			# free used layers in resultset
			my @used = $resultSet->GetLayers();

			foreach $_ (@used) {
				$_->{"used"} = 0;
			}

		}
		else {

			# add result set
			push( @{ $self->{"resultRules"} }, $resultSet );
		}

	}

}

sub __AddLayerTypes {
	my $self = shift;

	# add information about top/bot
	#CamMatrix->AddSideType( $self->{"layers"} );

	foreach my $l ( @{ $self->{"layers"} } ) {

		if ( $l->{"gROWname"} eq "pc" ) {

			$l->{"plotType"} = Enums->LType_SILKTOP;

		}
		elsif ( $l->{"gROWname"} eq "ps" ) {
			$l->{"plotType"} = Enums->LType_SILKBOT;

		}
		elsif ( $l->{"gROWname"} eq "mc" ) {

			$l->{"plotType"} = Enums->LType_MASKTOP;

		}
		elsif ( $l->{"gROWname"} eq "ms" ) {
			$l->{"plotType"} = Enums->LType_MASKBOT;

		}
		elsif ( $l->{"gROWname"} =~ /^[cs]$/ ) {

			$l->{"plotType"} = Enums->LType_SIGOUTER;

		}
		elsif ( $l->{"gROWname"} =~ /^v\d$/ ) {

			$l->{"plotType"} = Enums->LType_SIGINNER;
 
		}elsif ( $l->{"gROWname"} =~ /^gold[CS]$/i ) {

			$l->{"plotType"} = Enums->LType_GOLDFINGER;
 
		} 

	}
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
