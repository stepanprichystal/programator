#!/usr/bin/perl -w

# Ze souboru kde jous jen parametry jedny udela soubor:

## Drilling parameters
#
#C0.10F1.3U1.6S300.0H500
#C0.15F1.6U2.4S233.0H500
#C0.20F1.7U3.2S175.0H1000
#C0.25F1.9U4.0S140.0H1500
# 
## Routing parameters
#
#C0.10F1.3U1.6S300.0H500
#C0.15F1.6U2.4S233.0H500
#C0.20F1.7U3.2S175.0H1000
#C0.25F1.9U4.0S140.0H1500
#
## Special tools
#
#C6.50F0.1U25.0S7.0H500special=d6.5a90
#C6.50F0.1U25.0S7.0H500special=d6.5a120

#3th party library
use strict;
use warnings;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Helpers::FileHelper';

use aliased 'CamHelpers::CamDTM';

my $path = "\\\\incam\\incam_server\\users\\stepan\\hooks\\ncd\\parametersFile";

use File::Find;

find( { wanted => \&process_file, no_chdir => 1 }, $path );

sub process_file {
	if ( -f $_  && $_ !~ /navod/ ) {

		my $file = $_;

		my @l = @{ FileHelper->ReadAsLines($file) };
		
		if($l[0] =~ /%/){
			shift @l;
		}

		unlink($file);

		my @new = ();
		push( @new, "\n# Drilling parameters\n" );
		push( @new, "\n" );
		push( @new, @l );
		push( @new, "\n" );
		push( @new, "\n# Routing parameters\n" );
		push( @new, "\n" );
		push( @new, @l );
		push( @new, "\n" );
		push( @new, "\n# Special tools\n" );
		push( @new, "\n" );

		FileHelper->WriteLines($file, \@new);

		print "This is a file: $_\n";

	}
}

