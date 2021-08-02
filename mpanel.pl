#!/usr/bin/perl-w

#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

#necessary for load pall packages
use utf8;
use strict;
use warnings;

use File::Basename;

use aliased 'Helpers::GeneralHelper';

use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::CAMJob::Stackup::StackupDefault';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Programs::Panelisation::PnlWizard::RunPnlWizard::RunPnlWizard';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
my $inCAM = InCAM->new();

my $jobId = "$ENV{JOB}";

#$jobId = "d288860";

my $messMngr = MessageMngr->new("Panelizator - mpanel");

my @sig = CamJob->GetSignalLayerNames( $inCAM, $jobId );
my @sigInner = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1 );

while ( scalar(@sig) > 2 && !JobHelper->StackupExist($jobId) ) {

	my $constClass = CamJob->GetJobPcbClass( $inCAM, $jobId );
	my $constClassInn = CamJob->GetJobPcbClassInner( $inCAM, $jobId );
	my $outerThick    = HegMethods->GetOuterCuThick($jobId);
	my $pcbThick      = HegMethods->GetPcbMaterialThick($jobId) * 1000;

	my @innerCuUsage       = ();
	my @innerCuUsageFormat = ();

	foreach my $l (@sigInner) {

		my %area = ();
		my ($num) = $l =~ m/^v(\d+)$/;

		if ( $num % 2 == 0 ) {

			%area = CamCopperArea->GetCuArea( $outerThick, $pcbThick, $inCAM, $jobId, "o+1", $l, undef );
		}
		else {
			%area = CamCopperArea->GetCuArea( $outerThick, $pcbThick, $inCAM, $jobId, "o+1", undef, $l );
		}

		if ( $area{"percentage"} > 0 ) {

			push( @innerCuUsage, sprintf( "%.0f", $area{"percentage"} ));
			push( @innerCuUsageFormat, $l . " = " . sprintf( "%2.0f", ( $area{"percentage"} ) ) . "%" );

		}
	}

	my @mess1 = ();
	push( @mess1,
		      "Před vytvořením mpanelu je nutné mít vytvořené složení "
			. "(využití Cu se vezme z o+1, na konci se zkontroluje proti panelu jestli se nezmenšilo)\n" );
	push( @mess1, "Pocet vrstev = " . scalar(@sig) );
	push( @mess1, "Konstrukcni trida = $constClass" );
	push( @mess1, "Konstrukcni trida vnitrni = $constClassInn" );
	push( @mess1, "Vrstva venkovni medi = ${outerThick}µm" );
	push( @mess1, "Vyuziti medi = " . join( "/ ", @innerCuUsage ) );
	push( @mess1, "Tloustka DPS = ${pcbThick}µm" );

	my @btn = ( "Pokracovat - slozeni jsem vytvoril", "Vytvorit standardni slozeni" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn );    #  Script se zastavi

	my $btnNumber = $messMngr->Result();    # vraci poradove cislo zmacknuteho tlacitka (pocitano od 0, zleva)

	if ( $btnNumber == 1 ) {
		
		if(!defined $constClass || $constClass eq "" || $constClass == 0){
			die "Konstrukcni trida neni vyplnena v atributech jobu";
		}
		
		StackupDefault->CreateStackup( $inCAM, $jobId, scalar(@sig), \@innerCuUsage, $outerThick, $constClass );
	}
}

my $form = RunPnlWizard->new( $jobId, PnlCreEnums->PnlType_CUSTOMERPNL );

print STDERR "KONEC";
sleep(5);

