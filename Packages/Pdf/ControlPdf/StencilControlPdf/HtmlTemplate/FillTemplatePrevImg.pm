
#-------------------------------------------------------------------------------------------#
# Description: This class fill special template class
# Template class than contain all needed data, which are pasted to final PDF
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::PcbControlPdf::HtmlTemplate::FillTemplatePrevImg;

#3th party library
use utf8;

use strict;
use warnings;

use POSIX qw(strftime);

#local library
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

# Set keys regarding html temlate content
sub FillKeysData {
	my $self        = shift;
	my $template    = shift;
	my $previewPath = shift;
	my $infoToPdf   = shift;    # if put info about operator to pdf

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %inf = StnclHelper->GetStencilInfo( $self->{"jobId"} );

	$template->SetKey( "ScriptsRoot", GeneralHelper->Root() );

	# =================== Table views ============================

	my $legendProfEn = "";
	my $legendProfCz = "";

	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB ) {
		$legendProfEn =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\profile.png" /> pcb profile';
		$legendProfCz =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\profile.png" /> profil dps';
	}

	$template->SetKey( "LegendProfile", $legendProfEn, $legendProfCz );

	my $legendDataEn = "";
	my $legendDataCz = "";

	if ( $self->{"params"}->GetDataSource()->{"sourceType"} eq StnclEnums->StencilSource_JOB ) {
		$legendDataEn =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\data.png" /> stencil data limits';
		$legendDataCz =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\data.png" /> ohraničení plošek šablony';
	}

	$template->SetKey( "LegendData", $legendDataEn, $legendDataCz );

	my $fiducInf    = $self->{"params"}->GetFiducial();
	my $fiducTextEn = "";
	my $fiducTextCz = "";

	my $legendFiducEn = '';
	my $legendFiducCz = '';

	if ( $fiducInf->{"halfFiducials"} ) {

		my $readable = $fiducInf->{"fiducSide"} eq "readable" ? 1 : 0;

		if ( $inf{"tech"} eq StnclEnums->Technology_LASER ) {
			$fiducTextEn = "Positions of half-lasered fiducials (from " . ( $readable ? "readable" : "nonreadable" ) . " side)";
			$fiducTextCz = "Pozice fiduciálních značek vypálených do poloviny (z " . ( $readable ? "čitelné" : "nečitelné" ) . " strany)";
		}
		elsif ( $inf{"tech"} eq StnclEnums->Technology_ETCH ) {
			$fiducTextEn = "Positions of half-lasered fiducials (from " . ( $readable ? "readable" : "nonreadable" ) . " side)";
			$fiducTextCz = "Pozice fiduciálních značek vypálených do poloviny (z " . ( $readable ? "čitelné" : "nečitelné" ) . " strany)";
		}

		$legendFiducEn =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\fiduc.png" /> '
		  . $fiducTextEn;
		$legendFiducCz =
		    '<img  height="15" src="'
		  . GeneralHelper->Root()
		  . '\Packages\Pdf\ControlPdf\StencilControlPdf\HtmlTemplate\Img\fiduc.png" /> '
		  . $fiducTextCz;

	}

	$template->SetKey( "LegendFiduc", $legendFiducEn,                            $legendFiducCz );
	$template->SetKey( "TopView",     "View from readable side (squeegee side)", "Pohled z čitelné strany (strana stěrky)" );
	$template->SetKey( "TopViewImg",  $previewPath );

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
