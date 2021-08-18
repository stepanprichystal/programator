
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::MDIExport::View::LayerList::LayerListRowFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use utf8;
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Comments::Enums';
use aliased 'Programs::Exporter::ExportChecker::Groups::PlotExport::View::PlotList::LayerColorPnl';
use aliased 'Packages::Gerbers::Mditt::ExportFiles::Enums' => 'MDITTEnums';
use Widgets::Style;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class    = shift;
	my $parent   = shift;
	my $layerCnt = shift;
	my $coupleId = shift;
	my $topLayer = shift;
	my $botLayer = shift;
	my $export   = shift;

	my $self = $class->SUPER::new( $parent, $coupleId, undef );

	bless($self);

	# PROPERTIES
	$self->{"topLayer"} = $topLayer;
	$self->{"botLayer"} = $botLayer;

	$self->__SetLayout( $layerCnt, $export );

	# EVENTS

	return $self;
}

sub GetTopLayer {
	my $self = shift;

	return $self->{"topLayer"};
}

sub GetBotLayer {
	my $self = shift;

	return $self->{"botLayer"};
}

sub LayerExist {
	my $self  = shift;
	my $lName = shift;

	if (    ( defined $self->{"topLayer"} && $self->{"topLayer"} eq $lName )
		 || ( defined $self->{"botLayer"} && $self->{"botLayer"} eq $lName ) )
	{

		return 1;
	}
	else {

		return 0;
	}

}

