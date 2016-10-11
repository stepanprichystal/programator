#-------------------------------------------------------------------------------------------#
# Description: Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package PureWindow;
use base 'Wx::App';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

use aliased 'Widgets::Forms::MyWxFrame';
use Widgets::Style;
use aliased 'Programs::Exporter::ExportChecker::ExportChecker::Forms::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';
use aliased 'Programs::Exporter::ExportChecker::Groups::NCExport::View::NCUnitForm';
use aliased 'Packages::InCAM::InCAM';

#tested form


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

	 
	my $mainFrm = $self->__SetLayout($parent);

	# Properties
	
	$mainFrm->Show();
	

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

sub __SetLayout {
	my $self   = shift;
	my $parent = shift;

	#main formDefain forms
	my $mainFrm = MyWxFrame->new(
		$parent,                       # parent window
		-1,                            # ID -1 means any
		"Checking export settings",    # title
		&Wx::wxDefaultPosition,        # window position
		[ 800, 800 ],                                             # size
		&Wx::wxCAPTION | &Wx::wxCLOSE_BOX | &Wx::wxSTAY_ON_TOP |
		  &Wx::wxMINIMIZE_BOX   |  &Wx::wxSYSTEM_MENU   | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	use aliased 'Widgets::Forms::CustomControlList::ControlList';
	use aliased 'Widgets::Forms::CustomControlList::ControlListRow';

	

	my @widths = (100, 100, 100, 100);
	my $widget = ControlList->new($mainFrm, 4, \@widths);
	
	my @titles = ("test1", "test2", "test3", "test4");
	#$widget->SetHeader(\@titles);
	
	
	my $row = ControlListRow->new($widget, "Test");
	$widget->AddRow($row);
	
	my $row2 = ControlListRow->new($widget, "test 2");
	$widget->AddRow($row2);
	
	my $row3 = ControlListRow->new($widget, "test 2");
	$widget->AddRow($row3);
	 

	# Add this rappet to group table
	$szMain->Add( $widget, 0,  &Wx::wxALL, 4 );

	$mainFrm->SetSizer($szMain);
	$mainFrm->Layout();

	return $mainFrm;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
 
	my $test = PureWindow->new(-1, "f13610" );
	 
	$test->MainLoop();
 

1;

