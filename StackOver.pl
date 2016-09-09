
 
use strict;
use warnings;


use aliased 'Enums::EnumsPaths'; 

#determine if take user or site file dtm_user_columns
my $path = EnumsPaths->InCAM_users . "stepan\\hooks\\line_hooks\\nc_cre_output.post";
	
print 	$path."\n";
 
if(-e $path){
	
	push(@_, "c:\\Export\\testSourceFile1");
	
	require $path;
}