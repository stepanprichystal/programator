
package Programs::Panelisation::PnlWizard::EnumsStyle;

use aliased 'Programs::Panelisation::PnlWizard::Enums';

 
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
