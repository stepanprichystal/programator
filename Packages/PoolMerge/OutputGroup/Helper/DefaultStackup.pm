
#-------------------------------------------------------------------------------------------#
# Description: Create default stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::OutputGroup::Helper::DefaultStackup;


#3th party library
use utf8;
use strict;
use warnings;
use DateTime;
use File::Copy;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::Stackup::StackupDefault';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';
use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}
 
# Set info about solder mask and silk screnn, based on layers
sub CreateDefaultStackup {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	# Get info in order to create default stackup
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $masterJob );
	my $constClass  = CamAttributes->GetJobAttrByName( $inCAM, $masterJob, 'pcb_class' );
	my $cuThickness = HegMethods->GetOuterCuThick($masterJob);
	my $pcbThick    = 0.7;                                                                  # aproximate thickness of core

	if ( !defined $cuThickness || $cuThickness == 0 ) {
		$result = 0;
		$$mess .= "Copper thicknes is not set in Helios, job \"$masterJob\"";
		return $result;
	}

	my @innerCuUsage = ();
	my @layers       = CamJob->GetSignalLayer($inCAM, $masterJob);
	@layers = grep { $_->{"gROWname"} =~ /^v\d+$/ } @layers;
	@layers = sort { $a->{"gROWname"} cmp $b->{"gROWname"} } @layers;

	foreach my $l (@layers) {

		my %area = ();
		my ($num) = $l->{"gROWname"} =~ m/^v(\d+)$/;

		if ( $num % 2 == 0 ) {

			%area = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $masterJob, "panel", $l->{"gROWname"}, undef );
		}
		else {
			%area = CamCopperArea->GetCuArea( $cuThickness, $pcbThick, $inCAM, $masterJob, "panel", undef, $l->{"gROWname"} );
		}

		if ($area{"percentage"} > 0) {

			push( @innerCuUsage, $area{"percentage"} );
		}
		else {
			$result = 0;
			$$mess .= "Error when computing  Copper area for layer: " . $l->{"gROWname"};
		}

	}

	# Create default xml stackup
	StackupDefault->CreateStackup( $masterJob, $layerCnt, \@innerCuUsage, $cuThickness, $constClass );

	# Create pdf with stackup	
	my $stackupPdf = StackupPdf->new($masterJob);

	$stackupPdf->Create();
	my $stackTempPath = $stackupPdf->GetStackupPath();

	if ( -e $stackTempPath ) {
		my $pdfArchive = JobHelper->GetJobArchive($masterJob) . "pdf/" . $masterJob . "-cm.pdf";
		
		if(-e $pdfArchive){
			unlink($pdfArchive);
		}
 
		copy( $stackTempPath, $pdfArchive ) or die "Copy failed: $!";
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