sub __SetLayout {
	my $self         = shift;
	my $layerCnt     = shift;
	my $exportCouple = shift;

	# DEFINE SIZERS
	my $layout = $self->{"commLayout"};

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szCol1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szCol3 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szCol3Row1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szCol3Row2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	$self->SetBackgroundColour( Wx::Colour->new( 235, 235, 235 ) );

	my $exportChb = Wx::CheckBox->new( $self, -1, "", [ -1, -1 ], [ 15, 22 ] );
	my $layerColor = LayerColorPnl->new( $self, $self->GetTopLayer(), 10 );

	my $topLayerTxt = Wx::StaticText->new( $self, -1, $self->GetTopLayer(), &Wx::wxDefaultPosition, [ 55, 22 ] );
	my $botLayerTxt =
	  Wx::StaticText->new( $self, -1, ( defined $self->GetBotLayer() ? $self->GetBotLayer() : "" ), &Wx::wxDefaultPosition, [ 55, 22 ] );

	my @rotOptions = ( "V", "H" );

	my $topLayerRotChb = Wx::ComboBox->new( $self, -1, $rotOptions[0], &Wx::wxDefaultPosition, [ 32, 22 ], \@rotOptions, &Wx::wxCB_READONLY );
	my $botLayerRotChb = Wx::ComboBox->new( $self, -1, $rotOptions[0], &Wx::wxDefaultPosition, [ 32, 22 ], \@rotOptions, &Wx::wxCB_READONLY );

	my @fiducOptions = ();

	my $layerName = defined $self->GetTopLayer() ? $self->GetTopLayer() : $self->GetBotLayer();

	if ( $layerName =~ /^(outer)?[csv]\d?$/ ) {

		# SIGNAL LAYERS
		if ( $layerCnt <= 2 ) {
			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLE2V );
		}
		else {

			if ( $layerName =~ /^outer?[cs]$/ || $layerName =~ /^v\d$/ ) {

				push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEINNERVV );
				push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEINNERVVSL );

			}

			if ( $layerName =~ /^[cs]$/ ) {

				push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEOUTERVV );
			}

		}
	}
	elsif ( $layerName =~ /^m[cs]\d?$/ ) {

		# SOLDER MASK
		if ( $layerCnt <= 2 ) {

			# 2v

			push( @fiducOptions, MDITTEnums->Fiducials_CUSQUERE );
			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLE2V );

		}
		else {

			# vv

			push( @fiducOptions, MDITTEnums->Fiducials_CUSQUERE );
			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEOUTERVV );

		}

	}
	elsif ( $layerName =~ /^plg[csv]\d?$/ ) {

		# PLUG LAYERS
		if ( $layerCnt <= 2 ) {

			# 2v

			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLE2V );

		}
		else {

			# vv

			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEINNERVVSL );
			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEINNERVV );

		}

	}
	elsif ( $layerName =~ /^gold[cs]\d?$/ ) {

		# GOLD LAYER

		if ( $layerCnt <= 2 ) {

			# 2v

			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLE2V );
			push( @fiducOptions, MDITTEnums->Fiducials_CUSQUERE );

		}
		else {

			# vv
			push( @fiducOptions, MDITTEnums->Fiducials_OLECHOLEOUTERVV );
			push( @fiducOptions, MDITTEnums->Fiducials_CUSQUERE );

		}

	}

	my $topLayerFiducChb = Wx::ComboBox->new( $self, -1, $fiducOptions[0], &Wx::wxDefaultPosition, [ 10, 22 ], \@fiducOptions, &Wx::wxCB_READONLY );
	my $botLayerFiducChb = Wx::ComboBox->new( $self, -1, $fiducOptions[0], &Wx::wxDefaultPosition, [ 10, 22 ], \@fiducOptions, &Wx::wxCB_READONLY );

	#$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE LAYOUT

	$szCol1->Add( $exportChb,  1, &Wx::wxEXPAND | &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 2 );
	$szCol2->Add( $layerColor, 1, &Wx::wxEXPAND | &Wx::wxALL,                                1 );
	$szCol2->Add( 20,          0, 0 );

	$szCol3Row1->Add( $topLayerTxt,      0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3Row1->Add( $topLayerRotChb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3Row1->Add( $topLayerFiducChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3Row2->Add( $botLayerTxt,      0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3Row2->Add( $botLayerRotChb,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3Row2->Add( $botLayerFiducChb, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szCol3->Add( $szCol3Row1, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szCol3->Add( $szCol3Row2, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szMain->Add( $szCol1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szCol2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szCol3, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES
	$self->{"exportChb"}        = $exportChb;
	$self->{"topLayerRotChb"}   = $topLayerRotChb;
	$self->{"botLayerRotChb"}   = $botLayerRotChb;
	$self->{"topLayerFiducChb"} = $topLayerFiducChb;
	$self->{"botLayerFiducChb"} = $botLayerFiducChb;

}

# ==============================================
# PUBLIC FUNCTION
# ==============================================

sub SetIsSelected {
	my $self   = shift;
	my $select = shift;

	if ($select) {

		$self->{"exportChb"}->SetValue(1);
	}
	else {

		$self->{"exportChb"}->SetValue(0);
	}

}

sub GetIsSelected {
	my $self   = shift;
	my $select = shift;

	if ( defined $self->{"exportChb"}->GetValue() && $self->{"exportChb"}->GetValue() == 1 ) {

		return 1;
	}
	else {

		return 0;
	}
}

sub SetTopLayerSettings {
	my $self = shift;
	my $sett = shift;

	$self->__SetLayerSettings( $sett, $self->{"topLayerRotChb"}, $self->{"topLayerFiducChb"} );
}

sub GetTopLayerSettings {
	my $self = shift;

	my $sett = $self->__GetLayerSettings( $self->{"topLayerRotChb"}, $self->{"topLayerFiducChb"} );

	return $sett;
}

sub SetBotLayerSettings {
	my $self = shift;
	my $sett = shift;

	$self->__SetLayerSettings( $sett, $self->{"botLayerRotChb"}, $self->{"botLayerFiducChb"} );
}

sub GetBotLayerSettings {
	my $self = shift;

	my $sett = $self->__GetLayerSettings( $self->{"botLayerRotChb"}, $self->{"botLayerFiducChb"} );

	return $sett;
}

sub __SetLayerSettings {
	my $self         = shift;
	my $sett         = shift;
	my $rotControl   = shift;
	my $fiducControl = shift;

	if ( $sett->{"rotationCCW"} == 0 ) {
		$rotControl->SetValue("V");
	}
	elsif ( $sett->{"rotationCCW"} == 90 ) {
		$rotControl->SetValue("H");
	}
	else {

		die "Rotation: " . $sett->{"rotationCCW"} . "is not alowed";
	}

	$fiducControl->SetValue( $sett->{"fiducialType"} );
}

sub __GetLayerSettings {
	my $self         = shift;
	my $rotControl   = shift;
	my $fiducControl = shift;

	my %sett = ( "rotationCCW" => undef, "fiducialType" => undef );

	if ( $rotControl->GetValue() eq "V" ) {

		$sett{"rotationCCW"} = 0;

	}
	elsif ( $rotControl->GetValue() eq "H" ) {

		$sett{"rotationCCW"} = 90;
	}

	$sett{"fiducialType"} = $fiducControl->GetValue();

	return \%sett;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
