
#-------------------------------------------------------------------------------------------#
# Description: TifFile - interface for signal layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::Template2Pdf::Template2Pdf;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"lang"}        = shift;
	$self->{"outFilePath"} = shift;
	return $self;
}

sub Convert {
	my $self         = shift;
	my $htmlTemplate = shift;
	my $keyData      = shift;
	my $outFile      = shift;

 
	unless ( defined $outFile ) {
		$outFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID().".pdf";
	}

	$self->{"outFilePath"} = $outFile;

	my $result = 1;

	#load template
	my $templ = FileHelper->ReadAsString($htmlTemplate);

	# fill with coorect data
	$templ = $self->__FillTemplate( $templ, $keyData );
	$result = $self->__FinalConvert( $templ, $htmlTemplate, $outFile );

	return $result;
}

sub GetOutFile {
	my $self = shift;

	return $self->{"outFilePath"};
}

sub __FillTemplate {
	my $self     = shift;
	my $template = shift;
	my $keyData  = shift;
	# substitute keys in template

	my %keysData = $keyData->GetKeyData();

	foreach my $k ( keys %keysData ) {

		my $kItem = $keysData{$k};
		my $val   = $kItem->GetText( $self->{"lang"} );

		$template =~ s/([>"\\])$k([<"\\])/$1$val$2/gi; # means replace all keys which are between characters ><, "" or \
	}

	# remove rest of not substitued keys
	$template =~ s/^key_[\w\d]+//ig;

	return $template;
}

sub __FinalConvert {
	my $self         = shift;
	my $templData     = shift;
	my $templPathOri = shift;

	my $result = 1;

	my $cssPath = $templPathOri;
	$cssPath =~ s/html/css/;
	
	my $templPathFinal = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
	my $f;
	if(open($f, ">", $templPathFinal)){
		
		print $f $templData;
		close($f);
	}
	

	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "pythonLib\\xhtml2pdf" );
	push( @cmd, "--css=$cssPath" );
	push( @cmd, "-w" );
	push( @cmd, "--encoding utf8" );
	push( @cmd, $templPathFinal );
	push( @cmd, $self->{"outFilePath"} );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);
	 
	if ( $systeMres > 0 ) {
		$result = 0;
	}
	
	
	# delete temp file
	if(-e $templPathFinal){
		unlink $templPathFinal;
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

