#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Drilling::DrillingHelper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Drilling::DrillingHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Return soreted plated drilling in categories + info
# - every layer contains info about layer, which drilling start from
# - every layer contains info about layer, which drilling finish in
# - you can specify layers, which you want to return with @filter
sub GetPltNCLayerInfo {
	my $self     = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $inCAM    = shift;
	my @layers   = @{ shift(@_) };

	my %info = ();

	#get info which layer drilling/millin starts from/ end in
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	#get info, if file is splitted to more stages
	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $lname = $layers[$i]->{"gROWname"};
		$layers[$i]->{"stagesCnt"} = CamDrilling->GetStagesCnt( $jobId, $stepName, $lname, $inCAM );
	}

	#add info which layer drill start and stop in.
	#	my @ncInfo = ();
	#	foreach my $l (@startStop) {
	#		if ( grep { $_ eq $l->{"gROWname"} } @nc ) {
	#			push( @ncInfo, $l );
	#		}
	#	}

	#sort this layers by type
	my @nDrill    = ();    #normall through holes plated
	my @cDrill    = ();    #core plated
	my @bDrillTop = ();    #blind holes top
	my @bDrillBot = ();    #blind holes bot
	my @fDrill    = ();    #frame drilling
	my @nMill     = ();    #normall mill slits
	my @bMillTop  = ();    #z-axis top mill slits
	my @bMillBot  = ();    #z-axis bot mill slits
	my @dcDrill   = ();    #drill corsses

	my @ncPar = ();
	foreach my $l (@layers) {

		#unless ($l) { next; }

		unless ( $l->{"type"} ) {
			print 1;
		}

		my $pom = EnumsGeneral->LAYERTYPE_plt_nDrill;

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill ) {

			push( @nDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {
			push( @bDrillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {
			push( @bDrillBot, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
			push( @cDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill ) {
			push( @nMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillTop ) {
			push( @bMillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bMillBot ) {
			push( @bMillBot, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill ) {
			push( @fDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_dcDrill ) {
			push( @dcDrill, $l );
		}
	}

	$info{ EnumsGeneral->LAYERTYPE_plt_nDrill }    = \@nDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_cDrill }    = \@cDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } = \@bDrillTop;
	$info{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } = \@bDrillBot;
	$info{ EnumsGeneral->LAYERTYPE_plt_fDrill }    = \@fDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_nMill }     = \@nMill;
	$info{ EnumsGeneral->LAYERTYPE_plt_bMillTop }  = \@bMillTop;
	$info{ EnumsGeneral->LAYERTYPE_plt_bMillBot }  = \@bMillBot;
	$info{ EnumsGeneral->LAYERTYPE_plt_dcDrill }   = \@dcDrill;

	return %info;
}

# Return soreted nplated drilling in categories + info
# - every layer contains info about layer, which drilling start from
# - every layer contains info about layer, which drilling finish in
# - you can specify layers, which you want to return with @filter
sub GetNPltNCLayerInfo {
	my $self     = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $inCAM    = shift;
	my @layers   = @{ shift(@_) };

	my %info = ();

	#get info which layer drilling/millin starts from/ end in
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	#get info, if file is splitted to more stages
	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $lname = $layers[$i]->{"gROWname"};
		$layers[$i]->{"stagesCnt"} = CamDrilling->GetStagesCnt( $jobId, $stepName, $lname, $inCAM );
	}

	#add info which layer drill start and stop in.
	#	my @ncInfo = ();
	#	foreach my $l (@startStop) {
	#		if ( grep { $_ eq $l->{"gROWname"} } @nc ) {
	#			push( @ncInfo, $l );
	#		}
	#	}

	#sort this layers by type
	my @nplt_nMill     = ();    #normall mill slits
	my @nplt_bMillTop  = ();    #z-axis top mill
	my @nplt_bMillBot  = ();    #z-axis bot mill
	my @nplt_rsMill    = ();    #rs mill before plating
	my @nplt_frMill    = ();    #milling frame
	my @nplt_jbMillTop = ();    #z-axis Top mill of core
	my @nplt_jbMillBot = ();    #z-axis Bop mill of core
	my @nplt_kMill     = ();    #milling of connector

	my @ncPar = ();
	foreach my $l (@layers) {

		#unless ($l) { next; }

		unless ( $l->{"type"} ) {
			print 1;
		}

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
			push( @nplt_nMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillTop ) {
			push( @nplt_bMillTop, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bMillBot ) {
			push( @nplt_bMillBot, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {
			push( @nplt_rsMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_frMill ) {
			push( @nplt_frMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillTop ) {
			push( @nplt_jbMillTop, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_jbMillBot ) {
			push( @nplt_jbMillBot, $l );

		}elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
			push( @nplt_kMill, $l );

		}
	}

	$info{ EnumsGeneral->LAYERTYPE_nplt_nMill }     = \@nplt_nMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }  = \@nplt_bMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }  = \@nplt_bMillBot;
	$info{ EnumsGeneral->LAYERTYPE_nplt_rsMill }    = \@nplt_rsMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_frMill }    = \@nplt_frMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_jbMillTop } = \@nplt_jbMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_jbMillBot } = \@nplt_jbMillBot;
	$info{ EnumsGeneral->LAYERTYPE_nplt_kMill } 	= \@nplt_kMill;
	
	return %info;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use Packages::InCAM::InCAM;
	my $inCAM = Packages::InCAM::InCAM->new();
	DrillingHelper->GetStackupDrillingInfo( "f14742", $inCAM );

	#my $test = Connectors::HeliosConnector::HegMethods->GetMaterialType("F34140");

	#print $test;

}
1;
