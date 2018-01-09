
#-------------------------------------------------------------------------------------------#
# Description: Module allow fill own html template with prepared keys
# Process of conversion:
# 1) Fill special template class by keys and values
# 2) Substitue keys in html template by values
# Other function - convert prepared html template to pdf
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Other::HtmlTemplate::HtmlTemplate;

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

	$self->{"lang"} = shift;

	$self->{"outFilePath"} = undef;
	return $self;
}

# create prepared html file filled by key values
sub ProcessTemplate {
	my $self          = shift;
	my $htmlTemplPath = shift;
	my $keyData       = shift;
	my $outFile       = shift;

	unless ( defined $outFile ) {
		$outFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".html";
	}

	my $result = 1;

	$self->__ProcessTemplate( $htmlTemplPath, $keyData, $outFile );
	
	$self->{"outFilePath"} = $outFile;

	return $result;

}

# Create pdf file
sub ProcessTemplatePdf {
	my $self          = shift;
	my $htmlTemplPath = shift;
	my $keyData       = shift;
	my $outFile       = shift;

	my $result = 1;

	unless ( defined $outFile ) {
		$outFile = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".pdf";
	}

	# create html template
	my $htmlOutFile =  EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID() . ".html";
	$self->__ProcessTemplate( $htmlTemplPath, $keyData, $htmlOutFile );

	# convert template to pdf

	$result = $self->__FinalConvert( $htmlOutFile, $htmlTemplPath, $outFile );

	unlink($htmlOutFile);
	
	$self->{"outFilePath"} = $outFile;

	return $result;
}


sub GetOutFile {
	my $self = shift;

	return $self->{"outFilePath"};
}

sub __ProcessTemplate {
	my $self          = shift;
	my $htmlTemplPath = shift;
	my $keyData       = shift;
	my $outFile       = shift;

	#load template
	my $templ = FileHelper->ReadAsString($htmlTemplPath);

	# fill with coorect data
	my $templData = $self->__FillTemplate( $templ, $keyData );

	# store to file
	my $f;
	if ( open( $f, ">", $outFile ) ) {

		print $f $templData;
		close($f);
	}

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

		$template =~ s/([>"\\])$k([<"\\])/$1$val$2/gi;    # means replace all keys which are between characters ><, "" or \
	}

	# remove rest of not substitued keys
	$template =~ s/^key_[\w\d]+//ig;

	return $template;
}

sub __FinalConvert {
	my $self           = shift;
	my $templPathFinal = shift;
	my $templPathOri   = shift;
	my $outFile        = shift;

	my $result = 1;

	my $cssPath = $templPathOri;
	$cssPath =~ s/html/css/;
	
	my @cmd = ( EnumsPaths->InCAM_3rdScripts . "pythonLib\\xhtml2pdf" );
	push( @cmd, "--css=$cssPath" );
	push( @cmd, "-w" );
	push( @cmd, "--encoding utf8" );
	push( @cmd, $templPathFinal );
	push( @cmd, $outFile );

	my $cmdStr = join( " ", @cmd );

	my $systeMres = system($cmdStr);

	if ( $systeMres > 0 ) {
		$result = 0;
	}

	# delete temp file
	if ( -e $templPathFinal ) {
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

