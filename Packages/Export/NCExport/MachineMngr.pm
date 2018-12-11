
#-------------------------------------------------------------------------------------------#
# Description: Choose suitable machine for process given nc layers
# Each machine, can procces only some type of nc task such as drill/mill/depth drill with camreas etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::MachineMngr;

#3th party library
use strict;
use warnings;
use List::Util qw[max];

#use File::Copy;

#local library
use aliased 'Packages::Export::NCExport::Enums';
use aliased 'Enums::EnumsMachines';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepName"} = shift;
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{'inCAM'}, $self->{'jobId'} );

	$self->{"machines"}  = ();
	$self->{"propTable"} = ();

	$self->__SetMachines();
	$self->__SetStaticPropertyTable();

	return $self;
}

sub AssignMachines {
	my $self      = shift;
	my $opManager = shift;

	foreach my $op ( @{ $opManager->{"operItems"} } ) {

		my %propVec = $self->__GetPropertyVector($op);

		my @machines = $self->__GetMachinesByVector( \%propVec );

		$op->SetMachines( \@machines );

		$opManager->ReduceMachines($op);
	}

}

# create "vector of properties" for given NC operation,
# which machine should have for process nc operation
sub __GetPropertyVector {
	my $self          = shift;
	my $operationItem = shift;

	# Define "combine property functions" for each property
	# Function create new single property from two properties
	# These result property tells, which property machine has to have to process this NC operation

	# Example: - 1st layer has property DRILLDEPTH = 0
	#		   - 2nd layer has property DRILLDEPTH = 1
	# Function: sub { my ( $a, $b ) = @_; return $a | $b };
	# => Return 1, thus we need machine, which can "drill depth"

	my %comb = ();

	# $a - 1st layer property value
	# $b - 2nd layer property value

	$comb{ Enums->Property_DRILL }        = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_DRILLDEPTH }   = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_ROUT }         = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_ROUTDEPTH }    = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_DRILLCROSSES } = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_CAMERAS }      = sub { my ( $a, $b ) = @_; return $a | $b };
	$comb{ Enums->Property_MAXTOOL }      = sub { my ( $a, $b ) = @_; return max( $a, $b ) };
	$comb{ Enums->Property_MAXDEPTHTOOL } = sub { my ( $a, $b ) = @_; return max( $a, $b ) };

	# Result vector - final combination of all layers "property vectors"
	my %resVector     = ();
	my $resVectorInit = 0;

	# combine property vectors of all layers in "operation item"
	foreach my $oDef ( @{ $operationItem->{"operations"} } ) {
		my $layers = $oDef->GetLayers();

		if ( scalar( @{$layers} ) ) {

			# get  complete vector
			# combine property vectors of all layers in "operation definition"
			foreach my $l ( @{$layers} ) {

				# get  vector of property for this layer <$l>
				my %lVec          = ();
				my %staticVector  = $self->__GetStaticProperty( $l->{"type"} );
				my %dynamicVector = $self->__GetDynamicProperty($l);

				# vector for this layer
				%lVec = ( %staticVector, %dynamicVector );

				# init vector
				unless ($resVectorInit) {

					%resVector     = %lVec;
					$resVectorInit = 1;
					next;
				}

				# combine vector with preview "result" vector
				foreach my $propName ( keys %comb ) {

					# get new signle property value, from two property values
					$resVector{$propName} = $comb{$propName}->( $resVector{$propName}, $lVec{$propName} );
				}

			}
		}
	}

	return %resVector;
}

