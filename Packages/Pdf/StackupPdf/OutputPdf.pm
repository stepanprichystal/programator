
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
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
my $starX  = 30;
my $startY = 400;

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
my $page    = undef;
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

	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";

	return $self;
}

sub Output {
	my $self      = shift;
	my $stackupName = shift;
	my $stackup     = shift;

	$self->_CreatePdfStackup($stackupName, $stackup);

	return 1;
}


sub GetOutput{
	my $self      = shift;
	
	return $self->{"outputPath"};
}

#create stackup in PDF similar to MultiCall stackup
sub _CreatePdfStackup {
	my $self        = shift;
	my $stackupName = shift;
	my $stackup     = shift;

	my $lCount   =  $stackup->GetCuLayerCnt();
	
	my $pcbThick = $stackup->GetFinalThick();

	my $pcbPath = JobHelper->GetJobArchive($self->{"jobId"});

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
	$page = $a4->new_page();
	$f1 = $pdf->font(
					  'Subtype'  => 'Type1',
					  'Encoding' => 'WinAnsiEncoding',
					  'BaseFont' => 'Arial'
	);

	my $blankGap = 2;                                                 #2mm

	#draw stackup image
	$self->_DrawGrayBox( $starX, \$startY );

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
					$startY -= $blankGap;
				}
			}
			$self->_DrawCopper( $starX, \$startY, $layer );

		}
		elsif ( $layer->GetType() eq Enums->MaterialType_PREPREG ) {

			my @childPrepregs = $layer->GetAllPrepregs();

			foreach my $p (@childPrepregs) {

				$startY -= $blankGap;

				$self->_DrawPrepreg( $starX, \$startY, $p );
			}

		}
		elsif ( $layer->GetType() eq Enums->MaterialType_CORE ) {

			#add vertical gap
			if ($layerPrev) {
				unless ( $layerPrev->GetType() eq Enums->MaterialType_COPPER ) {
					$startY -= $blankGap;
				}
			}

			$self->_DrawCore( $starX, \$startY, $layer );

		}
	}
	$startY -= $blankGap;
	$self->_DrawGrayBox( $starX, \$startY );

	#draw stackup type
	$self->_DrawStackupType($stackup);

	#draw lines

	$page->set_width(2);
	$page->line( $col7, $row1, $col7,  $row7 );
	$page->line( $col8, $row3, $col12, $row3 );
	$page->line( $col8, $row5, $col12, $row5 );

	#sraw texts

	$page->string( $f1, 22, $col9, $row2, $stackupName );

	$page->string( $f1, 18, $col9,  $row4, "Number of Cu layers" );
	$page->string( $f1, 18, $col11, $row4, $lCount );
	$page->string( $f1, 18, $col9,  $row6, "Actual thickness" );
	$page->string( $f1, 18, $col11, $row6, sprintf( "%4.3f", ( $pcbThick / 1000 ) ) );

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
	$page->setrgbcolor( 0, 0, 0 );
	$page->string( $f1, $size, $col, $row, $text );
}

#tl 9x240
sub _DrawGrayBox {
	my $self       = shift;
	my $startX     = shift;
	my $actualYref = shift;

	my $lHeight = 9;
	${$actualYref} -= $lHeight;

	$page->setrgbcolor( 146 / 255, 146 / 255, 146 / 255 );
	$page->rectangle( $col1, ${$actualYref}, 243, $lHeight );
	$page->fill();
	$page->stroke();

}

#tl 12x300
sub _DrawCopper {
	my $self       = shift;
	my $startX     = shift;
	my $actualYref = shift;
	my $layer      = shift;

	my $lHeight = 10;
	${$actualYref} -= $lHeight;

	$page->setrgbcolor( 156 / 255, 1 / 255, 1 / 255 );

	if ( $layer->GetUssage() * 100 < 100 ) {
		$page->rectangle( $col2,       ${$actualYref}, 50, $lHeight );
		$page->rectangle( $col2 + 52,  ${$actualYref}, 50, $lHeight );
		$page->rectangle( $col2 + 104, ${$actualYref}, 30, $lHeight );
		$page->rectangle( $col2 + 136, ${$actualYref}, 71, $lHeight );
	}
	else {
		$page->rectangle( $col2, ${$actualYref}, 207, $lHeight );
	}

	$page->fill();

	#draw type  and usage of Cu
	my $usage = ( $layer->GetUssage() * 100 ) . " %";
	$self->_DrawText( $col4, ${$actualYref}, $txtSize, $layer->GetText() . "  " . $usage );

}

#tl 9
sub _DrawCore {
	my $self       = shift;
	my $startX     = shift;
	my $actualYref = shift;
	my $layer      = shift;

	my $lHeight = 14;
	${$actualYref} -= $lHeight;

	$page->setrgbcolor( 159 / 255, 149 / 255, 19 / 255 );
	$page->rectangle( $col2, ${$actualYref}, 207, $lHeight );
	$page->fill();

	$self->_DrawText( $col0, ${$actualYref}, $txtSize, $layer->GetThick() . " um" );    #draw thicks on left
	$self->_DrawText( $col5, ${$actualYref}, $txtSize, $layer->GetText() );             #draw type of material
	$self->_DrawText( $col6, ${$actualYref}, $txtSize, $layer->GetTextType() );         #draw type of  material quality
}

sub _DrawPrepreg {
	my $self       = shift;
	my $startX     = shift;
	my $actualYref = shift;
	my $layer      = shift;

	my $lHeight = 10;
	${$actualYref} -= $lHeight;

	$page->setrgbcolor( 71 / 255, 143 / 255, 71 / 255 );
	$page->rectangle( $col3, ${$actualYref}, 125, $lHeight );
	$page->fill();

	$self->_DrawText( $col0, ${$actualYref}, $txtSize, sprintf( "%4.0f", $layer->GetThick() ) . " um" );    #draw thicks on left
	$self->_DrawText( $col5, ${$actualYref}, $txtSize, $layer->GetText() );                                 #draw type of material
	$self->_DrawText( $col6, ${$actualYref}, $txtSize, $layer->GetTextType() );                             #draw type of  material quality
}

sub _DrawStackupType {
	my $self    = shift;
	my $stackup = shift;

	#$page->setrgbcolor( 71 / 255, 143 / 255, 71 / 255 );
	#$page->rectangle( $col3, ${$actualYref}, 125, $lHeight );
	#$page->fill();
	$page->string( $f1, 20, 100, 480, $stackup->GetStackupType() );

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

