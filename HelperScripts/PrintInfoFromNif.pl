#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

#local library

use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Enums::EnumsPaths';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';

use aliased 'Packages::NifFile::NifFile';

my $p = "c:/Export/test/jobsIn.txt";

my $t = "c:/Export/test/jobsOut.csv";

my $f;
open( $f, ">", $t ) or die "unable open" . $_;

my @lines = @{ FileHelper->ReadAsLines($p) };

my $res = "Order id; termin; pocet_prirezu; rozmer_x; rozmer_y; program_linka; pocet_der; pocet_vrtaku; min_vrtak; min_vrtak_pomer\n";

print $f $res."\n";

foreach my $orderId (@lines) {

	my $txt = "";

	$orderId =~ s/\t//g;
	$orderId =~ s/\n//g;

	my ($jobId) = $orderId =~ /(\w\d+)-/;
	
	$jobId = lc($jobId);
	
	unless($jobId){
		next;
	}
	
	my %orderInfo = HegMethods->GetOrderInfo( $orderId);
	

	my $formerNif = NifFile->new($jobId);
	if ( $formerNif->Exist() ) {

		my @inf = ();

		push( @inf, $orderId );
		push( @inf,  $orderInfo{'termin'});
		push( @inf,  $orderInfo{'pocet_prirezu'} + $orderInfo{'prirezu_navic'});
		
		
		
		push( @inf, $formerNif->GetValue("rozmer_x") );
		push( @inf, $formerNif->GetValue("rozmer_y") );

		push( @inf, ( $formerNif->GetValue("tenting") =~ /a/i ? "tenting" : "pattern" ) );
		push( @inf, $formerNif->GetValue("pocet_der") );
		push( @inf, $formerNif->GetValue("pocet_vrtaku") );
		push( @inf, $formerNif->GetValue("min_vrtak") );
		push( @inf, $formerNif->GetValue("min_vrtak_pomer") );

		$txt = join( ";", @inf );

		print $f $txt."\n";

	}
	else {

		print STDERR "nif doesnt-exist";
	}

}

close($f);

 
