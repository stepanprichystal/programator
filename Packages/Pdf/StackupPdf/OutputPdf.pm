
#-------------------------------------------------------------------------------------------#
# Description: Responsible for phzsic creation of pdf file with stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package  Packages::Pdf::StackupPdf::OutputPdf;

#3th party library
use strict;
use warnings;
use PDF::Create;
use English;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums';

#-------------------------------------------------------------------------------------------#
#   GLOBAL variables
#-------------------------------------------------------------------------------------------#

#stackup pdf has dimension 842 x 595 (A4 format rotate about 90 degree)
#start point for drawing stackup image
my $starX = 30;

#coordinates for drawing stackup
my $col0  = $starX;
my $col1  = $starX + 20;
my $col2  = $starX + 37;
my $col3  = $starX + 79;
my $col4  = $starX + 250;
my $col5  = $starX + 260;
my $col6  = $starX + 380;
my $col7  = $starX + 460;
my $col8  = $starX + 485;
my $col9  = $starX + 490;
my $col10 = $starX + 532;
my $col11 = $starX + 700;
my $col12 = $starX + 770;

my $row1 = 515;
my $row2 = 475;
my $row3 = 450;
my $row4 = 380;
my $row5 = 300;
my $row6 = 235;
my $row7 = 100;

#variables for creating pdf

my $f1      = undef;
my $txtSize = 9;

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"pdfStep"} = shift;

	$self->{"startY"}     = undef;                                                                # this y coordinate, where stackup image starts from
	$self->{"page"}       = undef;                                                                # xml page
	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Output {
	my $self        = shift;
	my $stackupName = shift;
	my $stackup     = shift;

	$self->{"startY"} = 400;       # start stackup image from coordinate 400px

	$self->_CreatePdfStackup( $stackupName, $stackup );

	return 1;
}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

#create stackup in PDF similar to MultiCall stackup
sub _CreatePdfStackup {
	my $self        = shift;
	my $stackupName = shift;
	my $stackup     = shift;

	my $lCount = $stackup->GetCuLayerCnt();

	my $pcbThick = $stackup->GetFinalThick();

	my $pcbPath = JobHelper->GetJobArchive( $self->{"jobId"} );

	#Enums::Paths->PCBARCHIV . substr( $pcbId, 0, 3 ) . "/" . $pcbId . "/";

	# initialize PDF
	my $pdf = PDF::Create->new(
								'filename'     => $self->{"outputPath"},
								'Author'       => 'John Doe',
								'Title'        => 'Sample PDF',
								'CreationDate' => [localtime],
	);

	# add a A4 sized page
	my @d = [ 0, 0, 842, 595 ];

	#my $a4 = $pdf->new_page('MediaBox' => @d);
	my $a4 = $pdf->new_page( 'MediaBox' => @d, 'Rotate' => '90' );    #UNCOMMENT FOR PAGE ROTATION
	$self->{"page"} = $a4->new_page();
	$f1 = $pdf->font(
					  'Subtype'  => 'Type1',
					  'Encoding' => 'WinAnsiEncoding',
					  'BaseFont' => 'Arial'
	);

	my $blankGap = 2;                                                 #2mm

	#draw stackup image
	$self->_DrawGrayBox($starX);

	my @stackupList = $stackup->GetAllLayers();
	my $layer;
	my $layerPrev;

	for ( my $i = 0 ; $i < scalar(@stackupList) ; $i++ ) {

		$layer = $stackupList[$i];

		if ( $i > 0 ) {
			$layerPrev = $stackupList[ $i - 1 ];
		}

		if ( $layer->GetType() eq Enums->MaterialType_COPPER ) {

			#add vertical gap
			if ($layerPrev) {
				unless ( $layerPrev->GetType() eq Enums->MaterialType_CORE ) {
					$self->{"startY"} -= $blankGap;
				}
			}
			$self->_DrawCopper( $starX, $layer );

		}
		elsif ( $layer->GetType() eq Enums->MaterialType_PREPREG ) {

			my @childPrepregs = $layer->GetAllPrepregs();

			foreach my $p (@childPrepregs) {

				$self->{"startY"} -= $blankGap;

				$self->_DrawPrepreg( $starX, $p );
			}

		}
		elsif ( $layer->GetType() eq Enums->MaterialType_CORE ) {

			#add vertical gap
			if ($layerPrev) {
				unless ( $layerPrev->GetType() eq Enums->MaterialType_COPPER ) {
					$self->{"startY"} -= $blankGap;
				}
			}

			$self->_DrawCore( $starX, $layer );

		}
	}
	$self->{"startY"} -= $blankGap;
	$self->_DrawGrayBox($starX);

	#draw stackup type
	$self->_DrawStackupType($stackup);

	#draw lines

	$self->{"page"}->set_width(2);
	$self->{"page"}->line( $col7, $row1, $col7,  $row7 );
	$self->{"page"}->line( $col8, $row3, $col12, $row3 );
	$self->{"page"}->line( $col8, $row5, $col12, $row5 );

	#sraw texts

	$self->{"page"}->string( $f1, 22, $col9, $row2, $stackupName );

	$self->{"page"}->string( $f1, 18, $col9,  $row4, "Number of Cu layers" );
	$self->{"page"}->string( $f1, 18, $col11, $row4, $lCount );
	$self->{"page"}->string( $f1, 18, $col9,  $row6, "Actual thickness" );
	$self->{"page"}->string( $f1, 18, $col11, $row6, sprintf( "%4.3f", ( $pcbThick / 1000 ) ) );

	$pdf->close;

	#copy pdf to folder "Zdroje"
	#FileHelper->Copy( $pcbPath . "pdf/" . $pcbId . "-cm.pdf", $pcbPath . "Zdroje/" . $pcbId . "-cm.pdf" );
}

