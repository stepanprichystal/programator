
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass;
use base("Managers::AsyncJobMngr::WorkerClass");

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportUtility::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

sub Init {
	my $self = shift;

	$self->{"pcbId"}       = shift;
	$self->{"taskId"}      = shift;
	$self->{"inCAM"}       = shift;
	$self->{"exportClass"} = shift;    # classes for export each group
	$self->{"data"}        = shift;    # export data

}

sub RunExport {
	my $self = shift;


	my %unitsData = $self->{"data"}->GetAllUnitData();
 	my @keys = $self->{"data"}->GetOrderedUnitKeys();
	# sort keys by nhash value "__UNITORDER__"
	#my @keys = ;

	foreach my $unitId (@keys) {
		#tell group export start

		my $exportData = $unitsData{$unitId};

		# Event when group export start
		$self->__GroupExportEvent( Enums->EventType_GROUP_START, $unitId );

		# Process group
		$self->__ProcessGroup( $unitId, $exportData );

		# Event when group export end
		$self->__GroupExportEvent( Enums->EventType_GROUP_END, $unitId );

	}
}

sub __ProcessGroup {
	my $self       = shift;
	my $unitId     = shift;
	my $exportData = shift;    # export data for specific group

	my $num = rand(10);

use Time::HiRes qw (sleep);
	for ( my $i = 0 ; $i < $num ; $i++ ) {

		my %data1 = ();
		$data1{"unitId"}   = $unitId;
		$data1{"itemId"}   = "Item id $i";
		$data1{"result"}   = "succes";
		$data1{"errors"}   = "";
		$data1{"warnings"} = "";

		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );

		sleep(0.2);

	}
	
	for ( my $i = 0 ; $i < 2 ; $i++ ) {

		my %data1 = ();
		$data1{"unitId"}   = $unitId;
		$data1{"itemId"}   = "Item id $i";
		$data1{"result"}   = "failure";
		$data1{"errors"}   = "rrrrrrrrrrr";
		$data1{"group"}   = "Layer";
		$data1{"warnings"} = "";

		$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );

		sleep(0.2);

	}

	return 1;

	# Get right export class and init
	my $exportClass = $self->{"exportClass"}->{$unitId};
	$exportClass->Init( $self->{"inCAM"}, $self->{"pcbId"}, $exportData );

	# Set handlers
	$exportClass->{"onItemResult"}->Add( sub { $self->__ItemResultEvent( $exportClass, $unitId, @_ ) } );

	# Final export group
	$exportClass->Run();

}

sub __ItemResultEvent {
	my $self        = shift;
	my $exportClass = shift;
	my $unitId      = shift;
	my $itemResult  = shift;

	# Item result event

	my %data1 = ();
	$data1{"unitId"}   = $unitId;
	$data1{"itemId"}   = $itemResult->ItemId();
	$data1{"result"}   = $itemResult->Result();
	$data1{"errors"}   = $itemResult->GetErrorStr( Enums->ItemResult_DELIMITER );
	$data1{"warnings"} = $itemResult->GetWarningStr( Enums->ItemResult_DELIMITER );

	$self->_SendMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );

	# Progress value event

	my %data2 = ();
	$data2{"unitId"} = $unitId;
	$data2{"value"}  = $exportClass->GetProgressValue();

	$self->_SendProgressEvt( \%data2 );

}

#sub __ItemErrorEvent {
#	my $self = shift;
#	my $data = shift;
#
#	$self->__OnMessageEvt( ITEM_ERROR, $data );
#}

sub __GroupExportEvent {
	my $self   = shift;
	my $unitId = shift;
	my $type   = shift;    #GROUP_EXPORT_<START/END>

	my %data = ();
	$data{"unitId"} = $unitId;

	$self->_SendMessageEvt( $type, \%data );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::ExporterUtility->new();

	#$app->Test();

	#$app->MainLoop;

}

1;

