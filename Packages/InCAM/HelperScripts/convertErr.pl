
use aliased 'Helpers::FileHelper';

my @newLines = ();

my $f     = FileHelper->Open("C:/Perl/site/lib/TpvScripts/Scripts/Packages/InCAM/ALL_ERRS");
my @lines = <$f>;

 
#$acp $1012011 Process is already executing a command

for (my $i = 0;  $i < scalar(@lines); $i++) {
	
	my $newL = "";

	my $l = $lines[$i];

	$l =~ s/([0-9a-z_\$])*//;
	
	$l =~ s/[\s\$]*//;
	
	$l =~ m/([\d]*)/;

	my $code = $1;
	$l =~ s/([\d])*//;
	
	$l =~ s/[\s]*//;
	
	$l =~ s/[\n]*//g;
	
	$l =~ s/[\"]*//g;
	
	 
	
$newL = "\$errs{\"$code\"} = \"$l\";\n";
	print $newL . "\n";
	# $errs{1012000} = "Internal Error";
	
	
	
	
	if (defined $code && $code ne ""){
		
		push (@newLines, $newL);
		
		
	}

}

FileHelper->WriteLines("C:/Perl/site/lib/TpvScripts/Scripts/Packages/InCAM/ALL_ERRS_convert", \@newLines );

