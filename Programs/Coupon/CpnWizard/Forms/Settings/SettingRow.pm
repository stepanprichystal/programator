#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::Settings::SettingRow;

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';

#tested form
use aliased 'Programs::Coupon::CpnWizard::Forms::Settings::HelpWindow';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class        = shift;
	my $parent       = shift;
	my $parentFrame  = shift;
	my $settingsKey  = shift;
	my $labelText    = shift;
	my $helpText     = shift;
	my $unitText     = shift;
	my $controls     = shift;
	my $labelWidth   = shift // 200;

	my $self = {};
	bless($self);

	# Properties
	$self->{"parent"}      = $parent;
	$self->{"parentFrame"} = $parentFrame;
	$self->{"settingsKey"} = $settingsKey;
	$self->{"labelText"}   = $labelText;
	$self->{"helpText"}    = $helpText;
	$self->{"unitText"}    = $unitText;
	$self->{"controls"}    = $controls;
	$self->{"labelWidth"}  = $labelWidth;

	$self->__SetLayout();

	return $self;
}

sub GetRowLayout {
	my $self = shift;

	return $self->{"szMain"};
}

sub __SetLayout {
	my $self = shift;

	my $key = $self->{"settingsKey"};

	my $settLabel       = $self->{"labelText"};
	my $settHelp        = $self->{"helpText"};
	my $settUnits       = $self->{"unitText"};
	my $settHelpImgPath = Helper->GetResourcePath() . "Help\\$key.bmp";

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $labelTxt = Wx::StaticText->new( $self->{"parent"}, -1, $settLabel, &Wx::wxDefaultPosition, [ $self->{"labelWidth"}, 25 ] );

	my $unitsTxt = Wx::StaticText->new( $self->{"parent"}, -1, $settUnits, &Wx::wxDefaultPosition, [ 40, 25 ] );

	my $helpPnl;
	if ( $settHelp ne "" || -e $settHelpImgPath ) {

		my $p = GeneralHelper->Root() . "\\Resources\\Images\\Question20x20.bmp";

		my $bitmap = Wx::Bitmap->new( $p, &Wx::wxBITMAP_TYPE_BMP );
		$helpPnl = Wx::StaticBitmap->new( $self->{"parent"}, -1, $bitmap );

		Wx::Event::EVT_LEFT_DOWN( $helpPnl, sub { $self->__ShowHelp($key) } );
	}
	else {
		$helpPnl = Wx::Panel->new( $self->{"parent"}, -1 );
	}

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $labelTxt,           0 );
	$szMain->Add( $self->{"controls"}, 0 );
	$szMain->Add( $unitsTxt,           0 );
	$szMain->Add( $helpPnl,            0 );
	$szMain->Add( 1, 1, 1 );

	$self->{"szMain"} = $szMain;
}

sub __ShowHelp {
	my $self = shift;

	my $key = $self->{"settingsKey"};

	my $settLabel       = $self->{"labelText"};
	my $settHelp        = $self->{"helpText"};
	my $settUnits       = $self->{"unitText"};
	my $settHelpImgPath = Helper->GetResourcePath() . "Help\\$key.png";

	my $w = HelpWindow->new( $self->{"parentFrame"}, $settLabel, $settHelp, $settHelpImgPath );
	$w->ShowModal();
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm";
	#
	#	my @dimension = ( 500, 800 );
	#
	my $test = GeneratorFrm->new(-1);

}

1;

