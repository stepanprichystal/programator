
#-------------------------------------------------------------------------------------------#
# Description: Choose suitable machine for process given nc layers
# Each machine, can procces only some type of nc task such as drill/mill/depth drill with camreas etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::MachineMngr;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
use aliased 'Packages::Export::NCExport::Enums';
use aliased 'Enums::EnumsMachines';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
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

	$self->{"machines"} = ();
	$self->{"propTable"} = ();

	$self->__SetMachines();
	$self->__SetPropertyTable();
	
	return $self;
}

sub AssignMachines {
	my $self      = shift;
	my $opManager = shift;

	foreach my $op ( @{ $opManager->{"operItems"} } ) {

		my @propVec = $self->__GetParamsByOperation($op);

		my @machines = $self->__GetMachinesByProp( \@propVec );
 
		$op->SetMachines( \@machines );
		
		$opManager->ReduceMachines($op);
	}

}

# create vector of properties, which machine should have for process nc operation
sub __GetParamsByOperation {
	my $self      = shift;
	my $operationItem = shift;

	my $t = $self->{"propTable"};

	my $pcbType;

	if ( $self->{"layerCnt"} <= 2 ) {
		$pcbType = "sl";
	}
	else {
		$pcbType = "ml";
	}

	# vector of values: 1) DRILL 2)  DRILL DEPTH 3) ROUT 4) ROUT DEPTH 5) DRILL CROSSES 6) CAMERAS
	my @resVector = ( 0, 0, 0, 0, 0, 0 );

	foreach my $oDef ( @{$operationItem->{"operations"}} ) {
		my $layers = $oDef->GetLayers();

		if ( scalar( @{$layers} ) ) {

			foreach my $l ( @{$layers} ) {

				my $lVec = $t->{ $l->{"type"} }{$pcbType};

				for ( my $i = 0 ; $i < scalar( @{$lVec} ) ; $i++ ) {

					$resVector[$i] = $resVector[$i] || ${$lVec}[$i];

				}
			}
		}
	}

	return @resVector;
}


# Return machines, suitable for process given operation
sub __GetMachinesByProp {
	my $self    = shift;
	my @propVec = @{ shift(@_) };

	my $sumPropVec = 0;
	map { $sumPropVec += $_ } @propVec;

	my @machines = @{ $self->{"machines"} };
	my @suitable = ();

	foreach my $m (@machines) {
		my @result  = ();
		
		# create vector of machine's properties
		my @machVec = @{$m->{"properties"}};

		#do AND between Machine vector and Vector given by operation
		for ( my $i = 0 ; $i < scalar(@machVec) ; $i++ ) {
			$result[$i] = $machVec[$i] && $propVec[$i];
		}

		my $sumResVec = 0;
		map { $sumResVec += $_ } @result;

		if ( $sumPropVec == $sumResVec ) {

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

		$m{"suffix"}     = lc( shift @vals );
		$m{"id"}         = "machine_" . $m{"suffix"};
		$m{"names"}      = shift @vals;
		$m{"properties"} = \@vals;

		push( @machines, \%m );
	}

	close($f);

	$self->{"machines"} = \@machines;

}

# Table tells, what properties machines has to has, for manage process given layer
# Properties depand on pcb type Multilayer / single layer
sub __SetPropertyTable {
	my $self = shift;

	my %t = ();
	$self->{"propTable"} = \%t;

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
	$t{ EnumsGeneral->LAYERTYPE_plt_nMill }{"sl"} = [ 0, 0, 1, 0, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_bMillTop }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillTop }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillBot }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_bMillBot }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_dcDrill }{"ml"} = [ 0, 0, 0, 0, 1, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_dcDrill }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_plt_fDrill }{"ml"} = [ 1, 0, 0, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_plt_fDrill }{"sl"} = [ 1, 0, 0, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_nMill }{"ml"} = [ 0, 0, 1, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_nMill }{"sl"} = [ 0, 0, 1, 0, 0, 0 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_rsMill }{"ml"} = [ 0, 0, 1, 0, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_rsMill }{"sl"} = [ 0, 0, 1, 0, 0, 1 ];

	$t{ EnumsGeneral->LAYERTYPE_nplt_frMill }{"ml"} = [ 0, 0, 1, 0, 0, 0 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_frMill }{"sl"} = [ 0, 0, 0, 0, 0, 0 ];
	
	$t{ EnumsGeneral->LAYERTYPE_nplt_jbMillTop }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_jbMillTop }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_jbMillBot }{"ml"} = [ 0, 0, 0, 1, 0, 1 ];
	$t{ EnumsGeneral->LAYERTYPE_nplt_jbMillBot }{"sl"} = [ 0, 0, 0, 1, 0, 1 ];	
	
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

