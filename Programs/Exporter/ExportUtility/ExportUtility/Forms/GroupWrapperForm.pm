#-------------------------------------------------------------------------------------------#
# Description: Wrapper wifget for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::ExportUtility::Forms::GroupWrapperForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Widgets::Style;

#local library

use aliased 'Programs::Exporter::ExportChecker::Enums';

use aliased 'Packages::Events::Event';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new($parent);

	bless($self);

	#$self->{"state"} = Enums->GroupState_ACTIVEON;

	$self->__SetLayout();
	
	#EVENTS
	
	#$self->{"onChangeState"} = Event->new();

	return $self;
}

sub Init {
	my $self      = shift;
	my $groupName = shift;
	my $groupBody = shift;

	$self->{"headerTxt"}->SetLabel($groupName);

	$self->{"bodySizer"}->Add( $groupBody, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$self->{"groupHeight"} = $groupBody->{"groupHeight"};

	# panel, which contain group content
	$self->{"groupBody"} = $groupBody;


}

 

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS
	
	my $szHeaderBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlHeader = Wx::Panel->new( $self, -1 );
	my $szHeader = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);


	# DEFINE PANELS
	
	$pnlHeader->SetBackgroundColour( Wx::Colour->new( 228, 232, 243 ) );
	#$pnlHeader->SetBackgroundColour($Widgets::Style::clrLightGreen);
	
	my $pnlBody = Wx::Panel->new( $self, -1 );
	$pnlBody->SetBackgroundColour( Wx::Colour->new( 245, 245, 245 ) );
	

	# use Wx qw( EVT_MOUSE_EVENTS);
	# use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

	# DEFINE CONTROLS

	my $headerTxt = Wx::StaticText->new( $pnlHeader, -1, "Default title" );
	
	my $height = 20;
	$height += rand(300);
	
	my $pnl = Wx::Panel->new( $pnlBody, -1, [-1, -1], [100, $height] );
	
	$self->{"headerTxt"} = $headerTxt;

	# BUILD STRUCTURE 
	
	 
	$szHeader->Add( $headerTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );


	$szBody->Add( $pnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$pnlHeader->SetSizer($szHeader);

	$pnlBody->SetSizer($szBody);

	$szHeaderBody->Add( $pnlHeader, 0, &Wx::wxEXPAND );
	$szHeaderBody->Add( $pnlBody,   1, &Wx::wxEXPAND );

	$self->SetSizer($szHeaderBody);
	
	$szHeaderBody->Layout();


	# SAVE REFERENCES
	
	$self->{"bodySizer"}    = $szBody;
	$self->{"szHeaderBody"} = $szHeaderBody;
	$self->{"pnlHeader"} = $pnlHeader;
	$self->{"pnlBody"}   = $pnlBody;

}


sub GetParentForGroup {
	my $self = shift;

	return $self->{"pnlBody"};
}

1;
