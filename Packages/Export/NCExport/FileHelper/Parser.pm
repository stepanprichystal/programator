
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::FileHelper::Parser;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Simple converts hash containing info about parsed file to array of lines
sub ConvertToArray {

	my $self       = shift;
	my %sourceFile = %{ shift(@_) };

	my @lines = ();
	my $line;

	#add header
	my @h = @{ $sourceFile{"header"} };
	for ( my $i = 0 ; $i < scalar(@h) ; $i++ ) {

		$line = $h[$i];
		push( @lines, $line );
	}

	#add  body
	my @b = @{ $sourceFile{"body"} };
	for ( my $i = 0 ; $i < scalar(@b) ; $i++ ) {

		$line = $b[$i];
		push( @lines, $line->{"line"} );
	}

	#add footer
	push( @lines, "\$\n" );
	my @f = @{ $sourceFile{"footer"} };
	for ( my $i = 0 ; $i < scalar(@f) ; $i++ ) {

		$line = $f[$i];
		push( @lines, $line->{"line"} );
	}
	push( @lines, "\$" );

	return @lines;
}


# Merge to NC files together
# Standard output is:
# 1) Header - from target file
# 2) Body - from target file
# 3) Body - from source file
# 4) Footer - from target file
# 4) Footer - from source file
sub MergeTwoFiles {

	my $self        = shift;
	my %sourceFile  = %{ shift(@_) };
	my %targetFile  = %{ shift(@_) };
	my $pasteBefore = shift;            # when 1, body of source file is paste before target body

	my @lines = ();
	my $line;

	#create hash - info about change tool num
	my @fsTmp      = @{ $sourceFile{"footer"} };
	my $startFrom  = $targetFile{"maxTool"} + 1;
	my %toolChange = ();

	for ( my $i = 0 ; $i < scalar(@fsTmp) ; $i++ ) {
		my $t = $fsTmp[$i];

		#key = old tool number , value = new tool number
		$toolChange{ $t->{"tool"} } = $startFrom;
		$startFrom++;
	}

	#renumber source tool in body and merge bodies
	my @bsTmp = @{ $sourceFile{"body"} };
	my @bs    = map { __ChangeTool( $_, \%toolChange ) } @bsTmp;
	my @bt    = @{ $targetFile{"body"} };

	my @b;
	if ($pasteBefore) {
		@b = ( @bs, @bt );
	}
	else {
		@b = ( @bt, @bs );
	}

	#renumber tools in source footer and merge footers
	my @fs = map { __ChangeTool( $_, \%toolChange ) } @fsTmp;
	my @ft = @{ $targetFile{"footer"} };
	push( @ft, @fs );

	#add target header
	my @h = @{ $targetFile{"header"} };

	for ( my $i = 0 ; $i < scalar(@h) ; $i++ ) {

		$line = $h[$i];
		push( @lines, $line );
	}

	#add merged bodies
	for ( my $i = 0 ; $i < scalar(@b) ; $i++ ) {

		$line = $b[$i];
		push( @lines, $line->{"line"} );
	}

	#add merged footers
	push( @lines, "\$\n" );

	for ( my $i = 0 ; $i < scalar(@ft) ; $i++ ) {

		$line = $ft[$i];
		push( @lines, $line->{"line"} );
	}
	push( @lines, "\$" );

	return @lines;
}

sub __ChangeTool {
	my $l          = shift;
	my $toolChange = shift;
	if ( $l->{"tool"} ) {

		#my $oldT = $l->{"tool"};
		my $newT = sprintf( "%02d", $toolChange->{ $l->{"tool"} } );
		$l->{"line"} =~ s/T[0-9]+/T$newT/;
	}

	return $l;
}

