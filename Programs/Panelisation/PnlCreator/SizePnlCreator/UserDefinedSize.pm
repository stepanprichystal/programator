
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SizePnlCreator::UserDefinedSize;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

use Class::Interface;
&implements('Programs::Panelisation::PnlCreator::SizePnlCreator::ISize');

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpPrepareData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpExportData';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::View::ImpUnitForm';

#use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $key   = Enums->SizePnlCreator_USERDEFINED;

	my $self = $class->SUPER::new( $inCAM, $jobId, $key );
	bless $self;

	$self->{"settings"}->{"w"} = 0;
	$self->{"settings"}->{"h"} = 0;

	return $self;                                    # Return the reference to the hash.
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Build layout, return 1 if succes, 0 if fail
sub Init {
	my $self = shift;
	my $inCAM = shift;

	 
	$self->{"settings"}->{"w"} = 30;
	$self->{"settings"}->{"h"} = 30;
		for ( my $i = 0 ; $i < 1 ; $i++ ) {

		$inCAM->COM("get_user_name");

	 	my $name =  $inCAM->GetReply();

		print STDERR "\nUSER NAME !! $name \n";

		sleep(1);

	}
	
	return 1;
}

## If builded, return layout
sub Check {
	my $self    = shift;
	my $inCAM = shift;
	my $errMess = shift;

	for ( my $i = 0 ; $i < 3 ; $i++ ) {

		$inCAM->COM("get_user_name");

	 	my $name =  $inCAM->GetReply();

		print STDERR "\nChecking  USER NAME !! $name \n";

		sleep(1);

	}

	return 1;

}
#
#

sub Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;

		for ( my $i = 0 ; $i < 3 ; $i++ ) {

		$inCAM->COM("get_user_name");

	 	my $name =  $inCAM->GetReply();

		print STDERR "\nProcessing  USER NAME !! $name \n";

		sleep(1);

	}

	return 1;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method
#-------------------------------------------------------------------------------------------#

sub SetWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"w"} = $val;

}

sub GetWidth {
	my $self = shift;

	return $self->{"settings"}->{"w"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

