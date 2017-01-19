#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::TpvDbViewer::CustomerTab;
use base 'Wx::App';

#3th party library
use utf8;
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);
use Wx qw(:listctrl :textctrl :font);
use Wx qw(:icon wxTheApp wxNullBitmap);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::LogConnector::LogMethods';
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Widgets::Forms::MyWxListCtrl';
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Programs::CamGuide::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self   = shift;
	my $parent = shift;
 
	$self->{"limit"}        = 100;
	$self->{"actualRecord"} = 0;
	$self->{"totalCount"}   = LogMethods->GetLogActionMessCnt();

	my $mainFrm = $self->__SetLayout($parent);
 

	$self->__Refresh();

	return $self;

}

sub OnInit {
	my $self = shift;

	return 1;
}

#sub __OnClose{
#	my $self = shift;
#	my $mainFrm = shift;
#	my $event = shift;
#
#
#		if(defined $self->{"parent"})
#		{
#			#$obj->Close();
#			$mainFrm->Destroy();
#			print "LogViewver HIDE\n";
#
#			#$event2->Veto();
#		}else{
#			$mainFrm->Destroy();
#			print "LogViewver DESTRTOY"
#		}
#
#}

sub __OnPrevClick {
	my $self    = shift;
	my $actPage = $self->{"nb"}->GetSelection();

	$self->{"actualRecord"} -= $self->{"limit"};
	if ( $self->{"actualRecord"} < 0 ) {
		$self->{"actualRecord"} = 0;
	}

	$self->__Refresh();
}

sub __OnNextClick {
	my $self    = shift;
	my $actPage = $self->{"nb"}->GetSelection();

	$self->{"actualRecord"} += $self->{"limit"};

	$self->__Refresh();
}

sub __Refresh {
	my $self = shift;

	print \$self . "\n";

	if ( $self->{"nb"}->GetSelection() == 0 ) {
		$self->__RefreshAction();

	}
	elsif ( $self->{"nb"}->GetSelection() == 1 ) {
		$self->__RefreshMDI();
	}
	elsif ( $self->{"nb"}->GetSelection() == 1 ) {
		$self->__RefreshJET();
	}
}

sub SetDefaultActionsFilter {
	my $self  = shift;
	my $pcbId = shift;

	$self->{"pcbidTxt"}->SetValue($pcbId);

	$self->{"typeLogChlist"}->Check( 0, 1 );
	$self->{"typeLogChlist"}->Check( 1, 0 );
	$self->{"typeLogChlist"}->Check( 2, 0 );
	$self->{"typeLogChlist"}->Check( 3, 0 );
	$self->{"typeLogChlist"}->Check( 4, 0 );

	$self->__Refresh();
}

sub __RefreshAction {
	my $self = shift;

	print "Refresh" . \$self . "\n";

	#$self->{"actionPnl"} = $pageMainPnl;
	#$self->{"actionList"} = $pageMainPnl;

	my $list = $self->{"actionList"};

	#GET data
	my @rows = $self->__GetFilteredData();

	my @keys =
	  ( "PcbId", "ChildPcbId", "Type", "ActionStep", "ActionOrder", "ActionName", "MessageCode", "MessageType", "MessageResult", "Inserted", "User" );

	$self->{"actionList"}->DisplayData( \@rows, \@keys );

	my $paggingTxt = $self->{"actualRecord"} . " - " . ( $self->{"actualRecord"} + $self->{"limit"} );
	$paggingTxt .= "  (total logs count " . $self->{"totalCount"} . ")";
	$self->{"actionList"}->SetPagingValue($paggingTxt);

	#$self->__RefreshGui();

	$self->{"actionTopSz"}->Layout();
}

