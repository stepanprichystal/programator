
#-------------------------------------------------------------------------------------------#
# Description: Inteface, which  allow classes to modify nc files, before ther are mmerged and
# moved from output folder to archive
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::MergeFileMngr::FileHelper::IFileEditor;

#3th party library
use strict;
use warnings;
#use File::Copy;

#local library
#use aliased 'Packages::Export::NCExport::NCExportHelper';
#use aliased 'Packages::Stackup::StackupHelper';
#use aliased 'Packages::Export::NCExport::OperationMngr::DrillingHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Packages::InCAM::InCAM';
#use aliased 'Enums::EnumsMachines';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::Export::NCExport::Parser';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

use Class::Interface;
&interface;     

sub EditAfterOpen;     
sub EditBeforeSave;     

1;
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	 
}

1;

