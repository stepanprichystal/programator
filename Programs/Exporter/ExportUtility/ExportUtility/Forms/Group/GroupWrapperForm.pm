#-------------------------------------------------------------------------------------------#
# Description: Wrapper wifget for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupWrapperForm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Widgets::Style;

#local library

use aliased 'Programs::Exporter::ExportChecker::Enums';

use aliased 'Packages::Events::Event';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupItemForm';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::ItemForm';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupStatusForm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my ( $class, $parent ) = @_;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# contains names of all group item
	my @groups = ();
	$self->{"groups"} = \@groups;

	#$self->{"state"} = Enums->GroupState_ACTIVEON;

	$self->__SetLayout();

	#$self->{"column"} = undef;

	#EVENTS

	#$self->{"onChangeState"} = Event->new();

	return $self;
}

sub __AddGroupItem {
	my $self  = shift;
	my $title = shift;

	# if group still doesnt exist, add it
	unless ( scalar( grep { $_ eq $title } @{ $self->{"groups"} } ) ) {

		push( @{ $self->{"groups"} }, $title );

		my $item = GroupItemForm->new( $self->{"pnlBody"}, $title );
		$self->{"bodySizer"}->Add( $item, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	}

}

sub AddItem {
	my $self       = shift;
	my $resultItem = shift;

	my $groupName = $resultItem->GetGroup();
	my $subItem   = 0;

	if ($groupName) {
		$self->__AddGroupItem($groupName);
		$subItem = 1;
	}

	my $item = ItemForm->new( $self->{"pnlBody"}, $resultItem->ItemId(), $subItem );
	$item->SetErrors( $resultItem->GetErrorCount() );
	$item->SetWarnings( $resultItem->GetWarningCount() );

	$self->{"bodySizer"}->Add( $item, 0, &Wx::wxEXPAND );

	return 0;

	#$self->{"bodySizer"}->Layout();
}

sub Init {
	my $self      = shift;
	my $groupName = shift;

	#my $groupBody = shift;

	$self->{"headerTxt"}->SetLabel($groupName);

	#	$self->{"bodySizer"}->Add( $groupBody, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	#$self->{"groupHeight"} = $groupBody->{"groupHeight"};

	# panel, which contain group content
	#$self->{"groupBody"} = $groupBody;

}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS

	my $szHeaderBody = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlHeader = Wx::Panel->new( $self, -1 );
	my $szHeader  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBody    = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE PANELS

	$pnlHeader->SetBackgroundColour( Wx::Colour->new( 228, 232, 243 ) );

	#$pnlHeader->SetBackgroundColour($Widgets::Style::clrLightGreen);

	my $pnlBody = Wx::Panel->new( $self, -1 );
	$pnlBody->SetBackgroundColour( Wx::Colour->new( 245, 245, 245 ) );

	# use Wx qw( EVT_MOUSE_EVENTS);
	# use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

	# DEFINE CONTROLS

	my $headerTxt = Wx::StaticText->new( $pnlHeader, -1, "Default title" );
	my $groupStatus = GroupStatusForm->new($pnlHeader);

	my $height = 20;
	$height += rand(300);

	#my $pnl = Wx::Panel->new( $pnlBody, -1, [ -1, -1 ], [ 100, $height ] );

	$self->{"headerTxt"} = $headerTxt;

	# BUILD STRUCTURE

	$szHeader->Add( $headerTxt,   1, &Wx::wxEXPAND | &Wx::wxALL, 2 );
	$szHeader->Add( $groupStatus, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$szBody->Add( $pnl, 1, &Wx::wxEXPAND | &Wx::wxALL, 2 );

	$pnlHeader->SetSizer($szHeader);

	$pnlBody->SetSizer($szBody);

	$szHeaderBody->Add( $pnlHeader, 0, &Wx::wxEXPAND );
	$szHeaderBody->Add( $pnlBody,   1, &Wx::wxEXPAND );

	$self->SetSizer($szHeaderBody);

	#$szHeaderBody->Layout();

	# SAVE REFERENCES

	$self->{"bodySizer"}    = $szBody;
	$self->{"szHeaderBody"} = $szHeaderBody;
	$self->{"pnlHeader"}    = $pnlHeader;
	$self->{"pnlBody"}      = $pnlBody;
	$self->{"groupStatus"}  = $groupStatus;

}

sub GetParentForGroup {
	my $self = shift;

	return $self->{"pnlBody"};
}

sub SetStatus {
	my $self = shift;
	my $value = shift;

	$self->{"groupStatus"}->SetStatus($value);
}

sub SetErrorCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupStatus"}->SetErrorCnt($cnt);
}

sub SetWarningCnt {
	my $self = shift;
	my $cnt  = shift;

	$self->{"groupStatus"}->SetWarningCnt($cnt);
}

sub SetResult {
	my $self   = shift;
	my $result = shift;

	$self->{"groupStatus"}->SetResult($result);
}

1;
