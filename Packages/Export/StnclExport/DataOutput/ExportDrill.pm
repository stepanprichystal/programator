
#-------------------------------------------------------------------------------------------#
# Description: Export of etched stencil
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::StnclExport::DataOutput::ExportDrill;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'CamHelpers::CamLayer';
#use aliased 'CamHelpers::CamSymbol';
#use aliased 'CamHelpers::CamJob';
#use aliased 'CamHelpers::CamHistogram';
#use aliased 'CamHelpers::CamFilter';
#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::Export::NCExport::ExportMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	 
	$self->{"step"} = "panel"; # step which stnecil data are exported from
	$self->{"workLayer"} = "f";
	$self->{"ncExport"} = ExportMngr->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"step"});
	$self->{"ncExport"}->{"onItemResult"}->Add( sub { $self->__OnExportResult(@_) } );
	 
 

	return $self;
}

# Prepare gerber files
sub Output {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};
 
	$self->{"ncExport"}->Run();
 
}
 

#-------------------------------------------------------------------------------------------#
# Private methods
#-------------------------------------------------------------------------------------------#

sub __OnExportResult {
	my $self = shift;
	my $item = shift;

	#$item->SetGroup("Cooperation ET");

	$self->_OnItemResult($item);
}

 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::StnclExport::DataOutput::ExportDrill';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f13610";

	my $export = ExportDrill->new( $inCAM, $jobId);
	$export->Output();
	
}

1;

