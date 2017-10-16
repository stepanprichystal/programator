
#-------------------------------------------------------------------------------------------#
# Description: Export of etched stencil
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::DataOutput::ExportLaser;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"step"} = "o+1";    # step which stnecil data are exported from

	$self->{"workLayer"} = "ds";

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	CamHelper->SetStep( $inCAM, $step );

	# 1) Export layers

	my $fileInf = $self->__PrepareLayer();

	# 2) zip files
	my $archive = JobHelper->GetJobArchive( $self->{"jobId"} ) . "zdroje\\data_stencil";

	unless ( -e $archive ) {
		mkdir($archive) or die "Can't create dir: " . $archive . $_;
	}

	my $zip = Archive::Zip->new();

	$zip->addFile( $fileInf->{"path"}, $fileInf->{"name"} );
	
	unless ( $zip->writeToFileNamed( $archive . "\\" . $jobId . "_laser.zip" ) == AZ_OK ) {

		die 'Error when zip stencil data files';
	}

}

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

# measure layer used for control
sub __PrepareLayer {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# 1) Export layer

	my $fileName = GeneralHelper->GetGUID();
	my $path     = EnumsPaths->Client_INCAMTMPOTHER;
	my %layer    = ( "name" => $self->{"workLayer"}, "polarity" => "positive", "comp" => 0, "mirror" => 0, "angle" => 0 );
	my @layers   = ( \%layer );

	my $resultItemGer = $self->_GetNewItem("Layer measure");

	Helper->ExportLayers2( $resultItemGer, $inCAM, $step, \@layers, $path, sub { return $fileName }, 0, 1 );

	$self->_OnItemResult($resultItemGer);

	my %info = ( "name" => "_t.ger", "path" => $path . $fileName );

	return \%info;

}

# If some pad is surface or line, create pad from him
sub __CreatePads {
	my $self  = shift;
	my $lName = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	$inCAM->COM( 'sel_contourize', "accuracy"  => '6.35', "break_to_islands" => 'yes', "clean_hole_size" => '60',  "clean_hole_mode" => 'x_and_y' );
	$inCAM->COM( 'sel_cont2pad',   "match_tol" => '25.4', "restriction"      => '',    "min_size"        => '127', "max_size"        => '12000' );

	# test on lines
	my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $lName );
	if ( $fHist{"line"} > 0 || $fHist{"arc"} > 0 ) {

		die "Error during convert featrues to apds. Layer ("
		  . $self->{"workLayer"}
		  . ") can't contain line and arcs. Only pad and surfaces are alowed.";
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportLaser';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportLaser->new( $inCAM, $jobId);
	$export->Output();

	#print $test;

}

1;

