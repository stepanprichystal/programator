#-------------------------------------------------------------------------------------------#
# Description: Base class, responsible for creating "rule result sets" based od rules
# Rules are difined in classes, which inherit from this class
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::FilmCreator::BaseFilmCreator;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Rules::RuleSet';
use aliased 'Packages::Export::PlotExport::Rules::Rule';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Export::PlotExport::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}  = shift;    #board layers
	$self->{"jobId"}  = shift;    #board layers
	$self->{"layers"} = shift;

	my @rules = ();
	$self->{"rules"} = \@rules;

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );

	$self->__AddLayerTypes();

	#$self->__AddLayerSize();

	return $self;
}

sub _AddRule {
	my $self          = shift;
	my $orientation   = shift;
	my $plotLayerOnce = shift;

	my $rule = Rule->new( $orientation, $plotLayerOnce );

	push( @{ $self->{"rules"} }, $rule );

	return $rule;
}

# Method produce rule sets, based on rules and available job layers
sub _RunRules {
	my $self = shift;
	my $usedLayers = shift // [];    #layer name of layers used in other ruleset

	my @layers = @{ $self->{"layers"} };    # not processed layers
	my @rules  = @{ $self->{"rules"} };

	my @resultRules = ();

	my $ruleIdx = 0;
	my $rule;

	while ( scalar(@layers) ) {

		$rule = $rules[$ruleIdx];

		# process all layers, which suit to this layer
		my @results = $self->__RunRule( $rule, \@layers, $usedLayers );
		push(@resultRules, @results) if (@results);

		$ruleIdx++;

		# for sure, test if all layertypes are used
		if ( $ruleIdx == scalar(@rules) ) {
			last;
		}

	}

	return @resultRules;
}

sub __RunRule {
	my $self       = shift;
	my $rule       = shift;
	my $layers     = shift;    # not processed layers
	my $usedLayers = shift;

	my @resultRules = ();

	my $createRuleSet = 1;

	#create "Result set" based on this rule
	while ($createRuleSet) {

		# try create new result set
		my $ruleSet = RuleSet->new($rule);

		# go through all rule types
		my @ruleTypes = $rule->GetLayerTypes();
		foreach my $ruleLType (@ruleTypes) {

			# go through layer type and check if some layer match this "type"

			foreach my $layer ( @{$layers} ) {

				if ( $layer->{"used"} ) {
					next;
				}

				# skip layer if rule request plot layer only one
				if ( $rule->GetLayerPlotOnce() && grep { $_ eq $layer->{"name"} } @{$usedLayers} ) {
					next;
				}

				# set of conditions, if layer suits to rule
				if ( $layer->{"plotType"} eq $ruleLType ) {

					# check dimension

					my $y = $layer->{"pcbSize"}->{"ySize"};
					my $x = $layer->{"pcbSize"}->{"xSize"};

					#check if is possible to plot

					if ( $rule->GetOrientation() eq Enums->Ori_VERTICAL ) {

						my $xSum = $x + $ruleSet->GetWidth();


						# text if pcb size exceeds fil dimension
						if ( $xSum > Enums->FilmSize_SmallX || $y > Enums->FilmSize_SmallY ) {
							next;
						}

						$ruleSet->SetDimenison( Enums->FilmSize_Small );
						 
# Big film: Enums->FilmSize_Big was canceled 11.6.2020
#			
#						# text if pcb size exceeds fil dimension
#						if ( $xSum > Enums->FilmSize_BigX || $y > Enums->FilmSize_BigY ) {
#							next;
#						}
#
#						if ( $y > Enums->FilmSize_SmallY ) {
#							$ruleSet->SetDimenison( Enums->FilmSize_Big );
#						}
#						else {
#							$ruleSet->SetDimenison( Enums->FilmSize_Small );
#						}


					}
					elsif ( $rule->GetOrientation() eq Enums->Ori_HORIZONTAL ) {

						# text if pcb size exceeds fil dimension
						if ( $y > Enums->FilmSize_SmallX || $x > Enums->FilmSize_SmallY ) {
							next;
						}
						
						$ruleSet->SetDimenison( Enums->FilmSize_Small );

# Big film: Enums->FilmSize_Big was canceled 11.6.2020
#
#						# text if pcb size exceeds fil dimension
#						if ( $y > Enums->FilmSize_BigX || $x > Enums->FilmSize_BigY ) {
#							next;
#						}
#						if ( $x > Enums->FilmSize_SmallY ) {
#							$ruleSet->SetDimenison( Enums->FilmSize_Big );
#						}
#						else {
#							$ruleSet->SetDimenison( Enums->FilmSize_Small );
#						}
	 
					}

					# add this type to result set
					$ruleSet->AddLayer($layer);
					$layer->{"used"} = 1;
					last;
				}
			}
		}

		unless ( $ruleSet->Complete() ) {

			# stop creating another ruleSets
			$createRuleSet = 0;

			# free used layers in resultset
			my @used = $ruleSet->GetLayers();

			foreach $_ (@used) {
				$_->{"used"} = 0;
			}

		}
		else {

			# add result set
			push( @resultRules, $ruleSet );

		}

	}

	return @resultRules;
}

sub __AddLayerTypes {
	my $self = shift;

	# add information about top/bot
	 

	foreach my $l ( @{ $self->{"layers"} } ) {

		if ( $l->{"name"} =~ /^pc2?/ ) {

			$l->{"plotType"} = Enums->LType_SILKTOP;

		}
		elsif ( $l->{"name"} =~ /^ps2?/ ) {
			$l->{"plotType"} = Enums->LType_SILKBOT;

		}
		elsif ( $l->{"name"} =~ /^mc2?/ ) {

			$l->{"plotType"} = Enums->LType_MASKTOP;

		}
		elsif ( $l->{"name"} =~ /^ms2?/ ) {
			$l->{"plotType"} = Enums->LType_MASKBOT;

		}
		elsif ( $l->{"name"} =~ /^(outer)?[cs]$/ ) {

			$l->{"plotType"} = Enums->LType_SIGOUTER;

		}
		elsif ( $l->{"name"} =~ /^(outer)?v\d+$/ ) {

			$l->{"plotType"} = Enums->LType_SIGINNER;

		}
		elsif ( $l->{"name"} =~ /^gold[cs]$/i ) {

			$l->{"plotType"} = Enums->LType_GOLDFINGER;

		}
		elsif ( $l->{"name"} =~ /^l[cs]$/i ) {

			$l->{"plotType"} = Enums->LType_PEELABLE;

		}
		elsif ( $l->{"name"} =~ /^plg[cs]$/i ) {

			$l->{"plotType"} = Enums->LType_VIAFILL;
		}
		else {

			$l->{"plotType"} = Enums->LType_ALL;
		}

	}

	# if layer has no type, it is unknown for rules, which combine layers into film
	# Thus remove it from list

	@{ $self->{"layers"} } = grep { defined $_->{"plotType"} } @{ $self->{"layers"} };
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
