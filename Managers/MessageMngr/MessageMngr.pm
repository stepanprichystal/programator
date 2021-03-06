use utf8;

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::MessageMngr::MessageMngr;

#3th party libraryMethods
use utf8;
use strict;
use warnings;
use threads;
use threads::shared;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageForm';
use aliased 'Managers::MessageMngr::Enums';
use aliased 'Packages::Events::Event';
use aliased 'Managers::MessageMngr::MessageParameter';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self   = shift;
	my $pcbId  = shift;    # title of message windows
	my $parent = shift;    # default parent (Wx:window) of all mesages. Possible to specify different when call Show/ShowModal

	$self = {};
	bless($self);

	# PROPERTIES

	#actual Message
	$self->{result}  = -1;       #contain's reference on result scalar variable
	$self->{messFrm} = undef;    #contain's reference on result scalar variable

	$self->{'onMessage'} = Event->new();    #event when message

	$self->{"pcbId"} = $pcbId;

	if ( !$self->{"pcbId"} ) {
		$self->{"pcbId"} = -1;
	}
	$self->{"childPcbId"} = -1;

	$self->{"parent"} = $parent;

	my @messQueue = ();
	$self->{messQueue} = \@messQueue;       #contain's reference on result scalar variable

	#my $worker = threads->create( sub { $self->__WorkerMethod( ) });
	#$worker->set_thread_exit_only(1);

	return $self;

}

sub __WorkerMethod {
	my $self = shift;

	while (1) {

		sleep(1);
		print STDERR " loop\n";

		$self->__ShowMessages();

	}

}

sub SetPcbIds {

	my $self = shift;
	$self->{"pcbId"}      = shift;
	$self->{"childPcbId"} = shift;
}

sub Show {
	my $self = shift;
	$self->__AddToQueue( 0, @_ );
}

sub ShowModal {
	my $self = shift;
	$self->__AddToQueue( 1, @_ );

}

# Results are number of pushed button.
# Count from left to right. Numbers start with number 1
sub Result {

	my $self = shift;

	#while(!defined $self->{"result"})
	#{};

	return $self->{result};
}

sub AddOnMessage {
	my $self      = shift;
	my $onMessage = shift;

	if ( defined $onMessage ) {

		$self->{'onMessage'}->Add($onMessage);
	}
}


# Prepare text message parameter structure
sub GetTextParameter {
	my $self  = shift;
	my $title = shift;
	my $value = shift;

	return $self->__GetParameter(Enums->ParameterType_TEXT, $title, $value);
}

# Prepare number message parameter structure
sub GetNumberParameter {
	my $self  = shift;
	my $title = shift;
	my $value = shift;

	return $self->__GetParameter(Enums->ParameterType_NUMBER, $title, $value);
}

# Prepare checkbox message parameter structure
sub GetCheckParameter {
	my $self  = shift;
	my $title = shift;
	my $value = shift;

	return $self->__GetParameter(Enums->ParameterType_CHECK, $title, $value);
}

# Prepare option message parameter structure
sub GetOptionParameter {
	my $self  = shift;
	my $title = shift;
	my $value = shift;
	my $options = shift;
	
	die "Parameter option is not defined" unless ( defined $options );

	return $self->__GetParameter(Enums->ParameterType_OPTION, $title, $value, $options);
}


# Prepare message parameter structure
sub __GetParameter {
	my $self  = shift;
	my $type  = shift;
	my $title = shift;
	my $value = shift;
	my $options = shift;

	die "Parameter type is not defined"  unless ( defined $type );
	die "Parameter title is not defined" unless ( defined $title );
	die "Parameter value is not defined" unless ( defined $value );

	my $par = MessageParameter->new( $type, $title, $value, $options );
	
	return $par;
}
 
sub __AddToQueue {
	my $self = shift;

	my %info = ();
	$info{"modal"}  = shift;
	$info{"parent"} = shift;

	$info{"type"}       = shift;
	$info{"messages"}   = shift;
	$info{"buttons"}    = shift;
	$info{"images"}     = shift;    # collection of images
	$info{"parameters"} = shift;    # collection of parameters

	$info{"status"} = Enums->StatusType_NOTSHOWED;

	my $result = "test";
	$info{"result"} = \$result;

	my $trace = Devel::StackTrace->new();
	$info{"caller"} = $trace->frame(2)->{"package"};

	#$info{id}       = GeneralHelper->GetGUID();

	push( @{ $self->{messQueue} }, \%info );

	$self->__ShowMessages();

}

