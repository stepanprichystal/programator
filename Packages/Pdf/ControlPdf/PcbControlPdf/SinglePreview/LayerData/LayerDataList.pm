
#-------------------------------------------------------------------------------------------#
# Description: Prepare special structure "LayerData" for each exported layer.
# This sctructure contain list <Packages::CAMJob::OutputData::LayerData::LayerData>
# and operations with this items
# type of layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::LayerData::LayerDataList;
use base('Packages::Pdf::ControlPdf::Helpers::SinglePreview::LayerData::LayerDataListBase');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Pdf::ControlPdf::PcbControlPdf::SinglePreview::Enums';

use aliased 'Helpers::ValueConvertor';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $self      = $class->SUPER::new(@_ );
	bless $self;
 
	return $self;
}
 




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

