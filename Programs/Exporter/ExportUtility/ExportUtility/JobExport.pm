
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::JobExport;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

use constant {
			   ITEM_RESULT  => "itemResult",
			   ITEM_ERROR   => "itemError",
			   GROUP_EXPORT => "groupExport"
};

my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;

sub new {
	my $self = shift;

	$self = {};
	bless($self);

	$self->{"pcbId"}   = shift;
	$self->{"jobGUID"} = shift;
	$self->{"inCAM"}   = shift;
	$self->{"data"}    = shift;

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

	my $groups = 2;
	my $items  = 5;

	my $prog = 0;

	for ( my $i = 0 ; $i < $groups ; $i++ ) {

		

		#tell group export start

		my %data = ( "groupId" => $i );

		$self->__GroupExportEvent( \%data );

		for ( my $j = 0 ; $j < $items ; $j++ ) {
		$prog += 10;
			sleep(1);

			my %data2 = ( "groupId" => $i, "itemId" => $j );

			$self->__ItemResultEvent( \%data2 );

			$self->__OnProgressEvt($prog);

		}
	}
}

sub __ItemResultEvent {
	my $self = shift;
	my $data = shift;

	$self->__OnMessageEvt( ITEM_RESULT, $data );
}

sub __ItemErrorEvent {
	my $self = shift;
	my $data = shift;

	$self->__OnMessageEvt( ITEM_ERROR, $data );
}

sub __GroupExportEvent {
	my $self = shift;
	my $data = shift;

	$self->__OnMessageEvt( GROUP_EXPORT, $data );
}

sub __OnMessageEvt {
	my $self         = shift;
	my $messType     = shift;
	my $data         = shift;
	my %res : shared = ();
	$res{"jobGUID"}  = $self->{"jobGUID"};
	$res{"messType"} = $messType;

	#%res = ( %res, %{$data} );

	my $threvent = new Wx::PlThreadEvent( -1, $THREAD_MESSAGE_EVT, \%res );
	Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

}

sub __OnProgressEvt {
	my $self  = shift;
	my $value = shift;

	my %res : shared = ();
	$res{"jobGUID"} = $self->{"jobGUID"};
	$res{"value"}   = $value;

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

