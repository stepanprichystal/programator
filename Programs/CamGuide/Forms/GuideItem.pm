
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Forms::GuideItem;

#use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:textctrl :font);
use Wx qw(:icon wxTheApp wxNullBitmap);


#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::CamGuide::Enums';
use Widgets::Style;

sub new {

	my $self   = shift;
	my $parent = shift;

	$self = {};
	bless($self);

	$self->{'itemType'} = shift;
	$self->{'itemId'} = shift;
	$self->{'stepName'} = shift;
	$self->{'actionName'} = shift;
	$self->{'actionDesc'} = shift;
	$self->{'actionInserted'} = shift;
	$self->{'actionUser'} = shift;

	$self->{'parent'} = $parent;

	 

	#EVENTS=========================
	#event, when some action happen
	$self->{'onRunAll'}    = undef;
	$self->{'onRunSingle'} = undef;
	$self->{'onInfo'} = undef;

	my $pnlItem = undef;

	if ( $self->{'itemType'} eq Enums->GUIDEITEM_ACTION ) {

		$pnlItem = $self->__SetLayoutAction();
	}
	elsif ($self->{'itemType'} eq Enums->GUIDEITEM_STEP) {

		$pnlItem = $self->__SetLayoutStep();
		
	}elsif ($self->{'itemType'} eq Enums->GUIDEITEM_FINISH) {

		$pnlItem = $self->__SetLayoutFinish();
	}

	$self->{'item'} = $pnlItem;
	return $self;
}

sub SetActualItem {
	my $self = shift;

	my $handBmp =
	  Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/Hand.bmp",
		&Wx::wxBITMAP_TYPE_BMP );
	$self->{'actPosition'}->SetBitmap($handBmp);
}


sub SetGreenColour {
	my $self = shift;
	$self->{'pnlActionName'}->SetBackgroundColour($Widgets::Style::clrLightGreen);
}

sub SetRedColour {
	my $self = shift;
	$self->{'pnlActionName'}->SetBackgroundColour($Widgets::Style::clrLightRed);
}

sub SetInsertedInfo {
	my $self = shift;
	
	$self->{'dateTxt'}->SetLabel($self->{'actionInserted'});
	$self->{'userNameTxt'}->SetLabel($self->{'actionUser'});
}



sub __SetLayoutStep {

	my $self = shift;
	my $parent = $self->{'parent'};

	#define panels
	my $pnlItem = Wx::Panel->new( $parent, -1 );
	$pnlItem->SetBackgroundColour($Widgets::Style::clrLightGray);

	#define sizers
	my $szRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #top level sizer
	my $runAllBmp = Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/RunAll2.bmp",&Wx::wxBITMAP_TYPE_BMP );

	#define controls
	
	my $stepNameTxt = Wx::StaticText->new(
		$pnlItem, -1, $self->{'stepName'},
		[ -1,  -1 ],
		[ 90, 20 ]
	);
	$stepNameTxt->SetFont($Widgets::Style::fontSmallLblBold);
	my $runAllBtn = Wx::Button->new( $pnlItem, -1, "", [ -1, -1 ], [ 20, 20 ] );
	$runAllBtn->SetBitmap($runAllBmp);

	#define events
	Wx::Event::EVT_BUTTON( $runAllBtn, -1, sub { __OnRunAllClick($self) } );

	#define layout structure
	$szRow->Add( $stepNameTxt, 0, &Wx::wxLEFT, 10 );
	$szRow->Add( $runAllBtn, 0 );
	$szRow->Add( 5, 5, 0 );

	$pnlItem->SetSizer($szRow);
	$szRow->Layout();

	return $pnlItem;
}

