
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobWorkerClass;

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

my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;

sub new {
	my $self = shift;

	$self = {};
	bless($self);

	$self->{"pcbId"}  = shift;
	$self->{"taskId"} = shift;
	$self->{"inCAM"}  = shift;
	$self->{"data"}   = shift;
	$self->{"exportClass"} = shift;

	$THREAD_PROGRESS_EVT = ${ shift(@_) };
	$THREAD_MESSAGE_EVT  = ${ shift(@_) };

	$self->{"exporterFrm"} = shift;

	#$self->{'onItemResult'}  = Event->new();
	#$self->{'onItemError'}   = Event->new();
	#$self->{'onGroupExport'} = Event->new();

	return $self;
}

sub RunExport {
	my $self = shift;

	my %unitsData = $self->{"data"}->GetAllUnitData();

	foreach my $unitId ( keys %unitsData ) {

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
	my $exportData = shift;                               # export data for specific group

	my $exportClass = $self->{"exportClass"}->{$unitId};
	
 
	
	$exportClass->Init($self->{"inCAM"}, $self->{"pcbId"}, $exportData);

	# Set handlers
	$exportClass->{"onItemResult"}->Add( sub { $self->__ItemResultEvent( $exportClass, $unitId, @_ ) } );

	$exportClass->Run();
	 

}

#sub __GetExportClass {
#	my $self   = shift;
#	my $unitId = shift;
#
#	my %id2class = ();
#
#	$id2class{ UnitEnums->UnitId_NIF } = NifExport->new();
#	$id2class{ UnitEnums->UnitId_NC }  = NifExport->new();
#
#	return $id2class{$unitId};
#}

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
	$data1{"errors"}   = $itemResult->GetErrorStr();
	$data1{"warnings"} = $itemResult->GetWarningStr();

	$self->__OnMessageEvt( Enums->EventType_ITEM_RESULT, \%data1 );
 
 	# Progress value event
	
	my %data2 = ();
	$data2{"unitId"} = $unitId;
	$data2{"value"} = $exportClass->GetProgressValue();
	
	$self->__OnProgressEvt( \%data2 );

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
	
	$self->__OnMessageEvt($type,  \%data );
}

# General method for sending "message" event from this class
sub __OnMessageEvt {
	my $self     = shift;
	my $messageType = shift;
	my $data     = shift;

	my %res : shared = ();
	$res{"taskId"}   = $self->{"taskId"};
	$res{"messType"}   = $messageType;
	

	#fill response with <$data> values, if exists
	if ($data) {

		my %dataShared : shared = ();
		$res{"data"} = \%dataShared;

		foreach my $k ( keys %{$data} ) {

			$res{"data"}{$k} = $data->{$k};
		}
	}

	my $threvent = new Wx::PlThreadEvent( -1, $THREAD_MESSAGE_EVT, \%res );
	Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

}

# General method for sending total progress value for units
sub __OnProgressEvt {
	my $self   = shift;
	my $data = shift;
	 
	my %res : shared = ();
	$res{"taskId"} = $self->{"taskId"};
	 
	 
	#fill response with <$data> values, if exists
	if ($data) {

		my %dataShared : shared = ();
		$res{"data"} = \%dataShared;

		foreach my $k ( keys %{$data} ) {

			$res{"data"}{$k} = $data->{$k};
		}
	}
	
	
	#%res = ( %res, %{$data} );

	my $threvent = new Wx::PlThreadEvent( -1, $THREAD_PROGRESS_EVT, \%res );
	Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

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

