
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
	my $pdfStackup = shift; # path
 
	# get info about pcb
	
	unless(-e $pdfStackup){
		return 0;
	}

	my $result = 1;
	
	
	
	$result = $self->__ConvertToImage($pdfStackup);

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
	push( @cmd, "-rotate 270 - crop 1800x2500+200+500 -trim" );
	push( @cmd, "-bordercolor white -border 40x40" );
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

