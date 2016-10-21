#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Helper;

#3th party library
use strict;
use warnings;
use Win32::GuiTest qw(FindWindowLike SetWindowPos ShowWindow);

#local library


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return base cu thick by layer
sub ShowExportWindow {
	my $self  = shift;
	my $show  = shift;
	my $title = shift;

	my @windows = FindWindowLike( 0, $title );
	for (@windows) {

		ShowWindow( $_, $show );

		return 1;
	}

	return 0;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

