
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

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"}   = shift;
 
 	$self->{"outputPath"} = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".jpeg";
 
	return $self;
}

sub Create {
	my $self = shift;
	
	
	my $stackup = StackupPdf->new($self->{"jobId"});
	my $resultCreate = $stackup->Create();
	
	unless($resultCreate){
		return 0;
	}
	
	my $path = $stackup->GetStackupPath();
	my $result = 1;
 
	$result = $self->__ConvertToImage($path);
	
	unlink($path);

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
	push( @cmd, "-rotate 270 -crop 1470x2000+150+500 -trim" );
	push( @cmd, "-bordercolor white -border 20x20" );
	push( @cmd, "-gravity center -background white -extent 1600x1600" );
 	push( @cmd, $self->{"outputPath"} );

	my $cmdStr = join( " ", @cmd );

	my $result = system($cmdStr);
	
	
	return $result;
	
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

