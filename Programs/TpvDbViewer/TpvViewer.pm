use utf8;

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::LogViewer::LogViewer;
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

use aliased 'Programs::TpvDbViewer::CustomerTab';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self   = shift;
	my $parent = shift;
	$self = {};

	unless ($parent) {
		$self = Wx::App->new( \&OnInit );
	}

	bless($self);

	$self->{"limit"}        = 100;
	$self->{"actualRecord"} = 0;
	$self->{"totalCount"}   = LogMethods->GetLogActionMessCnt();

	my $mainFrm = $self->__SetLayout($parent);

	#$self->SetTopWindow($mainFrm);
	$mainFrm->Show(1);

	$self->__Refresh();

	return $self;

}

sub OnInit {
	my $self = shift;

	return 1;
}

 

sub __SetLayout {

	my $self   = shift;
	my $parent = shift;

	#EVT_NOTEBOOK_PAGE_CHANGED( $self, $nb, $self->can( 'OnPageChanged' ) );

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                   # parent window
		-1,                        # ID -1 means any
		"Log viewer" . \$self,     # title
		&Wx::wxDefaultPosition,    # window position
		[ 960, 900 ],              # size
		                           #&Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	$self->{"mainFrm"} = $mainFrm;

	my $nb = Wx::Notebook->new( $mainFrm, -1, &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $imagelist = Wx::ImageList->new( 2, 32 );
	$nb->AssignImageList($imagelist);

	$self->{"nb"} = $nb;
 
 
 	# INIT TABS
 
	my $pageCust = $self->__AddPage( $nb, "Customers" );
	my $custTab = CustomerTab->new($pageCust);
	
 
	return $mainFrm;

}

sub __AddPage {
	my ( $self, $bookctrl, $string ) = @_;
	my $count = $bookctrl->GetPageCount;
	my $page = MyWxBookCtrlPage->new( $bookctrl, $count );

	$bookctrl->AddPage( $page, $string, 0, $count );
	$bookctrl->SetPageImage( $count, 0 );

	return $page;
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
