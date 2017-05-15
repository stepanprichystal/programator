    ######### System initialization section ###
    use Log::Log4perl qw(get_logger :levels);

    my $food_logger = get_logger("Groceries::Food");
    $food_logger->level($INFO);

drink();
drink("Soda");

sub drink {
	my ($what) = @_;

	my $logger = get_logger();

	if ( defined $what ) {
		$logger->info( "Drinking ", $what );
	}
	else {
		$logger->error("No drink defined");
	}
}
