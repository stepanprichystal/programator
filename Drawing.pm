#-------------------------------------------------------------------------------------------#
# Description: Popup, which shows result from export checking
# Allow terminate thread, which does checking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Drawing;
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
		[ 800, 800 ],                  # size
		&Wx::wxCAPTION | &Wx::wxCLOSE_BOX | &Wx::wxSTAY_ON_TOP |
		  &Wx::wxMINIMIZE_BOX | &Wx::wxSYSTEM_MENU | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX
	);

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	
	
	 Wx::Event::EVT_PAINT($self,\&paint);
 

	$mainFrm->SetSizer($szMain);
	$mainFrm->Layout();
	
	
	
	$self->{"mainFrm"} = $mainFrm;
 
	
	$self->{"mainFrm"}->Show(1);

	return $mainFrm;
}


sub Test{
	my ( $self, $event ) = @_;
	
	$self->{"dc"} = Wx::ClientDC->new( $self->{"mainFrm"} );
	
	 
	
	$self->{"dc"}->SetBrush( Wx::Brush->new( 'blue',&Wx::wxSOLID ) );
	
	my @arr = (Wx::Point->new(10, 10 ), Wx::Point->new(20, 20 ), Wx::Point->new(40, 20 ), Wx::Point->new(40, -10 )); 
	$self->{"dc"}->DrawPolygon( \@arr,  40, 40 );
	
	my $i = 0;
	foreach (1..1000){
		
		$self->{"dc"}->DrawPolygon( \@arr,  $i, $i );
		$i+= 5;
	}
	
	 
	 
}

sub paint {
	my ( $self, $event ) = @_;
	#my $dc = Wx::PaintDC->new( $self->{frame} );

 	
   $self->{"dc"} = Wx::ClientDC->new( $self->{"mainFrm"} ); 
  #$self->{"dc"}->SetBrush( Wx::Brush->new( 'black',&Wx::wxSOLID ) );
  $self->{"dc"}->DrawRectangle( 100,100, 200,200 );

 
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my $test = Drawing->new( -1, "f13610" );
$test->Test();
$test->MainLoop();

1;