sub __GetFilteredData {
	my $self = shift;

	#GET filter vales
	my $pcbId    = $self->{"pcbidTxt"}->GetValue();
	my $childPcbId   = undef;
	my $userName = $self->{"userTxt"}->GetValue();

	my $typeAction = $self->{"typeLogChlist"}->IsChecked(0);

	my @typeMessage = ();

	if ( $self->{"typeLogChlist"}->IsChecked(1) ) {
		push( @typeMessage, EnumsGeneral->MessageType_INFORMATION );
	}
	if ( $self->{"typeLogChlist"}->IsChecked(2) ) {
		push( @typeMessage, EnumsGeneral->MessageType_QUESTION );
	}
	if ( $self->{"typeLogChlist"}->IsChecked(3) ) {
		push( @typeMessage, EnumsGeneral->MessageType_ERROR );
	}
	if ( $self->{"typeLogChlist"}->IsChecked(4) ) {
		push( @typeMessage, EnumsGeneral->MessageType_WARNING );
	}

	my @actionInfo = Helper->GetActionInfos();
	my @rows = LogMethods->GetActionAndMessages( $self->{"limit"}, $self->{"actualRecord"}, $pcbId,$childPcbId, $userName, $typeAction, \@typeMessage );

	for ( my $i = 0 ; $i < scalar(@rows) ; $i++ ) {

		my $r = $rows[$i];

		#Set action name by action code
		if ( defined $r->{"ChildPcbId"} ) {
			if ( $r->{"ChildPcbId"} > 1 ) {
				$r->{"ChildPcbId"} = "pcb" . $r->{"ChildPcbId"};
			}
			else {
				$r->{"ChildPcbId"} = "master";
			}
		}

		#Set action name by action code
		if ( defined $r->{"ActionCode"} ) {

			my @res = grep { $_->{"actionCode"} eq $r->{"ActionCode"} } @actionInfo;

			if ( scalar(@res) > 0 ) {
				$r->{"ActionName"} = $res[0]->{"actionName"};
			}
		}
	}

	$self->__SetRowsColor( \@rows );

	return @rows;
}

sub __AddPage {
	my ( $self, $bookctrl, $string ) = @_;
	my $count = $bookctrl->GetPageCount;
	my $page = MyWxBookCtrlPage->new( $bookctrl, $count );

	$bookctrl->AddPage( $page, $string, 0, $count );
	$bookctrl->SetPageImage( $count, 0 );

	return $page;
}

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;
 
 	$self->__SetLayoutMenu($nb);
	$self->__SetLayoutList($nb);
	 
	 
	 
	 
	#$mainFrm->Fit();
	return $mainFrm;

}

#sub __OnClose {
#	my $self  = shift;
#	my $frm   = shift;
#	my $event = shift;
#
#
#	$frm->Destroy();
#
#
#
#}