sub __ShowMessages {
	my $self  = shift;
	my @queue = @{ $self->{messQueue} };

	if ( scalar(@queue) < 1 ) {
		return;
	}

	#delete destroyed windwos

	#for (my $i = 0; $i < scalar (@queue); $i++){

	#$queue[$i]

	#}

	my %mess = %{ $queue[0] };    #take first meesage from queue

	if ( $mess{status} eq Enums->StatusType_WAITFORRESULT ) {

		#do nothing
	}
	elsif ( $mess{status} eq Enums->StatusType_NOTSHOWED ) {

		my $parent = $mess{"parent"};
		if ( ( !defined $parent || $parent == -1 ) && defined $self->{"parent"} ) {
			$parent = $self->{"parent"};
		}

		my $messFrm =
		  MessageForm->new(
							$parent,           $self->{"pcbId"}, $mess{"type"},
							$mess{"messages"}, $mess{"buttons"}, $mess{"images"},
							$mess{"caller"}, $mess{"parameters"}, sub { __OnExitMessFrm( $self, @_ ) }
		  );

		$messFrm->Centre(&Wx::wxVERTICAL);

		#$self->{messFrm} = $messFrm;

		my $ref = @{ $self->{messQueue} }[0];
		$ref->{"status"} = Enums->StatusType_WAITFORRESULT;

		if ( $mess{"modal"} ) {
			$messFrm->ShowModal();
		}
		else {
			$messFrm->Show();
		}

		#	unless ($messFrm->IsMainLoopRunning())
		#	{
		# tun mainloop, in order messageWindow always show as modal
		#	print "Mainloop Messmngr";
		#	$messFrm->MainLoop;
		#}

	}
}

sub __OnExitMessFrm {
	my $self       = shift;
	my $messFrmObj = shift;
	my $resultBtn  = shift;

	my @messQueue = @{ $self->{messQueue} };

	my %exitMess = %{ $messQueue[0] };

	if ( $exitMess{"status"} eq Enums->StatusType_WAITFORRESULT ) {

		shift @{ $self->{messQueue} };    #delete first message

		$self->{"result"} = $resultBtn;

		#$mainfrm->MakeModal(0); # (Re-enables parent window)
		#$mainfrm->{"eventLoop"}->Exit();
		$messFrmObj->Hide();

		#$mainfrm->Hide();
		#$messFrmObj->Destroy();

		#write to log

		my @btns      = @{ $messFrmObj->{"buttons"} };
		my $resultTxt = $btns[$resultBtn];

		my $onMessage = $self->{'onMessage'};
		if ( scalar( $onMessage->Handlers() ) ) {

			$onMessage->Do( $self->{"pcbId"}, $self->{"childPcbId"}, $self->__GetMessagesTxt( $exitMess{"messages"} ), $exitMess{"type"},
							$resultTxt );
		}

		#$messFrmObj->Destroy();

		#show next message in queue
		$self->__ShowMessages();

	}

}

sub __GetMessagesTxt {
	my $self = shift;
	my @mess = @{ shift(@_) };

	my $messTxt = "";

	$messTxt = join( ', ', @mess );

	return $messTxt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Managers::MessageMngr::MessageMngr';
	use aliased 'Enums::EnumsGeneral';
	use aliased 'Helpers::GeneralHelper';

	# Typy oken:
	# MessageType_ERROR
	# MessageType_SYSTEMERROR
	# MessageType_WARNING
	# MessageType_QUESTION
	# MessageType_INFORMATION

	# Definice textovych zprav
	my $str = "Druha <r>FAIL</r> TEST <g>GREEN</g> konec \n";

	my @mess1 = ( "Prvni zprava\n", $str );
	push( @mess1, "<img1>" );
	push( @mess1, "dalsi text" );

	# Definice tlacitek
	my @btn = ( "tl1", "tl2" );

	# Kolekce obrazku
	# Kazdy obrazek je definovan polem:
	# - 0 index = cislo obrazku (umisteni pomoci tagu <img<cislo orazku>>)
	# - 1 index = cesta
	# - 2 index = typ obrazku
	my @imgs = ();
	my $p    = GeneralHelper->Root() . "\\Programs\\Coupon\\CpnWizard\\Resources\\small_coplanar_diff_coated_embedded_without_gnd.bmp";
	push( @imgs, [ 1, $p, &Wx::wxBITMAP_TYPE_BMP ] );

	my $messMngr = MessageMngr->new("D3333");

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1, \@btn, \@imgs );    #  Script se zastavi

	#my $btnNumber = $messMngr->Result();    # vraci poradove cislo zmacknuteho tlacitka (pocitano od 0, zleva)

	#$messMngr->Show( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );    #  Script se nezastavi a jede dal;

}

1;
