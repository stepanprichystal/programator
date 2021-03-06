
#-------------------------------------------------------------------------------------------#
# Description: Wizard step
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::WizardCore::WizardStep2;
use base('Programs::Coupon::CpnWizard::WizardCore::WizardStepBase');

use Class::Interface;
&implements('Programs::Coupon::CpnWizard::WizardCore::IWizardStep');

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardStep3';
use aliased 'Programs::Coupon::CpnSettings::CpnSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnSingleSettings';
use aliased 'Programs::Coupon::CpnSettings::CpnStripSettings';
use aliased 'Programs::Coupon::CpnSource::CpnSource';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnPolicy::GroupPolicy';
use aliased 'Programs::Coupon::CpnPolicy::GeneratorPolicy';
use aliased 'Programs::Coupon::CpnBuilder::CpnBuilder';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
my $PROCESS_END_EVT : shared;    # evt raise when processing reorder is done

sub new {
	my $class = shift;

	my $stepId = 2;
	my $title  = "Check global cpn settings, groups settings and strips settings";

	my $self = $class->SUPER::new( $stepId, $title );
	bless $self;

	# data model for step class
	$self->{"autogenerate"} = 1;    # allow automaticallz geenerate groups when user groups fail

	$self->{"cpnStripSett"} = {};   # strip settings for each strip

	$self->{"cpnGroupSett"} = {};   # group settings for each group

	return $self;
}

sub Load {
	my $self               = shift;
	my $oldConfig          = shift // 0;
	my $oldConfigGroupSett = shift;
	my $oldConfiStripSett  = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %constrFilter = %{ $self->GetConstrFilter() };
	my @constr = grep { $constrFilter{$_} } keys %constrFilter;

	my @uniqGroups = $self->GetUniqueGroups();

	# Default config settings
	if ( !$oldConfig ) {

		# 1) Define settings for each group

		for ( my $i = 0 ; $i < scalar(@uniqGroups) ; $i++ ) {

			$self->{"cpnGroupSett"}->{ $uniqGroups[$i] } = CpnSingleSettings->new();
		}

		# 2) Define strip settings for each strip

		# Default settings
		for ( my $i = 0 ; $i < scalar(@constr) ; $i++ ) {

			$self->{"cpnStripSett"}->{ $constr[$i] } = CpnStripSettings->new();
		}

		# 3) Set dynamically other settings
		my $isol = JobHelper->GetIsolationByClass( CamJob->GetLimJobPcbClass( $inCAM, $jobId, "max" ) );
		if ( $isol > 0 ) {

			# Set value of min Pad2GND isolation according pcb costruction class
			for ( my $i = 0 ; $i < scalar(@constr) ; $i++ ) {

				$self->{"cpnStripSett"}->{ $constr[$i] }->SetPad2GND($isol);
			}

			# Set Pad GND symbol by isolation if symbol is "thermal"
			for ( my $i = 0 ; $i < scalar(@uniqGroups) ; $i++ ) {

				my $sym = $self->{"cpnGroupSett"}->{ $uniqGroups[$i] }->GetPadGNDSymNeg();
				if ( $sym =~ /^thr(\d+)x(\d+)x(\d+)x(\d+)x(\d+)$/ ) {

					my $outerSize = $2 + 2 * $isol;
					$sym =~ s/^thr(\d+)(x\d+x\d+x\d+x\d+)$/thr$outerSize$2/;

					$self->{"cpnGroupSett"}->{ $uniqGroups[$i] }->SetPadGNDSymNeg($sym);

				}

			}

			# Set GND via hole size for coplanar according smallest hole in o+1 step

			my @layers =
			  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_plt_nDrill, EnumsGeneral->LAYERTYPE_plt_nFillDrill ] );

			if (@layers) {
				my $min = CamDrilling->GetMinHoleToolByLayers( $inCAM, $jobId, "o+1", \@layers );

				$self->{"globalSett"}->SetGNDViaHoleSize($min);
			}
			
			# Set GND via hole size of annular ring for coplanar according min isolation
			if ( $isol > 0 ) {
	 
				$self->{"globalSett"}->SetGNDViaHoleRing($isol);
			}
			

		}
	}
	else {

		# 1) Define settings for each group
		$self->{"cpnGroupSett"} = $oldConfigGroupSett;

		# 2) Define strip settings for each strip
		$self->{"cpnStripSett"} = $oldConfiStripSett;

	}

}

