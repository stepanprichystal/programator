#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
#use FindBin;
#use lib "$FindBin::Bin/../";
#use PackagesLib;
use aliased "CamHelpers::CamAttributes";
use aliased "Helpers::FileHelper";
use aliased "Enums::EnumsPaths";
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::OutputData::Helper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamFilter';

use Data::Dump qw(dump);

use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();
my $jobId = "f13610";
my $step  = "o+1";

my %inf = ( "gROWname" => "goldc" );

__PrepareGOLDFINGER();

sub __PrepareGOLDFINGER {
	my $self  = shift;
	my $layer = shift;

	my $baseCuL = ( "goldc" =~ m/^([pmlg]|gold)?([cs])$/ )[1];
	my $refL    = $layer->{"gROWname"};
	my $maskL   = "m" . $layer->{"gROWname"};

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $maskL ) ) {
		$maskL = 0;
	}

	unless ( CamHelper->LayerExists( $inCAM, $jobId, $refL ) ) {
		die "Reference layer $refL doesn't exist.";
	}

 
	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my $resultL = Helper->FeaturesByRefLayer( $inCAM, $jobId, $layer->{"gROWname"}, $refL, $maskL, \%lim );

}

