
#-------------------------------------------------------------------------------------------#
# Description: Export of laser stencil
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::DataOutput::ExportLaser;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Copy;

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
use aliased 'Programs::Stencil::StencilSerializer::StencilSerializer';
use aliased 'Programs::Stencil::StencilCreator::Enums'           => 'StnclEnums';

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
	
	my $ser    = StencilSerializer->new( $self->{"jobId"} );
	$self->{"params"} = $ser->LoadStenciLParams();

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
	my $lName = GeneralHelper->GetGUID();
	$inCAM->COM( "merge_layers", "source_layer" => $self->{"workLayer"}, "dest_layer" => $lName );
	$inCAM->COM( "profile_to_rout", "layer" => $lName, "width" => "300" );

	my $fileName = GeneralHelper->GetGUID();
	my $path     = EnumsPaths->Client_INCAMTMPOTHER;
	my %layer    = ( "name" => $lName, "polarity" => "positive", "comp" => 0, "mirror" => 0, "angle" => 0 );
	my @layers   = ( \%layer );

	my $resultItemGer = $self->_GetNewItem("Produce data");

	Helper->ExportLayers2( $resultItemGer, $inCAM, $step, \@layers, $path, sub { return $fileName }, 0, 0);

	$self->_OnItemResult($resultItemGer);
	
	$inCAM->COM( 'delete_layer', layer => $lName );

	my $gerName = $jobId."_t.ger";
	
	if($self->{"params"}->GetStencilType() eq StnclEnums->StencilType_BOT){
		
		$gerName = $jobId."_b.ger";
	}

	my %info = ( "name" => $gerName, "path" => $path . $fileName );

	return \%info;

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

