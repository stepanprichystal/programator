use aliased 'Helpers::FileHelper';

my $inputFile = 'c:\Export\test\test.txt';

my @lines = @{ FileHelper->ReadAsLines($inputFile) };

#num of paths (files + dirs)
my $pathsCnt = scalar( split( /\s+/, ( $lines[0] =~ /\((.*)\)/i )[0] ) );

# create array of hashes with input file informations
my @paths = ();
for ( my $i = 0 ; $i < $pathsCnt ; $i++ ) {

	push( @paths, {} );
}

for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

	my ( $key, $vals ) = $lines[$i] =~ /set\s*(\w+)\s*=\s*\((.*)\)/i;
	
	my @vals = split( /\s+/, ($vals)[0] );
	s/\s+$// for (@vals);

	for ( my $j = 0 ; $j < scalar($pathsCnt) ; $j++ ) {

		my $pathInf = $paths[$j];
		$pathInf->{$key} = $vals[$j];
	}
}
 
 # we want only file not dir
 
 @paths = grep{$_->{"giTYPE"} eq "file"} @paths;
 
 
 use Data::Dump qw(dump);
 dump(@paths);

