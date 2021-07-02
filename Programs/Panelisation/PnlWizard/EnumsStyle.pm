
package Programs::Panelisation::PnlWizard::EnumsStyle;

use Wx;

use aliased 'Programs::Panelisation::PnlWizard::Enums';

use constant {
	BACKGCLR_LIGHTGRAY => Wx::Colour->new( 233, 233, 233 ),
	BACKGCLR_MEDIUMGRAY => Wx::Colour->new( 200, 200, 200 ),
	BACKGCLR_HEADERBLUE => Wx::Colour->new( 112, 146, 190 ),
	BACKGCLR_LEFTPNLBLUE => Wx::Colour->new( 51, 52, 74 ),
	
	TXTCLR_LEFTPNL =>  Wx::Colour->new( 187, 187, 196 ),

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
	elsif ( $part eq Enums->Part_PNLSCHEME ) {
		$tit = "Scheme";
	}

	return $tit;
}

1;
