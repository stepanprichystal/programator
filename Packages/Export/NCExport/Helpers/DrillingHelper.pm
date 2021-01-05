#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Helpers::DrillingHelper;

#3th party library
use strict;
use warnings;

#local library
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
	my @nDrill        = ();    #normall through holes plated
	my @nFillDrill    = ();    #filed through holes plated
	my @cDrill        = ();    #core plated
	my @cFillDrill    = ();    #fill core plated
	my @bDrillTop     = ();    #blind holes top
	my @bDrillBot     = ();    #blind holes bot
	my @bFillDrillTop = ();    #filled blind holes top
	my @bFillDrillBot = ();    #filled blind holes bot
	my @fDrill        = ();    #frame drilling
	my @fcDrill       = ();    #core frame drilling
	my @fcPressDrill  = ();    #core frame drilling of press holes
	my @nMill         = ();    #normall mill slits
	my @bMillTop      = ();    #z-axis top mill slits
	my @bMillBot      = ();    #z-axis bot mill slits
	my @dcDrill       = ();    #drill corsses

	my @ncPar = ();
	foreach my $l (@layers) {

		#unless ($l) { next; }

		my $pom = EnumsGeneral->LAYERTYPE_plt_nDrill;

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill ) {

			push( @nDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill ) {

			push( @nFillDrill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop ) {
			push( @bDrillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot ) {
			push( @bDrillBot, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop ) {
			push( @bFillDrillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot ) {
			push( @bFillDrillBot, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill ) {
			push( @cDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill ) {
			push( @cFillDrill, $l );
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
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcDrill ) {
			push( @fcDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcPressDrill ) {
			push( @fcPressDrill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_plt_dcDrill ) {
			push( @dcDrill, $l );
		}
	}

	$info{ EnumsGeneral->LAYERTYPE_plt_nDrill }        = \@nDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_nFillDrill }    = \@nFillDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_cDrill }        = \@cDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_cFillDrill }    = \@cFillDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_bDrillTop }     = \@bDrillTop;
	$info{ EnumsGeneral->LAYERTYPE_plt_bDrillBot }     = \@bDrillBot;
	$info{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } = \@bFillDrillTop;
	$info{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } = \@bFillDrillBot;
	$info{ EnumsGeneral->LAYERTYPE_plt_fDrill }        = \@fDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_fcDrill }       = \@fcDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_fcPressDrill }  = \@fcPressDrill;
	$info{ EnumsGeneral->LAYERTYPE_plt_nMill }         = \@nMill;
	$info{ EnumsGeneral->LAYERTYPE_plt_bMillTop }      = \@bMillTop;
	$info{ EnumsGeneral->LAYERTYPE_plt_bMillBot }      = \@bMillBot;
	$info{ EnumsGeneral->LAYERTYPE_plt_dcDrill }       = \@dcDrill;

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
	my @nplt_nDrill    = ();    #normall npl drill
	my @nplt_nMill     = ();    #normall mill slits
	my @nplt_bMillTop  = ();    #z-axis top mill
	my @nplt_bMillBot  = ();    #z-axis bot mill
	my @nplt_rsMill    = ();    #rs mill before plating
	my @nplt_frMill    = ();    #milling frame
	my @nplt_cbMillTop = ();    #z-axis Top mill of core
	my @nplt_cbMillBot = ();    #z-axis Bop mill of core
	my @nplt_kMill     = ();    #milling of connector
	my @nplt_lcMill    = ();    #milling of template snim lak pro c
	my @nplt_lsMill    = ();    #milling of template snim lak pro s
	my @nplt_fMillSpec = ();    #Special milling (ramecke, dovrtani)

	my @nplt_cvrlycMill        = ();    #top coverlay mill
	my @nplt_cvrlysMill        = ();    #bot coverlay mill
	my @nplt_prepregMill       = ();    #prepreg mill
	my @nplt_stiffcMill        = ();    # milling for stiffener from side c
	my @nplt_stiffsMill        = ();    # milling for stiffener from side s
	my @nplt_bStiffcAdhMillTop = ();    # depth milling of top stiffener adhesive from top
	my @nplt_bStiffsAdhMillTop = ();    # depth milling of bot stiffener adhesive from top
	my @nplt_soldcMill         = ();    # milling of template for soldering coverlay from side c
	my @nplt_soldsMill         = ();    # milling of template for soldering coverlay from side s

	my @nplt_bstiffcMill = ();          # depth milling of stiffener from side c
	my @nplt_bstiffsMill = ();          # depth milling for stiffener from side s
	my @nplt_tapecMill   = ();          # milling of doublesided tape sticked from top
	my @nplt_tapesMill   = ();          # milling of doublesided tape sticked from bot
	my @nplt_tapebrMill  = ();          # milling of doublesided tape bridges after tape is pressed

	my @ncPar = ();
	foreach my $l (@layers) {

		#unless ($l) { next; }

		unless ( $l->{"type"} ) {
			next;
		}

		if ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nDrill ) {
			push( @nplt_nDrill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_nMill ) {
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
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillTop ) {
			push( @nplt_cbMillTop, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cbMillBot ) {
			push( @nplt_cbMillBot, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {
			push( @nplt_kMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lcMill ) {
			push( @nplt_lcMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_lsMill ) {
			push( @nplt_lsMill, $l );
		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_fMillSpec ) {
			push( @nplt_fMillSpec, $l );
		}

		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill ) {
			push( @nplt_cvrlycMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ) {
			push( @nplt_cvrlysMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill ) {
			push( @nplt_prepregMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcMill ) {
			push( @nplt_stiffcMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsMill ) {
			push( @nplt_stiffsMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bStiffcAdhMillTop ) {
			push( @nplt_bStiffcAdhMillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bStiffsAdhMillTop ) {
			push( @nplt_bStiffsAdhMillTop, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldcMill ) {
			push( @nplt_soldcMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_soldsMill ) {
			push( @nplt_soldsMill, $l );

		}

		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ) {
			push( @nplt_bstiffcMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ) {
			push( @nplt_bstiffsMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapecMill ) {
			push( @nplt_tapecMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapesMill ) {
			push( @nplt_tapesMill, $l );

		}
		elsif ( $l->{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapebrMill ) {
			push( @nplt_tapebrMill, $l );

		}

	}

	$info{ EnumsGeneral->LAYERTYPE_nplt_nDrill }            = \@nplt_nDrill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_nMill }             = \@nplt_nMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bMillTop }          = \@nplt_bMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bMillBot }          = \@nplt_bMillBot;
	$info{ EnumsGeneral->LAYERTYPE_nplt_rsMill }            = \@nplt_rsMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_frMill }            = \@nplt_frMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_cbMillTop }         = \@nplt_cbMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_cbMillBot }         = \@nplt_cbMillBot;
	$info{ EnumsGeneral->LAYERTYPE_nplt_kMill }             = \@nplt_kMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_lcMill }            = \@nplt_lcMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_lsMill }            = \@nplt_lsMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_fMillSpec }         = \@nplt_fMillSpec;
	$info{ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill }        = \@nplt_cvrlycMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_cvrlysMill }        = \@nplt_cvrlysMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_prepregMill }       = \@nplt_prepregMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_stiffcMill }        = \@nplt_stiffcMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_stiffsMill }        = \@nplt_stiffsMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bStiffcAdhMillTop } = \@nplt_bStiffcAdhMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bStiffsAdhMillTop } = \@nplt_bStiffsAdhMillTop;
	$info{ EnumsGeneral->LAYERTYPE_nplt_soldcMill }         = \@nplt_soldcMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_soldsMill }         = \@nplt_soldsMill;

	$info{ EnumsGeneral->LAYERTYPE_nplt_bstiffcMill } = \@nplt_bstiffcMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_bstiffsMill } = \@nplt_bstiffsMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_tapecMill }   = \@nplt_tapecMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_tapesMill }   = \@nplt_tapesMill;
	$info{ EnumsGeneral->LAYERTYPE_nplt_tapebrMill }  = \@nplt_tapebrMill;

	return %info;
}

#1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Packages::InCAM::InCAM;
	#my $inCAM = Packages::InCAM::InCAM->new();
	#DrillingHelper->GetStackupDrillingInfo( "f14742", $inCAM );

	#my $test = Connectors::HeliosConnector::HegMethods->GetMaterialType("F34140");

	#print $test;

}
1;