sub __SetLayoutAction {

	my $self = shift;
	my $parent = $self->{'parent'};

	
	#define panels
	my $pnlItem = Wx::Panel->new( $parent, -1 );
	my $pnlActionName = Wx::Panel->new( $pnlItem, -1 );
	$self->{'pnlActionName'} = $pnlActionName;

	#define sizers
	my $szRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL); 

	#define controls
	my $infoBmp =
	  Wx::Bitmap->new(
		GeneralHelper->Root() . "/Resources/Images/Information2.bmp",
		&Wx::wxBITMAP_TYPE_BMP );
	my $runAllBmp =
	  Wx::Bitmap->new( GeneralHelper->Root() . "/Resources/Images/RunAll2.bmp",
		&Wx::wxBITMAP_TYPE_BMP );
	my $runSingleBmp =
	  Wx::Bitmap->new(
		GeneralHelper->Root() . "/Resources/Images/RunSingle2.bmp",
		&Wx::wxBITMAP_TYPE_BMP );
		
	my $actionIdTxt = Wx::StaticText->new($pnlItem, -1, $self->{'itemId'}, [ -1, -1 ], [ 20, 20 ]);	
	$actionIdTxt->SetForegroundColour($Widgets::Style::clrDarkGray);
	my $stepNameTxt =
	  Wx::StaticText->new( $pnlItem, -1, "", [ -1, -1 ], [ 70, 20 ] );
	$stepNameTxt->SetFont($Widgets::Style::fontSmallLblBold);
	my $emptyBmp =
	  Wx::Bitmap->new(
		GeneralHelper->Root() . "/Resources/Images/EmptyHand.bmp",
		&Wx::wxBITMAP_TYPE_BMP );
	my $actPosition = Wx::StaticBitmap->new( $pnlItem, -1, $emptyBmp );
	$self->{'actPosition'} = $actPosition;
	my $runAllBtn = Wx::Button->new( $pnlItem, -1, "", [ -1, -1 ], [ 20, 20 ] );
	$runAllBtn->SetBitmap($runAllBmp);
	my $runSingleBtn =
	  Wx::Button->new( $pnlItem, -1, "", [ -1, -1 ], [ 20, 20 ] );
	$runSingleBtn->SetBitmap($runSingleBmp);
	my $infoActionBtn =
	  Wx::Button->new( $pnlItem, -1, "", [ -1, -1 ], [ 20, 20 ] );
	$infoActionBtn->SetBitmap($infoBmp);
	my $actionNameTxt =
	  Wx::StaticText->new( $pnlActionName, -1, $self->{'actionName'} );
	my $dateTxt = Wx::StaticText->new( $pnlItem, -1, "" , [ -1, -1 ], [ 100, 20 ]);
	$dateTxt->SetForegroundColour($Widgets::Style::clrDarkGray);
	$self->{'dateTxt'} = $dateTxt;
	my $userNameTxt = Wx::StaticText->new( $pnlItem, -1, "", [ -1, -1 ], [40, 20 ]);
	$userNameTxt->SetForegroundColour($Widgets::Style::clrDarkGray);
	$self->{'userNameTxt'} = $userNameTxt;

	#register EVENTS
	Wx::Event::EVT_BUTTON( $runAllBtn, -1, sub { __OnRunAllClick($self, @_) } );
	Wx::Event::EVT_BUTTON( $runSingleBtn, -1, sub { __OnRunSingle($self, @_) } );
	Wx::Event::EVT_BUTTON( $infoActionBtn, -1, sub { __OnInfoClick($self, @_) } );
 


	#define layout structure
	
	$szRow->Add( $actionIdTxt, 0, &Wx::wxLEFT, 10 );
	$szRow->Add( $stepNameTxt, 0 );
	$szRow->Add( $actPosition, 0 );
	$szRow->Add( $runAllBtn,   0 );
	$szRow->Add( $runSingleBtn,  0 );
	$szRow->Add( $infoActionBtn, 0 );
	$szRow->Add( $pnlActionName, 1, &Wx::wxLEFT | &Wx::wxRIGHT, 10 );
	$szRow->Add( $dateTxt,       0 );
	$szRow->Add( $userNameTxt,   0, &Wx::wxLEFT, 5);
	$szRow->Add( 10, 10, 0 );

	
	

	$pnlItem->SetSizer($szRow);
	$szRow->Layout();

	return $pnlItem;
}



sub __SetLayoutFinish {

	my $self = shift;
	my $parent = $self->{'parent'};

	#define panels
	my $pnlItem = Wx::Panel->new( $parent, -1 );
	$pnlItem->SetBackgroundColour($Widgets::Style::clrLightGray);

	#define sizers
	my $szRow = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);    #top level sizer
	 

	#define controls
	
	my $stepNameTxt = Wx::StaticText->new(
		$pnlItem, -1, "Finish",
		[ -1,  -1 ],
		[ 100, 20 ]
	);
	$stepNameTxt->SetFont($Widgets::Style::fontSmallLblBold);
	 
	my $emptyBmp =  Wx::Bitmap->new(GeneralHelper->Root() . "/Resources/Images/EmptyHand.bmp", &Wx::wxBITMAP_TYPE_BMP );
	my $actPosition = Wx::StaticBitmap->new( $pnlItem, -1, $emptyBmp );
	$self->{'actPosition'} = $actPosition;
	 
	#define layout structure
	$szRow->Add( $stepNameTxt, 0, &Wx::wxLEFT, 10 );
	$szRow->Add( $actPosition, 0 );
	$szRow->Add( 5, 5, 0 );

	$pnlItem->SetSizer($szRow);
	$szRow->Layout();

	return $pnlItem;
}


sub __OnInfoClick {
	my $self = shift;

	my $onInfo = $self->{'onInfo'};
	if ( defined $onInfo ) {

		$onInfo->($self->{'itemId'});
	}
}

sub __OnRunAllClick {
	my $self = shift;

	my $onRunAll = $self->{'onRunAll'};
	if ( defined $onRunAll ) {

		$onRunAll->($self->{'itemType'}, $self->{'itemId'});
	}
}

sub __OnRunSingle {
	my $self = shift;

	my $onRunSingle = $self->{'onRunSingle'};
	if ( defined $onRunSingle ) {

		$onRunSingle->($self->{'itemId'});
	}
}


sub __GetPcbChildName {
	my $self = shift;
	
	if ($self->{'childId'} > 1){
		
		return "pcb".$self->{'childId'};
		
	}else{
		
		return "";
		
	}
	
}

1;

