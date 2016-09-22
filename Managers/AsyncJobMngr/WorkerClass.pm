#-------------------------------------------------------------------------------------------#
# Description: Abstract class, used for implementation code in worker thread
# Implement function for asznynchrounous sending ProgressEvent, MessageEvent
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AsyncJobMngr::WorkerClass;

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

# Handlers processed by main thread
my $THREAD_PROGRESS_EVT : shared;
my $THREAD_MESSAGE_EVT : shared;

sub new {
	my $self = shift;

	$self = {};
	bless($self);

	# PROPERTIES

	$THREAD_PROGRESS_EVT   = ${ shift(@_) };
	$THREAD_MESSAGE_EVT    = ${ shift(@_) };
	$self->{"exporterFrm"} = shift;

	return $self;
}

# General method for sending "message" event from this class
sub _SendMessageEvt {
	my $self        = shift;
	my $messageType = shift;
	my $data        = shift;

	my %res : shared = ();
	$res{"taskId"}   = $self->{"taskId"};
	$res{"messType"} = $messageType;

	#fill response with <$data> values, if exists
	if ($data) {

		my %dataShared : shared = ();
		$res{"data"} = \%dataShared;

		foreach my $k ( keys %{$data} ) {

			#	my $val : shared = $data->{$k};

			$res{"data"}->{$k} = $data->{$k};

			#	${ $res{"data"} }{$k} = $val;
		}
	}

	my $threvent = new Wx::PlThreadEvent( -1, $THREAD_MESSAGE_EVT, \%res );
	Wx::PostEvent( $self->{"exporterFrm"}, $threvent );

}

# General method for sending total progress value for units
sub _SendProgressEvt {
	my $self = shift;
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

