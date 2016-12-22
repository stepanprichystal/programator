
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::ControlPdf::StackupPreview::StackupPreview;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Pdf::StackupPdf::StackupPdf';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamJob';
#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
 
 	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";
 	
 	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
 
	return $self;
}

sub Create {
	my $self = shift;
	my $message = shift;
	
	my $stackup = StackupPdf->new($self->{"jobId"});
	my $resultCreate = $stackup->Create();
	
	if($self->{"layerCnt"} <= 2){
		return 1;
	}
	elsif(!$resultCreate && $self->{"layerCnt"} > 2){
		$$message .= "Error when create stackup preview. Loading stackup failed.";
		return 0;
	} 
	
	my $path = $stackup->GetStackupPath();
	my $result = 1;
 
	$result = $self->__ConvertToImage($path);
	
	unless($result){
		$$message .= "Error when convverting stackup in PDF to image.";
	}
	
	unlink($path);
	
	FileHelper->DeleteTempFiles();

	return $result;
}

sub GetOutput {
	my $self = shift;

	return $self->{"outputPath"};
}

sub __ConvertToImage{
	my $self = shift;
	my $pdfStackup = shift; # path
	
	 

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "im\\convert.exe" );
 
	push( @cmd, "-density 300 -background white -flatten" );
	push( @cmd, $pdfStackup );
	push( @cmd, "-rotate 270 -crop 1500x2000+120+500 -trim" );
	push( @cmd, "-bordercolor white -border 20x20" );
	push( @cmd, "-gravity center -background white -extent 1600x1600" );
 	push( @cmd, $self->{"outputPath"} );

	my $cmdStr = join( " ", @cmd );

	my $result = system($cmdStr);
	
	if($result == 0){
		return 1;
	}else{
		return 0;
	}
 
	
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

