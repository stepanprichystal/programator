
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
	my $self           = shift;
	my $template       = shift;
	my $previewTopPath = shift;
	my $previewBotPath = shift;
	my $infoToPdf      = shift;    # if put info about operator to pdf

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

 
 	$template->SetKey( "ScriptsRoot", GeneralHelper->Root() );
 
	# =================== Table views ============================

	$template->SetKey( "TopView", "Top view", "Pohled top" );
	$template->SetKey( "TopViewImg", $previewTopPath );

	$template->SetKey( "BotView", "Bot view", "Pohled bot" );
	$template->SetKey( "BotViewImg", $previewBotPath );

	return 1;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
