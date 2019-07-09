


	use aliased 'Packages::Technology::EtchOperation';
	
	my $cuThickness = 18;
	my $class = 8;
	my $plated = 1;
	
	print EtchOperation->GetCompensation($cuThickness, $class, $plated);