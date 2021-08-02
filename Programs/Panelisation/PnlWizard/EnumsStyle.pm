
package Programs::Panelisation::PnlWizard::EnumsStyle;

use Wx;

use aliased 'Programs::Panelisation::PnlWizard::Enums';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

use constant {
	BACKGCLR_LIGHTGRAY   => Wx::Colour->new( 233, 233, 233 ),
	BACKGCLR_MEDIUMGRAY  => Wx::Colour->new( 200, 200, 200 ),
	BACKGCLR_HEADERBLUE  => Wx::Colour->new( 112, 146, 190 ),
	BACKGCLR_LEFTPNLBLUE => Wx::Colour->new( 51,  52,  74 ),

	TXTCLR_LEFTPNL => Wx::Colour->new( 187, 187, 196 ),

};

# Return part title
sub GetPartTitle {
	my $self = shift;
	my $part = shift;

	my $tit = undef;

	if ( $part eq Enums->Part_PNLSIZE ) {
		$tit = "Dimension";
	}
	elsif ( $part eq Enums->Part_PNLSTEPS ) {
		$tit = "Steps";

	}
	elsif ( $part eq Enums->Part_PNLCPN ) {
		$tit = "Coupons";
	}
	elsif ( $part eq Enums->Part_PNLSCHEME ) {
		$tit = "Scheme";
	}

	return $tit;
}

sub GetCreatorTitle {
	my $self       = shift;
	my $creatorKey = shift;

	my $tit = undef;

	if ( $creatorKey eq PnlCreEnums->SizePnlCreator_USER ) {
		$tit = "User defined";
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_HEG ) {
		$tit = "HEG defined";

	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_MATRIX ) {
		$tit = "Grid of steps";
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSUSER ) {
		$tit = "User Panel class";
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_CLASSHEG ) {
		$tit = "HEG Panel class";
	}
	elsif ( $creatorKey eq PnlCreEnums->SizePnlCreator_PREVIEW ) {
		$tit = "Existing InCAM job";
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSUSER ) {
		$tit = "User Panel class";
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_CLASSHEG ) {
		$tit = "HEG Panel class";
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_MATRIX ) {
		$tit = "Grid of steps";
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_SET ) {
		$tit = "Customer set";
	}
	elsif ( $creatorKey eq PnlCreEnums->StepPnlCreator_PREVIEW ) {
		$tit = "Existing InCAM job";
	}
	elsif ( $creatorKey eq PnlCreEnums->CpnPnlCreator_SEMIAUTO ) {
		$tit = "Automatic placement";
	}
	elsif ( $creatorKey eq PnlCreEnums->SchemePnlCreator_LIBRARY ) {
		$tit = "From library";
	}

	return $tit;
}

1;