# Return machines, suitable for process given operation
sub __GetMachinesByVector {
	my $self     = shift;
	my %operProp = %{ shift(@_) };    # vector of operation property

	# Define "functions" which tell, if machine has requested property
	# Functions return 1, if so, else 0

	# Example: - operation vector has property DRILLDEPTH = 1
	#		   - specific machine has property DRILLDEPTH = 0
	# Function: sub { my ( $m, $o ) = @_; return (!$m && $o ? 0 : 1)};
	# => Return 0, thus this machine is not able to "drill depth"

	my %comb = ();

	# $m - "machine"
	# $o - "operation"

	$comb{ Enums->Property_DRILL }        = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_DRILLDEPTH }   = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_ROUT }         = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_ROUTDEPTH }    = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_DRILLCROSSES } = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_CAMERAS }      = sub { my ( $m, $o ) = @_; return ( !$m        && $o      ? 0 : 1 ) };
	$comb{ Enums->Property_MAXTOOL }      = sub { my ( $m, $o ) = @_; return ( defined $o && $m < $o ? 0 : 1 ) };
	$comb{ Enums->Property_MINTOOL }      = sub { my ( $m, $o ) = @_; return ( defined $o && $m > $o ? 0 : 1 ) };
	$comb{ Enums->Property_MAXDEPTHTOOL } = sub { my ( $m, $o ) = @_; return ( defined $o && $m < $o ? 0 : 1 ) };

	#my $sumPropVec = 0;
	#map { $sumPropVec += $_ } @propVec;

	my @machines = @{ $self->{"machines"} };
	my @suitable = ();                         #suitable machines

	foreach my $m (@machines) {
		my @result = ();

		# Get machine vector of property
		my %machProp = %{ $m->{"properties"} };

		my $machineSuit = 1;

		# check if machine suits to all requested property
		foreach my $propName ( keys %comb ) {

			# get result, if machine meets requirment
			my $res = $comb{$propName}->( $machProp{$propName}, $operProp{$propName} );

			unless ($res) {
				$machineSuit = 0;
				last;
			}
		}
		if ($machineSuit) {

			push( @suitable, $m );
		}
	}

	return @suitable;
}

