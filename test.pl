


	use aliased 'Packages::Technology::EtchOperation';
	
	my $cuThickness = 18;
	my $class = 5;
	my $plated = 1;
	
	print EtchOperation->GetCompensation($cuThickness, $class, $plated);