#Draw text to pdf
sub _DrawText {
	my $self = shift;
	my $col  = shift;
	my $row  = shift;
	my $size = shift;
	my $text = shift;

	#print $col."/".$row."-".$size.$text;
	$self->{"page"}->setrgbcolor( 0, 0, 0 );
	$self->{"page"}->string( $f1, $size, $col, $row, $text );
}

#tl 9x240
sub _DrawGrayBox {
	my $self   = shift;
	my $startX = shift;

	my $lHeight = 9;
	$self->{"startY"} -= $lHeight;

	$self->{"page"}->setrgbcolor( 146 / 255, 146 / 255, 146 / 255 );
	$self->{"page"}->rectangle( $col1, $self->{"startY"}, 243, $lHeight );
	$self->{"page"}->fill();
	$self->{"page"}->stroke();

}

#tl 12x300
sub _DrawCopper {
	my $self   = shift;
	my $startX = shift;
	my $layer  = shift;

	my $lHeight = 10;
	$self->{"startY"} -= $lHeight;

	$self->{"page"}->setrgbcolor( 156 / 255, 1 / 255, 1 / 255 );

	if ( $layer->GetUssage() * 100 < 100 ) {
		$self->{"page"}->rectangle( $col2,       $self->{"startY"}, 50, $lHeight );
		$self->{"page"}->rectangle( $col2 + 52,  $self->{"startY"}, 50, $lHeight );
		$self->{"page"}->rectangle( $col2 + 104, $self->{"startY"}, 30, $lHeight );
		$self->{"page"}->rectangle( $col2 + 136, $self->{"startY"}, 71, $lHeight );
	}
	else {
		$self->{"page"}->rectangle( $col2, $self->{"startY"}, 207, $lHeight );
	}

	$self->{"page"}->fill();

	#draw type  and usage of Cu
	my $usage = ( $layer->GetUssage() * 100 ) . " %";
	$self->_DrawText( $col4, $self->{"startY"}, $txtSize, $layer->GetText() . "  " . $usage );

}

#tl 9
sub _DrawCore {
	my $self   = shift;
	my $startX = shift;
	my $layer  = shift;

	my $lHeight = 14;
	$self->{"startY"} -= $lHeight;

	$self->{"page"}->setrgbcolor( 159 / 255, 149 / 255, 19 / 255 );
	$self->{"page"}->rectangle( $col2, $self->{"startY"}, 207, $lHeight );
	$self->{"page"}->fill();

	$self->_DrawText( $col0, $self->{"startY"}, $txtSize, $layer->GetThick() . " µm" );    #draw thicks on left
	$self->_DrawText( $col5, $self->{"startY"}, $txtSize, $layer->GetText() );              #draw type of material
	$self->_DrawText( $col6, $self->{"startY"}, $txtSize, $layer->GetTextType() );          #draw type of  material quality
}

sub _DrawPrepreg {
	my $self   = shift;
	my $startX = shift;
	my $layer  = shift;

	my $lHeight = 10;
	$self->{"startY"} -= $lHeight;

	$self->{"page"}->setrgbcolor( 71 / 255, 143 / 255, 71 / 255 );
	$self->{"page"}->rectangle( $col3, $self->{"startY"}, 125, $lHeight );
	$self->{"page"}->fill();

	$self->_DrawText( $col0, $self->{"startY"}, $txtSize, sprintf( "%4.0f", $layer->GetThick() ) . " µm" );    #draw thicks on left
	$self->_DrawText( $col5, $self->{"startY"}, $txtSize, $layer->GetText() );                                  #draw type of material
	$self->_DrawText( $col6, $self->{"startY"}, $txtSize, $layer->GetTextType() );                              #draw type of  material quality
}

sub _DrawStackupType {
	my $self    = shift;
	my $stackup = shift;

	#$self->{"page"}->setrgbcolor( 71 / 255, 143 / 255, 71 / 255 );
	#$self->{"page"}->rectangle( $col3, $self->{"startY"}, 125, $lHeight );
	#$self->{"page"}->fill();
	$self->{"page"}->string( $f1, 20, 100, 480, $stackup->GetStackupType() );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