# Load existing machines and their parameters from config file
sub __SetMachines {
	my $self = shift;

	my @machines = ();

	my $f;
	open( $f, "<" . GeneralHelper->Root() . EnumsPaths->Config_NCMACHINES );

	# Header of table is:
	# Group ID | Machines | rest are properties => 1) DRILL 2)  DRILL DEPTH 3) ROUT 4) ROUT DEPTH 5) DRILL CROSSES 6) CAMERAS

	while ( my $l = <$f> ) {

		chomp($l);

		if ( $l =~ /#/ || $l =~ /^[\r\n\t]$/ || $l eq "" ) {
			next;
		}

		my %m = ();
		my @vals = split( /\|/, $l );

		chomp @vals;
		map { $_ =~ s/[\t\s]//g } @vals;

		$m{"suffix"} = lc( shift @vals );
		$m{"id"}     = "machine_" . $m{"suffix"};
		$m{"names"}  = shift @vals;

		my %prop = ();
		$prop{ Enums->Property_DRILL }        = $vals[0];
		$prop{ Enums->Property_DRILLDEPTH }   = $vals[1];
		$prop{ Enums->Property_ROUT }         = $vals[2];
		$prop{ Enums->Property_ROUTDEPTH }    = $vals[3];
		$prop{ Enums->Property_DRILLCROSSES } = $vals[4];
		$prop{ Enums->Property_CAMERAS }      = $vals[5];
		$prop{ Enums->Property_MAXTOOL }      = $vals[6];
		$prop{ Enums->Property_MINTOOL }      = $vals[7];
		$prop{ Enums->Property_MAXDEPTHTOOL } = $vals[8];

		$m{"properties"} = \%prop;

		push( @machines, \%m );
	}

	close($f);

	$self->{"machines"} = \@machines;

}

# Return property, which are based on layer type
sub __GetStaticProperty {
	my $self      = shift;
	my $layerType = shift;

	my $pcbType;    # multi layer / 1,2 layer

	if ( $self->{"layerCnt"} <= 2 ) {
		$pcbType = "sl";
	}
	else {
		$pcbType = "ml";
	}

	# vector of static property
	my $vec = $self->{"propTable"}->{$layerType}{$pcbType};

	# create hash of property from this vector
	my %h = ();

	$h{ Enums->Property_DRILL }        = ${$vec}[0];
	$h{ Enums->Property_DRILLDEPTH }   = ${$vec}[1];
	$h{ Enums->Property_ROUT }         = ${$vec}[2];
	$h{ Enums->Property_ROUTDEPTH }    = ${$vec}[3];
	$h{ Enums->Property_DRILLCROSSES } = ${$vec}[4];
	$h{ Enums->Property_CAMERAS }      = ${$vec}[5];

	return %h;

}

# Return property, which are based on layer content
sub __GetDynamicProperty {
	my $self  = shift;
	my $layer = shift;

	# create hash of property from this vector
	my %h = ();

	my @tools = $layer->{"UniDTM"}->GetUniqueTools();

	my $maxStandard = undef;
	my $maxSpecial  = undef;
	my $minStandard = undef;

	for ( my $i = 0 ; $i < scalar(@tools) ; $i++ ) {

		if ( !$tools[$i]->GetSpecial() && ( !defined $maxStandard || $maxStandard < $tools[$i]->GetDrillSize() ) ) {
			$maxStandard = $tools[$i]->GetDrillSize();
		}

		if ( !$tools[$i]->GetSpecial() && ( !defined $minStandard || $minStandard > $tools[$i]->GetDrillSize() ) ) {
			$minStandard = $tools[$i]->GetDrillSize();
		}

		if ( $tools[$i]->GetSpecial() && ( !defined $maxSpecial || $maxSpecial < $tools[$i]->GetDrillSize() ) ) {
			$maxSpecial = $tools[$i]->GetDrillSize();
		}

	}

	# set max tool which is not special
	$h{ Enums->Property_MAXTOOL } = $maxStandard / 1000 if (defined $maxStandard);

	# get min tool which is not special
	$h{ Enums->Property_MINTOOL } = $minStandard / 1000 if (defined $minStandard);

	# set max tool which is  special
	$h{ Enums->Property_MAXDEPTHTOOL } = $maxSpecial / 1000 if (defined $maxSpecial);

	return %h;

}

# Table tells, what properties machines has to have, for manage process given layer
# Properties depand on pcb type Multilayer / single layer
sub __SetStaticPropertyTable {
	my $self = shift;

	my %t = ();
	$self->{"propTable"} = \%t;

	my $camera = 0;
	if ( JobHelper->GetIsFlex( $self->{"jobId"} ) ) {
		$camera = 1;
	}

	# Header is:
	# 1) DRILL
	# 2) DRILL DEPTH
	# 3) ROUT
	# 4) ROUT DEPTH
	# 5) DRILL CROSSES
	# 6) CAMERAS

	$t{ EnumsGeneral->LAYERTYPE_plt_nDrill }{"ml"} = [ 1, 0, 0, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_nDrill }{"sl"} = [ 1, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_bDrillTop }{"ml"} = [ 0, 1, 0, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bDrillTop }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bDrillBot }{"ml"} = [ 0, 1, 0, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bDrillBot }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_cDrill }{"ml"} = [ 1, 0, 0, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_cDrill }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_nMill }{"ml"} = [ 0, 0, 1, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_nMill }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_bMillTop }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillTop }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillBot }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillBot }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_dcDrill }{"ml"} = [ 0, 0, 0, 0, 1, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_dcDrill }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_fDrill }{"ml"} = [ 1, 0, 0, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_fDrill }{"sl"} = [ 1, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_nDrill }{"ml"} = [ 1, 0, 0, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_nDrill }{"sl"} = [ 1, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_nMill }{"ml"} = [ 0, 0, 1, 0, 0, $camera ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_nMill }{"sl"} = [ 0, 0, 1, 0, 0, $camera ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }{"ml"} = [ 0, 0, 0, 1, 0, $camera ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }{"sl"} = [ 0, 0, 0, 1, 0, $camera ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }{"ml"} = [ 0, 0, 0, 1, 0, $camera ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }{"sl"} = [ 0, 0, 0, 1, 0, $camera ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_rsMill }{"ml"} = [ 0, 0, 1, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_rsMill }{"sl"} = [ 0, 0, 1, 0, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_frMill }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_frMill }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_cbMillTop }{"ml"} = [ 0, 0, 0, 1, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_cbMillTop }{"sl"} = [ 0, 0, 0, 1, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_cbMillBot }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_cbMillBot }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_kMill }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_kMill }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_lcMill }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_lcMill }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_lsMill }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_lsMill }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_fMillSpec }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_fMillSpec }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill }{"ml"} = [ 0, 0, 0, 1, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill }{"sl"} = [ 0, 0, 0, 1, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_cvrlysMill }{"ml"} = [ 0, 0, 0, 1, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_cvrlysMill }{"sl"} = [ 0, 0, 0, 1, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_prepregMill }{"ml"} = [ 0, 0, 0, 1, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_prepregMill }{"sl"} = [ 0, 0, 0, 1, 0, 0 ];

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

