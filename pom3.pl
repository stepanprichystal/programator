Test	
 

 my ($red,$green,$blue) = (255,100,100); #or whatever
$hex = sprintf("%x%x%x",$red,$green,$blue);
print $hex;