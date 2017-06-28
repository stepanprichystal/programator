
my $dir = "3.02sp1";

if($dir =~ /^(\d+\.\d+)(SP(\d+))?/i){
	
 
	
	my $total = defined $3 ? $1.$3 : $1;
	
	print $total;
	 
	
	
}