# Parse NC files and return hash whit three arrys:
# - header lines
# - body lines
# - footer lines
sub ParseFile {
	my $self = shift;

	my @lines = @{ shift(@_) };    #source files

	#search start/end line number for header, body footer

	my ( $headerEnd, $bodyStart, $bodyEnd, $footerStart, $footerEnd, $maxTNum );

	my $frstTStart;
	my $line;

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		$line = $lines[$i];

		if ( $line =~ m/X(-?[0-9]+\.?[0-9]+)?Y(-?[0-9]+\.?[0-9]+)?T([0-9]+).*/i ) {

			$frstTStart = $i;
			last;
		}
	}

	#Try to search if some M47 command exist between header and body
	unless ($frstTStart) { return 0; }

	$bodyStart = $frstTStart;

	for ( my $i = $frstTStart - 1 ; $i >= 0 ; $i-- ) {

		if ( $i < 0 ) { next; }

		#permited : M47,\P:
		# allowed : M47, some text,  empty lines
		$line = $lines[$i];

		if ( $line =~ /^[\t\n\r]*$/ || ( $line =~ /M47,\s*.*/ && $line !~ /M47,\s*\\P/i ) ) {

			#Ok, this line belongs to body
			$bodyStart = $i;
		}
		else {

			#this is header, end searching
			last;
		}
	}

	$headerEnd = $bodyStart - 1;

	# search body end. Body end, where tool definitions start
	# tool definition starts with "$"
	my $dolarCnt = 0;
	for ( my $i = $bodyStart + 1 ; $i < scalar(@lines) ; $i++ ) {

		if ( $dolarCnt > 1 ) {
			last;
		}

		$line = $lines[$i];

		if ( $line =~ /[\t\n\r]*\$[\t\n\r]*/ ) {

			if ( $dolarCnt == 0 ) {
				$dolarCnt++;
				$bodyEnd     = $i - 1;
				$footerStart = $i + 1;

			}
			else {

				$footerEnd = $i - 1;
			}
		}
	}

	#load lines fro header, bod, footer
	my %parseFile = ();
	my @header    = ();    #item = lines
	my @body      = ();    #item = array of hashes
	my @footer    = ();    #item = hash

	#load header lines
	for ( my $i = 0 ; $i <= $headerEnd ; $i++ ) {

		push( @header, $lines[$i] );
	}

	#load body lines
	for ( my $i = $bodyStart ; $i <= $bodyEnd ; $i++ ) {

		$line = $lines[$i];

		my %info = ();
		if ( $line =~ m/X(-?[0-9]+\.?[0-9]+)?Y(-?[0-9]+\.?[0-9]+)?T([0-9]+).*/i ) {

			#$info{"type"} = "tool";
			$info{"tool"} = int($3);
		}
		else {
			$info{"tool"} = undef;
		}

		$info{"line"} = $line;

		push( @body, \%info );
	}

	#if last tool has G83, add G82 if not exist, InCAM can't do this..
	for ( my $i = scalar(@body) - 1 ; $i >= 0 ; $i-- ) {

		my $info = $body[$i];

		#delete empty lines
		if ( $info->{"line"} =~ /^[\t\n\r]*$/ ) {
			splice @body, $i, 1;
			next;
		}

		#test if G82 exist
		if ( $info->{"line"} =~ /G82/ ) {
			last;
		}

		#take last tool and check if has G83
		if ( $info->{"tool"} ) {

			if ( $info->{"line"} =~ /G83/ ) {
				my %g82 = ( "line" => "G82\n" );
				push( @body, \%g82 );
			}

			last;
		}
	}

	#load footer lines
	$maxTNum = -1;

	for ( my $i = $footerStart ; $i <= $footerEnd ; $i++ ) {

		$line = $lines[$i];

		if ( $line !~ /^[\t\n\r]*$/ && $line =~ m/T([0-9]+)D/ ) {

			my %info = ();

			$info{"tool"} = int($1);
			$info{"line"} = $line;

			if ( $info{"tool"} > $maxTNum ) {

				$maxTNum = $info{"tool"};
			}
			push( @footer, \%info );
		}
	}

	$parseFile{"maxTool"} = $maxTNum;
	$parseFile{"header"}  = \@header;
	$parseFile{"body"}    = \@body;
	$parseFile{"footer"}  = \@footer;

	return %parseFile;


}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {






}



1;
