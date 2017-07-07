my @test = (1, 2, 3, 4, 5, 6, 7, 8, 9);



if(scalar(@test) > 5){
	@test =  @test[0..4];	
}

print @test;