
#!/usr/bin/perl

use Win32::Process;

my $f1 = "c:\\Export\\report\\dps.pdf";
my $f2 = "c:\\Export\\report\\template.pdf";

my $tar = "c:\\Export\\report\\merged.pdf";

use aliased 'Packages::Pdf::PdfOperation::PdfOperation';

my @array = ( $f1, $f2 );

PdfOperation->MergeDocs( \@array, $tar );

#
#my $prog = "c:\\export\\report\\im\\convert.exe";
#
#
#
#
#	my $processObj2;
#	Win32::Process::Create( $processObj2, $prog, $cmd,
#							0, NORMAL_PRIORITY_CLASS,".")
#	  || die "Failed to create CloseZombie process.\n";
#
#
#print "HOTOVO";
