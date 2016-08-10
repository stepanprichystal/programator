#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Forms::GuideFrm;
use base 'Wx::App';

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:richtextctrl :textctrl :font);
use Wx qw(:icon wxTheApp wxNullBitmap);

BEGIN {
	eval { require Wx::RichText; };
}

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::CamGuide::Enums';
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Programs::CamGuide::Forms::GuideItem';
use aliased 'Programs::CamGuide::Forms::ScrollPanel';
use aliased 'Programs::LogViewer::LogViewer';
use aliased 'Programs::CamGuide::GuideSelector';

use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self   = shift;
	my $parent = shift;

	$self = {};

	if ( !defined $parent || $parent == -1 ) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	$self->{'pcbId'}       = shift;
	$self->{'guideId'}     = shift;
	$self->{'childId'}     = shift;
	$self->{'actionQueue'} = shift;
	$self->{'messMngr'}    = shift;

	#EVENTS=========================
	#event, when some action happen
	$self->{'onRunAll'}       = undef;
	$self->{'onRunSingle'}    = undef;
	$self->{'onGuideChanged'} = undef;

	my @items = ();
	$self->{"actionItemQueue"} = \@items;    #item is ref on GuidItem.pm object
	my $mainFrm = $self->__SetLayout($parent);

	#$self->SetTopWindow($mainFrm);

	$mainFrm->Show(1);

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;

	my @actionQueue = ();

	if ( defined $self->{'actionQueue'} ) {
		@actionQueue = @{ $self->{'actionQueue'} };
	}

	my $actionCount = scalar(@actionQueue);

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                                  # parent window
		-1,                                       # ID -1 means any
		"Guide - " . $self->{'pcbId'} . $self,    # title
		&Wx::wxDefaultPosition,                   # window position
		[ 550, 600 ],    # size
		                 #&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	#define staticboxes
	my $frstStatBox = Wx::StaticBox->new( $mainFrm, -1, 'Guide info' );
	my $szFrstStatBox = Wx::StaticBoxSizer->new( $frstStatBox, &Wx::wxHORIZONTAL );

	my $secStatBox = Wx::StaticBox->new( $mainFrm, -1, 'Guide actions' );
	my $szSecStatBox = Wx::StaticBoxSizer->new( $secStatBox, &Wx::wxVERTICAL );

	#define panels
	my $pnlHeader = Wx::Panel->new( $secStatBox, -1 );
	$pnlHeader->SetBackgroundColour($Widgets::Style::clrDefaultFrm);

	# rowHeight;
	my $rowHeight = 22;
	my $scrollPnl = ScrollPanel->new( $secStatBox, $rowHeight );
	$scrollPnl->SetRowCount( $actionCount + 10 );

	#define sizers
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#my $szGridInfo = Wx::GridSizer->new( 2, 4, 1, 1, );
	my $szInfo1Clmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szInfo2Clmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szInfo3Clmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szInfo4Clmn = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szInfo          = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szActionList    = Wx::BoxSizer->new(&Wx::wxVERTICAL);     #top level sizer
	my $szActionsHeader = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#define controls
	my $guideTypeTxt = Wx::StaticText->new( $frstStatBox, -1, "Guide type:", &Wx::wxDefaultPosition, [ 30, 22 ] );
	my $stepsTypeTxt = Wx::StaticText->new( $frstStatBox, -1, "Pcb type:",   &Wx::wxDefaultPosition, [ 30, 22 ] );

	#my $guideTypeValTxt =  Wx::StaticText->new( $frstStatBox, -1, $self->{'guideName'}, &Wx::wxDefaultPosition,[ 120, 25 ] );
	my $stepsTypeValTxt = Wx::StaticText->new( $frstStatBox, -1, $self->__GetPcbType(), &Wx::wxDefaultPosition, [ 50, 22 ] );

	#my $changeBtn = Wx::Button->new( $frstStatBox, -1, "Change" );

	my $showLogsTxt = Wx::StaticText->new( $frstStatBox, -1, "All logs for pcb:", &Wx::wxDefaultPosition, [ 100, 22 ] );
	my $showLogsBtn = Wx::Button->new( $frstStatBox, -1, "Show all" , &Wx::wxDefaultPosition, [ 100, 22 ]);

	my @guideTypes = $self->__GetGuideTypes();
	my $guidTypeCb = Wx::ComboBox->new( $frstStatBox, -1, $self->__GetGuideNameById(), [ -1, -1 ], [ 200, 22 ], \@guideTypes, &Wx::wxCB_READONLY );

	#EVT_COMBOBOX( $self, $combobox, \&OnCombo );

	#EVT_TEXT_ENTER( $self, $combobox, \&OnComboTextEnter );

	my $column1Txt = Wx::StaticText->new( $pnlHeader, -1, "Step name", &Wx::wxDefaultPosition, [ 190, 20 ] );
	my $column2Txt = Wx::StaticText->new( $pnlHeader, -1, "Action name" );
	my $column3Txt = Wx::StaticText->new( $pnlHeader, -1, "Date", &Wx::wxDefaultPosition, [ 100, 20 ] );
	my $column4Txt = Wx::StaticText->new( $pnlHeader, -1, "User", &Wx::wxDefaultPosition, [ 70, 20 ] );

	#$column1Txt->SetFont($Widgets::Style::fontSmallLblBold);
	#$column2Txt->SetFont($Widgets::Style::fontSmallLblBold);
	#$column3Txt->SetFont($Widgets::Style::fontSmallLblBold);
	#$column4Txt->SetFont($Widgets::Style::fontSmallLblBold);

	#add "action" items
	my $guideItem  = undef;
	my $actualStep = "";
	my %action     = ();
	my $j          = 0;       #step id
	my $i          = 0;       #action id
	for ( ; $i < scalar(@actionQueue) ; $i++ ) {

		%action = %{ $actionQueue[$i] };

		#add step
		if ( $actualStep ne $action{"actionStep"} ) {
			$guideItem = GuideItem->new( $scrollPnl, Enums->GUIDEITEM_STEP, $j, $self->__GetStepName( $action{"actionStep"} ) );
			$szActionList->Add( $guideItem->{"item"}, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
			$j++;

			$guideItem->{'onRunAll'} = sub { __OnRunAllClick( $self, @_ ) };
		}

		$guideItem = GuideItem->new( $scrollPnl, Enums->GUIDEITEM_ACTION, $i, $action{"actionStep"}, $action{"actionName"}, $action{"actionDesc"},
									 $action{"inserted"}, $action{"user"} );

		$szActionList->Add( $guideItem->{"item"}, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
		push( @{ $self->{'actionItemQueue'} }, $guideItem );

		#$guideItem->{'onRunAll'} = sub { $self->__OnRunAllClick(@_)};
		#$guideItem->{'onRunSingle'} = sub { $self->__OnRunSingleClick(@_)};
		#$guideItem->{'onInfo'} = sub { $self->__OnInfoClick(@_)};

		$guideItem->{'onRunAll'} = sub { __OnRunAllClick( $self, @_ ) };
		$guideItem->{'onRunSingle'} = sub { __OnRunSingleClick( $self, @_ ) };
		$guideItem->{'onInfo'} = sub { __OnInfoClick( $self, @_ ) };

		$actualStep = $action{"actionStep"};
	}

	$guideItem = GuideItem->new( $scrollPnl, Enums->GUIDEITEM_FINISH, scalar(@actionQueue) );
	$szActionList->Add( $guideItem->{"item"}, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	push( @{ $self->{'actionItemQueue'} }, $guideItem );

	#register events
	Wx::Event::EVT_PAINT( $scrollPnl, sub { __OnPaint( $self, $mainFrm, @_ ) } );
	Wx::Event::EVT_BUTTON( $showLogsBtn, -1, sub { __OnShowAllClick( $self, @_ ) } );
	Wx::Event::EVT_TEXT( $guidTypeCb, -1, sub { __OnGuidChanged( $self, @_ ) } );

	#built layout structure

	$szInfo1Clmn->Add( $guideTypeTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szInfo1Clmn->Add( $stepsTypeTxt,    0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	
	$szInfo2Clmn->Add( $guidTypeCb, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szInfo2Clmn->Add( $stepsTypeValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szGridInfo->Add( 10,            10, 0,                          &Wx::wxEXPAND );
	$szInfo3Clmn->Add( $showLogsTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	
	$szInfo4Clmn->Add( $showLogsBtn, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	
	#$szGridInfo->Add( $stepsTypeValTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szInfo->Add( $guideTypeTxt, 0, &Wx::wxALIGN_CENTRE_VERTICAL | &Wx::wxEXPAND | &Wx::wxALL, 1);
	#$szInfo->Add( $guideTypeValTxt, 0,  &Wx::wxALIGN_CENTRE_VERTICAL | &Wx::wxEXPAND | &Wx::wxALL, 1);
	#$szInfo->Add( $changeBtn, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1);
	#$szInfo->Add( 50, 10, 1, );
	#$szInfo->Add( $showLogsTxt, 0,  &Wx::wxALIGN_CENTRE_VERTICAL | &Wx::wxEXPAND | &Wx::wxALL, 1);
	#$szInfo->Add( $showLogsBtn, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1);

	$szActionsHeader->Add( 5, 5, 0, &Wx::wxALL, 2 );
	$szActionsHeader->Add( $column1Txt, 0, &Wx::wxALL, 0 );
	$szActionsHeader->Add( $column2Txt, 1, &Wx::wxALL, 0 );
	$szActionsHeader->Add( $column3Txt, 0, &Wx::wxALL, 0 );
	$szActionsHeader->Add( $column4Txt, 0, &Wx::wxALL, 0 );
	$pnlHeader->SetSizer($szActionsHeader);
	$scrollPnl->SetSizer($szActionList);

	#$szFrstStatBox->Add( $szInfo, 0, &Wx::wxEXPAND );
	$szFrstStatBox->Add( $szInfo1Clmn, 15, &Wx::wxEXPAND );
		$szFrstStatBox->Add( $szInfo2Clmn, 35, &Wx::wxEXPAND );
		$szFrstStatBox->Add( 10, 10 , 0, &Wx::wxEXPAND );
			$szFrstStatBox->Add( $szInfo3Clmn, 25, &Wx::wxEXPAND );
				$szFrstStatBox->Add( $szInfo4Clmn, 25, &Wx::wxEXPAND );
	$szSecStatBox->Add( $pnlHeader, 0, &Wx::wxEXPAND );
	$szSecStatBox->Add( $scrollPnl, 1, &Wx::wxEXPAND );

	$szMain->Add( $szFrstStatBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	#$szMain->Add( 5, 5, 0, &Wx::wxEXPAND  | &Wx::wxALL, 4 );
	$szMain->Add( $szSecStatBox, 1, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$mainFrm->SetSizer($szMain);

	$self->{"mainFrm"}   = $mainFrm;
	$self->{"scrollPnl"} = $scrollPnl;
	$self->{"szMain"}    = $szMain;

	$mainFrm->Layout();

	return $mainFrm;
}

sub __OnShowAllClick {
	my $self    = shift;
	my $mainFrm = shift;
	my $btn     = shift;
	my $event   = shift;

	my $logViewer = LogViewer->new($mainFrm);
	$logViewer->SetDefaultActionsFilter( $self->{"pcbId"} );

	#my $myApp = MyApp->new();

}

sub __OnGuidChanged {
	my $self  = shift;
	my $cb    = shift;
	my $event = shift;

	my $id = $self->__GetGuideIdByName( $cb->GetStringSelection() );

	my $onGuideChanged = $self->{'onGuideChanged'};

	if ( defined $onGuideChanged ) {

		$onGuideChanged->( $self->{"mainFrm"}, $id );
	}

}

sub __OnPaint {
	my $self      = shift;
	my $mainFrm   = shift;
	my $scrollPnl = shift;
	my $event     = shift;

	$mainFrm->Layout();
	$scrollPnl->FitInside();
}

sub SetActualItem {
	my $self     = shift;
	my $actionId = shift;

	my $item = @{ $self->{'actionItemQueue'} }[$actionId];

	$item->SetActualItem();

	for ( my $i = 0 ; $i < scalar( @{ $self->{'actionItemQueue'} } ) ; $i++ ) {

		$item = @{ $self->{'actionItemQueue'} }[$i];

		if ( $i < $actionId ) {
			if ( $item->{'actionInserted'} ne "" ) {
				$item->SetGreenColour();
			}
			else {
				$item->SetRedColour();
			}

			$item->SetInsertedInfo();    #set column User, Inserted

		}

	}

	#$self->{"mainFrm"}->Fit();
	#$self->{"szMain"}->Layout();
	#$self->{"mainFrm"}->SetMinSize([500,600]);
	$self->{"mainFrm"}->Refresh();

	#$self->{"mainFrm"}->Refresh();

	#DODELAT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
}

sub __OnInfoClick {
	my $self = shift;

	my $itemId = shift;

	my @actionQueue = @{ $self->{'actionQueue'} };
	my $action      = $actionQueue[$itemId];

	my @mess = ( "Step: " . $action->{"actionStep"}, "Action: " . $action->{"actionDesc"} );
	my $mainFrm = $self->{"mainFrm"};
	$self->{'messMngr'}->Show( $mainFrm, EnumsGeneral->MessageType_INFORMATION, \@mess );

}

sub __OnRunAllClick {
	my $self = shift;

	my $itemType = shift;
	my $itemId   = shift;

	my $onRunAll = $self->{'onRunAll'};
	if ( defined $onRunAll ) {

		$onRunAll->( $self->{"mainFrm"}, $itemType, $itemId, $self );
	}
}

sub __OnRunSingleClick {
	my $self = shift;

	my $itemType = shift;
	my $itemId   = shift;

	my $onRunSingle = $self->{'onRunSingle'};
	if ( defined $onRunSingle ) {

		$onRunSingle->( $self->{"mainFrm"}, $itemType, $itemId );
	}
}

sub __GetPcbType {
	my $self = shift;

	if ( $self->{'childId'} > 1 ) {

		return "Child - pcb" . $self->{'childId'};

	}
	else {

		return "Master";
	}
}

sub __GetStepName {
	my $self     = shift;
	my $stepName = shift;

	if (    $stepName eq Enums->ActualStep_STEPO
		 || $stepName eq Enums->ActualStep_STEPOPLUS1 )
	{

		if ( $self->{'childId'} > 1 ) {

			$stepName = $stepName . "_pcb" . $self->{'childId'};
		}
	}

	return $stepName;
}

sub __GetGuideTypes {
	my $self     = shift;
	my @typesStr = ();

	my $guideSelector = GuideSelector->new();
	my $temp          = $guideSelector->GetGuideTypes();

	if ($temp) {

		@typesStr = map { $_->{"name"} } @{$temp};
	}
	return @typesStr;
}

sub __GetGuideIdByName {
	my $self = shift;
	my $name = shift;
	my $id;

	my $guideSelector = GuideSelector->new();
	my $temp          = $guideSelector->GetGuideTypes();

	if ($temp) {

		my $guidInfo = ( grep { $_->{"name"} eq $name } @{$temp} )[0];
		$id = $guidInfo->{"id"};
	}

	return $id;
}

sub __GetGuideNameById {
	my $self = shift;
	my $id   = $self->{'guideId'};
	my $name;

	my $guideSelector = GuideSelector->new();
	my $temp          = $guideSelector->GetGuideTypes();

	if ($temp) {

		my $guidInfo = ( grep { $_->{"id"} == $id } @{$temp} )[0];
		$name = $guidInfo->{"name"};
	}

	return $name;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

if (0) {

	my $test = Programs::CamGuide::Forms::GuideForm->new( "d11111", "typ pool" );

	$test->MainLoop();

}

1;