sub __SetLayoutActions {

	my $self        = shift;
	my $nb          = shift;
	my $pageMainPnl = $self->__AddPage( $nb, "Actions" );

	my @heading =
	  ( "Id", "ChildId", "Type", "ACTION step", "ACTION order", "ACTION name", "MESSAGE text", "MESSAGE type", "MESSAGE result", "Date", "User" );

	#SIZERS
	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $test     = Wx::StaticBox->new( $pageMainPnl, -1, 'Logs filter' );
	my $szFilter = Wx::StaticBoxSizer->new( $test, &Wx::wxHORIZONTAL );

	my $szFilterPcbUser   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szFilterPcbUser1r = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szFilterPcbUser2r = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#CONTROLOS
	my @types = ( "Actions", "Information", "Qustion", "Errors", "Warnings" );
	my $typeLogChlist = Wx::CheckListBox->new( $test, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize, \@types );
	for ( my $i = 0 ; $i < scalar(@types) ; $i++ ) { $typeLogChlist->Check( $i, 1 ); }

	my $pcbidTxt = Wx::TextCtrl->new( $test, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );
	my $userTxt  = Wx::TextCtrl->new( $test, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );

	my $pcbidStaticTxt = Wx::StaticText->new( $pageMainPnl, -1, 'Id:',   &Wx::wxDefaultPosition, [ 30, 15 ] );
	my $userStaticTxt  = Wx::StaticText->new( $pageMainPnl, -1, 'User:', &Wx::wxDefaultPosition, [ 30, 15 ] );

	my $listCtrl = MyWxListCtrl->new($pageMainPnl);
	$listCtrl->InsertColumns( \@heading, 90 );
	$listCtrl->SetSingleColumnWidth( 0, 60 );
	$listCtrl->SetSingleColumnWidth( 1, 50 );
	$listCtrl->SetSingleColumnWidth( 2, 60 );
	$listCtrl->SetSingleColumnWidth( 4, 50 );
	$listCtrl->SetSingleColumnWidth( 5, 150 );
	$listCtrl->SetSingleColumnWidth( 6, 150 );
	$listCtrl->SetSingleColumnWidth( 9, 120 );

	#BUILD STRUCTURE
	$szFilterPcbUser1r->Add( $pcbidStaticTxt, 0, &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$szFilterPcbUser1r->Add( $pcbidTxt,       0, &Wx::wxALL,                                5 );
	$szFilterPcbUser2r->Add( $userStaticTxt,  0, &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 5 );
	$szFilterPcbUser2r->Add( $userTxt,        0, &Wx::wxALL,                                5 );

	$szFilterPcbUser->Add( $szFilterPcbUser1r, 0, &Wx::wxALL, 0 );
	$szFilterPcbUser->Add( $szFilterPcbUser2r, 0, &Wx::wxALL, 0 );

	$szFilter->Add( $typeLogChlist, 0, &Wx::wxALL, 0 );
	$szFilter->Add( 40, 40, 0, &Wx::wxEXPAND, 0 );
	$szFilter->Add( $szFilterPcbUser, 0, &Wx::wxALL, 0 );

	$szMain->Add( $szFilter, 0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $listCtrl, 0, &Wx::wxALL, 0 );
	$pageMainPnl->SetSizer($szMain);

	#$self->{"mainFrm"}->Layout();
	$szMain->Layout();

	#$szFilter->Layout();

	#SET EVENTS

	Wx::Event::EVT_CHECKLISTBOX( $typeLogChlist, -1, sub { __RefreshAction($self) } );
	Wx::Event::EVT_TEXT( $pcbidTxt, -1, sub { __RefreshAction($self) } );
	Wx::Event::EVT_TEXT( $userTxt,  -1, sub { __RefreshAction($self) } );

	$self->{"actionPnl"}   = $pageMainPnl;
	$self->{"actionTopSz"} = $pageMainPnl;
	$self->{"actionList"}  = $listCtrl;

	$self->{"typeLogChlist"} = $typeLogChlist;
	$self->{"pcbidTxt"}      = $pcbidTxt;
	$self->{"userTxt"}       = $userTxt;

	$listCtrl->{'onPrev'}    = sub { __OnPrevClick($self) };
	$listCtrl->{'onNext'}    = sub { __OnNextClick($self) };
	$listCtrl->{'onRefresh'} = sub { __Refresh($self) };

}
 

sub __SetRowsColor {
	my $self = shift;
	my $rows = shift;

	for ( my $i = 0 ; $i < scalar( @{$rows} ) ; $i++ ) {

		my $r = @{$rows}[$i];

		#print  $pom1->{"MesageType"};
		#print  $pom1{"MesageType"};

		#my $r = @{$rows}[$i];

		unless ( defined $r->{"MessageType"} ) {
			next;
		}

		if ( $r->{"MessageType"} eq EnumsGeneral->MessageType_ERROR ) {
			$r->{"colour"} = $Widgets::Style::clrErrorLight;
		}
		elsif ( $r->{"MessageType"} eq EnumsGeneral->MessageType_WARNING ) {
			$r->{"colour"} = $Widgets::Style::clrWarningLight;
		}
		elsif ( $r->{"MessageType"} eq EnumsGeneral->MessageType_QUESTION ) {
			$r->{"colour"} = $Widgets::Style::clrInfoQuestion;
		}
		elsif ( $r->{"MessageType"} eq EnumsGeneral->MessageType_INFORMATION ) {
			$r->{"colour"} = $Widgets::Style::clrInfoQuestion;
		}
		else {
			$r->{"colour"} = $Widgets::Style::clrInfoQuestion;
		}

	}

}

sub InsertColumn {
	my $self = shift;
	my $idx  = shift;
	my $name = shift;

	my $list = $self->{"list"};

	$list->InsertColumn( $idx, $name );

}

#sub DisplayData {
#
#	my $self = shift;
#	my @rows = ( "a", "b", "c" );
#
#	my @names = ( "Cheese", "Apples", "Oranges" );
#
#	#my( $small, $normal ) = $self->create_image_lists;
#	#$self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
#	#$self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );
#
#	$self->{"list"}->InsertColumn( 0, "Type" );
#	$self->{"list"}->InsertColumn( 1, "Amount" );
#	$self->{"list"}->InsertColumn( 2, "Price" );
#
#	foreach my $i ( 0 .. 50 ) {
#		my $t   = ( rand() * 100 ) % 3;
#		my $q   = int( rand() * 100 );
#		my $idx = $self->{"list"}->InsertImageStringItem( $i, $names[$t], 0 );
#		$self->{"list"}->SetItemData( $idx, $i );
#		$self->{"list"}->SetItem( $idx, 1, $q );
#		$self->{"list"}->SetItem( $idx, 2, $q * ( $t + 1 ) );
#
#		$self->{"list"}
#		  ->SetItemBackgroundColour( $idx, $Widgets::Style::clrWarning );
#
#	}
#
#}

sub __WriteMessages() {

	my $self    = shift;
	my $richTxt = shift;

	$richTxt->BeginFontSize(13);

	my @messages = @{ $self->{messages} };

	for ( my $i = 0 ; $i < scalar(@messages) ; $i++ ) {

		$richTxt->BeginItalic;
		$richTxt->WriteText(" - ");
		$richTxt->EndBold;

		$richTxt->WriteText( $messages[$i] );

		if ( $i + 1 != scalar(@messages) ) {
			$richTxt->BeginFontSize(8);
			$richTxt->Newline;
			$richTxt->Newline;
			$richTxt->BeginFontSize(13);
		}
	}

}

sub __GetHeightOfText {
	my $self     = shift;
	my @messages = @{ $self->{messages} };

	my $rowCount = 0;

	for ( my $i = 0 ; $i < scalar(@messages) ; $i++ ) {

		$rowCount += ( int( length( $messages[$i] ) / 100 ) + 1 );
	}

	$rowCount += scalar(@messages);

	#22 is size for one line. If line is only one add some free space 15px
	my $space = ( scalar(@messages) == 1 ) ? 15 : 0;
	return $rowCount * 22 + $space;
}

sub __AddButtons {
	my $self        = shift;
	my $pnlBtns     = shift;
	my $szBtnsChild = shift;
	my @buttons     = undef;

	unless ( defined $self->{buttons} ) {
		push( @{ $self->{buttons} }, "Ok" );
	}

	@buttons = @{ $self->{buttons} };

	for ( my $i = 0 ; $i < scalar(@buttons) ; $i++ ) {

		my $btn = $buttons[$i];

		my $button = Wx::Button->new( $pnlBtns, -1, $btn );
		$button->SetFont($Widgets::Style::fontBtn);
		$button->{"order"} = $i;

		$szBtnsChild->Add( $button, 0, &Wx::wxALL, 5 );

		Wx::Event::EVT_BUTTON( $button, -1, sub { __OnClick( $self, $button ) } );

	}
}

sub __OnClick {

	my ( $parent, $button ) = @_;
	$parent->{"result"} = $button->{"order"};

	my $onExit = $parent->{onExit};

	$onExit->();
}

sub __GetIcoName {
	my $self = shift;

	my $imgName = "";

	if ( $self->{type} eq EnumsGeneral->MessageType_ERROR ) {
		$imgName = "Error";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_WARNING ) {
		$imgName = "Warning";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_QUESTION ) {
		$imgName = "Question";
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_INFORMATION ) {
		$imgName = "Info";
	}
	else {
		$imgName = "Info";
	}

	return $imgName;
}

sub __GetIcoColor {
	my $self = shift;

	my $iconColor = "";

	if ( $self->{type} eq EnumsGeneral->MessageType_ERROR ) {
		$iconColor = $Widgets::Style::clrError;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_WARNING ) {
		$iconColor = $Widgets::Style::clrWarning;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_QUESTION ) {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}
	elsif ( $self->{type} eq EnumsGeneral->MessageType_INFORMATION ) {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}
	else {
		$iconColor = $Widgets::Style::clrInfoQuestion;
	}

	return $iconColor;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ($package, $filename, $line) = caller;
if ($filename =~ /DEBUG_FILE.pl/) {

	my $app = Programs::LogViewer::LogViewer->new();

	$app->MainLoop;

	print "Finish";

}

1;
