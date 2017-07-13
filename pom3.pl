

my $str = 'KW-$$WW';

if($str =~ /(\${2}(dd|ww|mm|yy|yyyy)\s*){1,3}$/i){
	
	print "test";
}