sub Build {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	my $groupGenPolicy = GeneratorPolicy->new( $self->{"cpnSource"}, $self->{"globalSett"}->GetMaxTrackCnt() );

	# Create structure from strips and groups suitable for Layout algorithm
	my %constrFilter = %{ $self->GetConstrFilter() };
	my @constr = grep { $constrFilter{$_} } keys %constrFilter;

	my @comb = ();
	foreach my $g ( $self->GetUniqueGroups() ) {
		my @strips = map { $self->{"cpnSource"}->GetConstraint($_) } grep { $self->{"userGroups"}->{$_} == $g } @constr;

		push( @comb, \@strips );
	}

	my $combStruct = $groupGenPolicy->GenerateGroupComb( \@comb );

	# Create translate table (user group id => group id given by order)
	my %groupSettings = ();
	my @uniqGroups    = $self->GetUniqueGroups();
	for ( my $i = 0 ; $i < scalar(@uniqGroups) ; $i++ ) {

		$groupSettings{$i} = $self->{"cpnGroupSett"}->{ $uniqGroups[$i] };
	}

	# try build Cpnvariant
	my $variant =
	  Helper->GetBestGroupVariant( $self->{"cpnSource"}, [$combStruct], $self->{"globalSett"}, \%groupSettings );

	if ( !defined $variant && $self->{"autogenerate"} ) {

		$variant = Helper->GetBestGroupCombination( $self->{"cpnSource"}, \@constr, $self->{"globalSett"} );

		if ( !defined $variant ) {

			$$errMess .= "Unable to automatically generate coupon. Change settings or create more groups.";
			$result = 0;

		}
		else {

			# 1) update constr gorups
			my @singleCpns = $variant->GetSingleCpns();

			for ( my $i = 0 ; $i < scalar(@singleCpns) ; $i++ ) {

				foreach my $strip ( $singleCpns[$i]->GetAllStrips() ) {
					$self->UpdateConstrGroup( $strip->Id(), $i );
				}
			}

			# 2) create new settings for group and strips
			$self->Load();

			%groupSettings = ();
			my @uniqGroups = $self->GetUniqueGroups();
			for ( my $i = 0 ; $i < scalar(@uniqGroups) ; $i++ ) {

				$groupSettings{$i} = $self->{"cpnGroupSett"}->{ $uniqGroups[$i] };
			}

		}
	}
	elsif ( !defined $variant && !$self->{"autogenerate"} ) {

		$$errMess .= "Unable to generate coupon. Some microstrips don't fit inside a single group. Allow option:  Generate automatically new coupon.";
		$result = 0;
	}

	# variant was found
	if ( defined $variant ) {

		Helper->AddSett2CpnVarinat( $variant, $self->{"globalSett"}, \%groupSettings, $self->{"cpnStripSett"} );

		# Build layout

		my $inCAM = $self->{"inCAM"};
		my $jobId = $self->{"jobId"};

		my $builder = CpnBuilder->new( $inCAM, $jobId, $self->{"cpnSource"} );
		if ( $builder->Build( $variant, $errMess ) ) {
			my $layout = $builder->GetLayout();

			$self->{"nextStep"} = WizardStep3->new( $layout, $variant );
			$self->{"nextStep"}->Init( $self->{"inCAM"},      $self->{"jobId"},      $self->{"cpnSource"}, $self->{"userFilter"},
									   $self->{"userGroups"}, $self->{"globalSett"}, $self->{"asyncWorker"} );

		}
		else {

			$result = 0;
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Update method - update wizard step data model
#-------------------------------------------------------------------------------------------#
sub UpdateConstrFilter {
	my $self     = shift;
	my $constrId = shift;
	my $selected = shift;

	$self->{"userFilter"}->{$constrId} = $selected;
}

sub UpdateAutogenerate {
	my $self          = shift;
	my $autogenereate = shift;

	$self->{"autogenerate"} = $autogenereate;
}

#-------------------------------------------------------------------------------------------#
# Get data from model -
#-------------------------------------------------------------------------------------------#

# Return unique groups sorted ASC
sub GetUniqueGroups {
	my $self = shift;

	my %constrFilter = %{ $self->GetConstrFilter() };
	my @constr = grep { $constrFilter{$_} } keys %constrFilter;

	my $constrGroups = $self->GetConstrGroups();
	my @uniqGroups = uniq( map { $constrGroups->{$_} } grep { $constrFilter{$_} } keys %constrFilter );

	@uniqGroups = sort { $a <=> $b } @uniqGroups;

	return @uniqGroups;
}

sub GetAutogenerate {
	my $self = shift;

	return $self->{"autogenerate"};
}

sub GetGroupSettings {
	my $self    = shift;
	my $groupId = shift;

	return $self->{"cpnGroupSett"}->{$groupId};
}

sub GetStripSettings {
	my $self    = shift;
	my $stripId = shift;

	return $self->{"cpnStripSett"}->{$stripId};
}

sub GetAllGroupSettings {
	my $self = shift;

	return $self->{"cpnGroupSett"};
}

sub GetAllStripSettings {
	my $self = shift;

	return $self->{"cpnStripSett"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

