
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::StorageModelMngr;
use base ('Packages::ObjectStorable::JsonStorable::JsonStorableMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased "Enums::EnumsPaths";
use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class         = shift;
	my $jobId         = shift;
	my $pnlWizardType = shift;

	my $dir = EnumsPaths->Client_INCAMTMPPNLCRE;

	unless ( -e $dir ) {
		mkdir($dir) or die "Can't create dir: " . $dir . $_;
	}

	my $type = undef;

	if ( $pnlWizardType eq PnlCreEnums->PnlType_PRODUCTIONPNL ) {

		$type = "panel";
	}
	elsif ( $pnlWizardType eq PnlCreEnums->PnlType_CUSTOMERPNL ) {
		$type = "mpanel";
	}
	else {

		die "Unknow wizard type";
	}

	my $p = $dir . $jobId . "_$type";

	my $self = $class->SUPER::new($p);
	bless $self;

	$self->{"jobId"} = $jobId;

	#$self->{"modelData"}      = $modelData;
	#$self->{"modelPartsData"} = $modelPartsData;

	FileHelper->DeleteTempFilesFrom( EnumsPaths->Client_INCAMTMPPNLCRE, 3600 * 24 * 5 );    #delete 5 days old settings

	return $self;
}

sub ExistModelData {
	my $self = shift;

	return $self->SUPER::SerializedDataExist();

}

sub GetModelDate {
	my $self = shift;
	my $time = shift // 1;
	my $date = shift // 0;

	my $dt = $self->SUPER::GetSerializedDataDate();

	my $str = "";
	$str .= $dt->hour() . ":" . $dt->minute() if ($time);
	$str .= ( $time ? " " : "" ) .  $dt->day_abbr() if ($date);

	return $str;
}

sub StoreModel {
	my $self  = shift;
	my $model = shift;

	return $self->SUPER::StoreData($model);
}

sub LoadModel {
	my $self = shift;

	return $self->SUPER::LoadData();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

