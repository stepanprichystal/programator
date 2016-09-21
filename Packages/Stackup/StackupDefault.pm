#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro automaticke vytvoreni standardniho slozeni
#  pro dps 4vv, 6vv, 8vv  9um + 18um + 35um
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupDefault;

#loading of locale modules
use LoadLibrary;

#3th party library
use English;
use strict;
use warnings;
use XML::Simple;
use POSIX;
use PDF::Create;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Stackup::Enums';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Connectors::HeliosConnector::HegMethods';

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
#  Script methods
#-------------------------------------------------------------------------------------------#

#Create xml and pdf stackup and  automatically
sub CreateStackup {
	my $self         = shift;
	my $pcbId        = shift;
	my $lCount       = shift;
	my @innerCuUsage = @{ shift(@_) };
	my $outerCuThick = shift;
	my $pcbClass     = shift;

	my $messMngr = MessageMngr->new($pcbId);

	#test input parameters
	if ( $lCount < 4 ) {
		print STDERR "Number of Cu has to be larger then 4";
		return 0;
	}

	unless ($pcbId) {
		print STDERR "No pcb Id";
		return 0;
	}

	unless (@innerCuUsage) {
		print STDERR "No inner Cu ussage in param innerCuUsage";
		return 0;
	}

	if ( $outerCuThick < 18 ) {
		print STDERR "Error, outher thick is less then 18";
		return 0;
	}

	if ( $lCount != scalar(@innerCuUsage) + 2 ) {
		print STDERR "Number of layer is diffrent from number of item in array innerCuUsage + 2";
		return 0;
	}

	#we need identify, which type of stackup use. It depends on inner layers Cu ussage
	#see Resources/DefaultStackup/Navod.txt
	my $stackType = "type1";

	if ( $lCount == 6 && $innerCuUsage[1] + $innerCuUsage[2] < 30 ) {
		$stackType = "type2";

	}
	elsif (
			$lCount == 8
			&& (    ( $innerCuUsage[1] + $innerCuUsage[2] < 60 )
				 || ( $innerCuUsage[3] + $innerCuUsage[4] < 60 ) )
	  )
	{
		$stackType = "type2";
	}

	my $defaultName = $lCount . "vv_" . $stackType . ".xml";

	my @mess = ("Který typ standardního stackupu chceš vygenerovat? (IS400 pouze malý pøíøez)");
	my @btn = ( "IS400", "FR4" );

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess, \@btn );

	my $res = $messMngr->Result();

	my $path;

	if ($res) {

		$path = GeneralHelper->Root() . "\\Resources\\DefaultStackups\\";
	}
	else {

		$path = GeneralHelper->Root() . "\\Resources\\DefaultStackups_is400\\";
	}

 
	my $stcFile = $path.$defaultName;;
 
	my $xml = $self->_LoadStandardStackup($stcFile);

	#if pcb is in 8 class, set outer Cu 9Âµm
	if ( $pcbClass >= 8 && $outerCuThick <= 18 ) {
		$outerCuThick = 9;
	}

	#create new xml stackup file
	$self->_SetOuterCu( \$xml, $outerCuThick, $pcbClass );
	$self->_SetCuUsage( \$xml, \@innerCuUsage );
	$self->_CreateNewStackup( \$xml, $pcbId, $pcbId );

	#get final thick of pcb and get info about stackup layers
	my $stackup  = Stackup->new($pcbId);
	my $pcbThick = $stackup->GetFinalThick();

	#generate name of stackup file eg.: d99991_4vv_1,578_Euro.xml
	my $stackupName = $self->_GenerateNameOfStackup( $pcbId, $lCount, $pcbThick );

	$self->_CompleteNewStackup( $pcbId, $pcbThick, $stackupName );

	$self->_CreatePdfStackup( $pcbId, $lCount, $stackupName, $pcbThick, $stackup );

	@mess = ( "Standardni stackup :" . $stackupName . ".xml byl automaticky vygenerovan" );

	$messMngr->Show( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

	#Tidy up temp dir
	FileHelper->DeleteTempFiles();

	return 1;

}

#Load xml stackup for pcb
sub _LoadStandardStackup {
	my $self    = shift;
	my $stcFile = shift;

	#load standard stackup by LayerCount
	my $fStackupXml = undef;

	#check validation of pcb's stackup xml file
	if ( FileHelper->IsXMLValid($stcFile) ) {

		my $fStackupXml = FileHelper->Open($stcFile);
	}
	else {

	 

		my $fname = FileHelper->ChangeEncoding( $stcFile, "cp1252", "utf8" );

		 
		$fStackupXml = FileHelper->Open( EnumsPaths->Client_INCAMTMPOTHER . $fname );
	}

	my @thickList = ();

	my $xml = XMLin(
					 $fStackupXml,
					 ForceArray => undef,
					 KeyAttr    => undef,
					 KeepRoot   => 1,
	);

	return $xml;
}

