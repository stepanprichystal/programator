

package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm;
use base qw(Wx::Panel);

use strict;

use Wx;
use Widgets::Style;


sub new {
	my ( $class, $parent ) = @_;
	
	my $self = $class->SUPER::new($parent);

	bless($self);
	
	$self->{"inCAM"} = shift;
	
	$self->{"title"} = shift;
	

	$self->__SetLayout();
	
	$self->__SetName();
	
	#$self->Disable();

	#$self->SetBackgroundColour($Widgets::Style::clrLightBlue);

	return $self;
}


#sub Init{
#	my $self = shift;	
#	my $parent = shift;
#	
#	$self->Reparent($parent);
#	
#	$self->__SetLayout();
#	
#	$self->__SetName();
#}


sub __SetName {
	my $self = shift;
	
	$self->{"title"} = "Nif group";
	
}

sub __SetHeight {
	my $self = shift;
	my $height = shift;
	
	$self->{"groupHeight"} = $height;
	
}


sub __SetLayout {
	my $self = shift;

	#define panels
	
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $rowCount = 15;
	 
	for (my $i = 0; $i < $rowCount; $i++){
		
		my $testTxt = Wx::StaticText->new( $self, -1, "Row_$i".$self->{"title"}, [ -1, -1 ], [-1, -1 ] );
		$szMain->Add( $testTxt, 1, &Wx::wxEXPAND );
	}
 
 
	$self->SetSizer($szMain);
	
	
	$self->__SetHeight($rowCount*20);
 
}



1;
