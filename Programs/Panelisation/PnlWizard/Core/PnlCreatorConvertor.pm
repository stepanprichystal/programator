
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Core::PnlCreatorConvertor;

# Abstract class #

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library
#use aliased 'Programs::Exporter::ExportChecker::Enums';
#use aliased 'Packages::Events::Event';

use aliased 'Programs::Panelisation::PnlCreator::Enums' => 'PnlCreEnums';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::HEGOrderSize';
use aliased 'Programs::Panelisation::PnlCreator::SizePnlCreator::UserDefinedSize';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# Define all creators
	$self->{"creators"} = {};

	$self->{"creators"}->{ PnlCreEnums->SizePnlCreator_USERDEFINED } = UserDefinedSize->new();
	$self->{"creators"}->{ PnlCreEnums->SizePnlCreator_HEGORDER }    = HEGOrderSize->new();

	return $self;
}

sub __ModelData2CreatorSettings {
	my $self       = shift;
	my $modelData  = shift;
	my $creatorKey = shift;

	die "Creator was not defined  for key: $creatorKey" unless ( defined $self->{"creators"}->{$creatorKey} );

	# Get creator object
	my $creator = dclone( $self->{"creators"}->{$creatorKey} );

	# CHeck if model data and creatod settings has same "keys"

	$creator->{"settings"} = $modelData->{"data"};

	my $JSONSett = $creator->ExportSett();

	return $JSONSett;
}

sub __CreatorSettings2ModelData {
	my $self      = shift;
	my $modelData = shift;
	my $JSONSett  = shift;

	my $creatorKey = $modelData->GetModelKey();

	die "Creator was not defined  for key: $creatorKey" unless ( defined $self->{"creators"}->{$creatorKey} );

	# Get creator object
	my $creator = dclone( $self->{"creators"}->{$creatorKey} );

	# CHeck if model data and creatod settings has same "keys"

	$creator->ImportSett($JSONSett);

	$modelData->{"data"} = $creator->{"settings"};

	return $modelData;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