#set thick of Cu to stackup
sub _SetOuterCu {
	my $self         = shift;
	my $xml          = ${ shift(@_) };
	my $outerCuThick = shift;
	my $pcbClass     = shift;

	my $idOfCu   = $self->_GetCuIdByThick($outerCuThick);
	my @elements = @{ $xml->{ml}->{element} };

	if (    $elements[0]->{type} =~ /Enums->MaterialType_COPPER/i
		 && $elements[ scalar(@elements) - 1 ]->{type} =~ /Enums->MaterialType_COPPER/i )
	{
		@{ $xml->{ml}->{element} }[0]->{id} = $idOfCu;
		@{ $xml->{ml}->{element} }[ scalar(@elements) - 1 ]->{id} = $idOfCu;
	}

}

#Return id of Cu material from ml.xml
sub _GetCuIdByThick {
	my $self  = shift;
	my $thick = shift;

	#read id from multicall.
	#temporary solution

	if ( $thick == 9 ) {
		return 2;
	}
	elsif ( $thick == 18 ) {
		return 4;
	}
	elsif ( $thick == 35 ) {
		return 5;
	}
}

#Set ussage of inner Cu layers to stackup
sub _SetCuUsage {
	my $self         = shift;
	my $xml          = ${ shift(@_) };
	my @innerCuUsage = @{ shift(@_) };

	#add TOP and BOTTOM usage 100%
	@innerCuUsage = ( 100, @innerCuUsage, 100 );

	my @elements = @{ $xml->{ml}->{element} };
	my $cuPos    = 0;

	for ( my $i = 0 ; $i < scalar(@elements) ; $i++ ) {

		if ( $elements[$i]->{type} =~ /Enums->MaterialType_COPPER/i ) {
			@{ $xml->{ml}->{element} }[$i]->{p} = $innerCuUsage[$cuPos];
			$cuPos++;
		}
	}
}

#Create and save new xml stackup, without pcb thickness and correct file name yet
sub _CreateNewStackup {
	my $self        = shift;
	my $xml         = ${ shift(@_) };
	my $pcbId       = shift;
	my $stackupName = shift;

	$xml->{"ml"}{"soll"} = 0;
	my $xmlString = XMLout( $xml->{ml}, RootName => "ml" );

	FileHelper->WriteString( EnumsPaths->Jobs_STACKUPS . $stackupName . "\.xml", $xmlString );
}

#Complete created stacup with right file name and thick of pcb
sub _CompleteNewStackup {
	my $self        = shift;
	my $pcbId       = shift;
	my $pcbThick    = shift;
	my $stackupName = shift;

	$pcbThick = sprintf( "%4.3f", ( $pcbThick / 1000 ) );
	$pcbThick =~ s/\./\,/g;

	my $newXml = $self->_LoadStandardStackup( EnumsPaths->Jobs_STACKUPS . $pcbId . ".xml" );
	$newXml->{"ml"}{"soll"} = $pcbThick;
	my $xmlString = XMLout( $newXml->{ml}, RootName => "ml" );

	#delete all files beginning with actual pcb id
	opendir( DIR, EnumsPaths->Jobs_STACKUPS );
	my @stackups = grep( m/$pcbId/i, readdir(DIR) );
	map { FileHelper->DeleteFile( EnumsPaths->Jobs_STACKUPS . $_ ) } @stackups;
	closedir(DIR);

	FileHelper->WriteString( EnumsPaths->Jobs_STACKUPS . $stackupName . "\.xml", $xmlString );

}

#create name of new stackup xml file;
sub _GenerateNameOfStackup {
	my $self     = shift;
	my $pcbId    = shift;
	my $lCount   = shift;
	my $pcbThick = shift;

	$pcbThick = sprintf( "%4.3f", ( $pcbThick / 1000 ) );
	$pcbThick =~ s/\./\,/g;

	my %customerInfo = HegMethods->GetCustomerInfo($pcbId);

	my $customer = $customerInfo{"customer"};

	if ($customer) {
		$customer =~ s/\s//g;
		$customer = substr( $customer, 0, 8 );
	}
	else {
		$customer = "";
	}

	if ( $customer =~ /safiral/i )    #exception for safiral
	{
		$customer = "";
	}

	return $pcbId . "_" . $lCount . "vv" . "_" . $pcbThick . "_" . $customer;
}

#create stackup in PDF similar to MultiCall stackup
sub _CreatePdfStackup {
	my $self        = shift;
	my $pcbId       = shift;
	my $lCount      = shift;
	my $stackupName = shift;
	my $pcbThick    = shift;
	my $stackup     = shift;

	my $pcbPath = JobHelper->GetJobArchive($pcbId);

	#Enums::Paths->PCBARCHIV . substr( $pcbId, 0, 3 ) . "/" . $pcbId . "/";

	# initialize PDF
	my $pdf = PDF::Create->new(
								'filename'     => $pcbPath . "pdf/" . $pcbId . "-cm.pdf",
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
		$layerPrev;

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

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;

if ( $filename =~ /DEBUG_FILE.pl/ ) {
	my $pcbId        = "d99991";
	my $layerCnt     = 8;
	my @innerCuUsage = ( 50, 3, 15, 50, 15, 44 );
	my $outerCuThick = 18;
	my $pcbClass     = 9;

	use aliased 'Packages::Stackup::StackupDefault';

	StackupDefault->CreateStackup( $pcbId, $layerCnt, \@innerCuUsage, $outerCuThick, $pcbClass );
}

1;

