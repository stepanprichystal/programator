
#!/usr/bin/perl

use Win32::Process;


my $imgSource = "c:\\Export\\report\\dps.pdf";
my $imgTarget1 = "c:\\Export\\report\\obr1.png";
my $imgTarget2 = "c:\\Export\\report\\obr2.png";



my $result = system("y:\\server\\site_data\\scripts3rdParty\\im\\convert.exe  -density 200 $imgSource -shave 20x20 -trim -shave 5x5  $imgTarget1");
print STDERR "result is: ". $result."\n";

#system("c:\\export\\report\\im\\convert.exe  -density 400 $imgSource -shave 20x20 -trim -shave 5x5  $imgTarget1");
 


print "HOTOVO";

exit;
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