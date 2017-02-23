	use aliased 'Managers::MessageMngr::MessageMngr';
	use aliased 'Enums::EnumsGeneral';

	# typy oken:
	# MessageType_ERROR
	# MessageType_SYSTEMERROR
	# MessageType_WARNING
	# MessageType_QUESTION
	# MessageType_INFORMATION

	my @mess1 = ("ahoj <b>toto je tucne </b>ahoj.\n");
	my @btn = ( "tl1", "tl2" );

	my $messMngr = MessageMngr->new("D3333");

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess1 );    #  Script se zastavi

	my $btnNumber = $messMngr->Result();    # vraci poradove cislo zmacknuteho tlacitka (pocitano od 1, zleva)

	$messMngr->Show( -1, EnumsGeneral->MessageType_WARNING, \@mess1 )    #  Script se nezastavi a jede dal;
