
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationMngr::Helper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use List::Util qw[max min first];

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsDrill';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Smaller value means higher priority
# Layer with lower priority, will be processed by machine later, than layer with higher priority
# Example of final nc file:
# 1) File header
# 2) Layer blind top
# 3) Layer plated rout
# 4) Layer through drill
# 5) Tool definition (Footer)
sub SortLayersByRules {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my @ordered = ();

	my %priority = ();

	# plated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }    = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }     = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cFillDrill } = 0;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nFillDrill }    = 1030;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1030;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }    = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fcDrill }   = 1040;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop } = 1070;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot } = 1070;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }    = 1080;

	# nplted layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrill }      = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrillBot }      = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }    = 2020;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }    = 2030;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bstiffcMill } = 2040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bstiffsMill } = 2050;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMill }       = 2060;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMillBot }       = 2060;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_rsMill }      = 2070;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_frMill }      = 2080;

	#1) sort by priority bz tep of layer

	my @sorted = sort { $priority{ $b->{"type"} } <=> $priority{ $a->{"type"} } } @layers;

	#2) sort by unique number in layer, if layer such number contains
	# this provide functionality, that layers with lower number, will be
	# processed on NC machine before layer with higher number

	#split layers according same type
	my @splitted = ();

	my $lBefore;
	my @group = ();
	for ( my $i = 0 ; $i < scalar(@sorted) ; $i++ ) {

		my $l = $sorted[$i];

		if ( $lBefore->{"type"} && $lBefore->{"type"} eq $l->{"type"} ) {
			push( @group, $l );
		}
		else {
			if ( scalar(@group) ) {
				my @tmp = @group;
				push( @splitted, \@tmp );
			}
			@group = ();
			push( @group, $l );
		}
		$lBefore = $l;

		if ( $i == scalar(@sorted) - 1 ) {

			my @tmp = @group;
			push( @splitted, \@tmp );
		}
	}

	#now sort each group in @splitted
	for ( my $i = 0 ; $i < scalar(@splitted) ; $i++ ) {

		my $g = $splitted[$i];

		#add key (number in layer) to every item for sorting
		foreach ( @{$g} ) {
			my ($num) = $_->{"gROWname"} =~ m/[\D]*(\d*)/g;

			if ( $num eq "" ) { $num = 0; }

			$_->{"key"} = $num;
		}

		# sort layers example: fz_c3, fz_c1, fz_c2, => fz_c1, fz_c2, fz_c3
		my @sortedG = sort { $b->{"key"} <=> $a->{"key"} } @{$g};

		$splitted[$i] = \@sortedG;
	}

	#join splitted groups
	my @sorted2 = ();

	foreach my $g (@splitted) {

		push( @sorted2, @{$g} );
	}

	return @sorted2;
}

#Tell what file header will be used, when theese layers will be merged
sub GetHeaderLayer {
	my $self   = shift;
	my @layers = @{ shift(@_) };

	my %priority = ();

	# plated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_plt_dcDrill }    = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cDrill }     = 0;
	$priority{ EnumsGeneral->LAYERTYPE_plt_cFillDrill } = 0;

	$priority{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = 1010;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = 1020;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = 1020;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillTop }     = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bMillBot }     = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bstiffcMill } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bstiffsMill } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nMill }        = 1050;

	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } = 1040;
	$priority{ EnumsGeneral->LAYERTYPE_plt_nFillDrill }    = 1050;

	$priority{ EnumsGeneral->LAYERTYPE_plt_fcDrill } = 1090;
	$priority{ EnumsGeneral->LAYERTYPE_plt_fDrill }  = 1090;

	# nplated layer are merged together
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrill }   = 2060;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nDrillBot }   = 2060;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } = 2020;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } = 2030;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMill }    = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_nMillBot }    = 2010;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_rsMill }   = 2040;
	$priority{ EnumsGeneral->LAYERTYPE_nplt_frMill }   = 2050;

	my @sorted = sort { $priority{ $a->{"type"} } <=> $priority{ $b->{"type"} } } @layers;

	return $sorted[0];

}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

