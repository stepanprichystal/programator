use strict;
use warnings;
use File::Copy;

my $p = 'c:\Export\ExportFiles\pan2_4-18-1500-Imersnizlato_17-09-58.xml';

for ( my $i = 0 ; $i < 20 ; $i++ ) {

	my $newName = "c:\\Export\\ExportFiles\\pan" . $i . "_4-18-1500-Imersnizlato_17-09-58.xml";

	  copy( $p, $newName );

}
