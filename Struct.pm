package IOperationBuilder;

use Class::Interface;
&interface;    # this actually declares the interface

sub Create;    #first argument OperationMangr

1;

package MLOperationBuilder;

use Class::Interface;
&implements('IOpCreator');

sub new {

	my $self = shift;
	$self = {};
	bless $self;
}

sub Build {
	my $self      = shift;
	my $opManager = shift;

}

1;

package SLOperationBuilder;

use Class::Interface;
&implements('IOpCreator');

sub new {

	my $self = shift;
	$self = {};
	bless $self;
}

sub Build {
	my $self      = shift;
	my $opManager = shift;

}

1;


package NCLayer;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"ncMechanicType"}; #DRILL/mill
	$self->{"ncType"}; # plated rout etc..
	

}


1;

package Operation;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"name"};
	my @arr = ();
	$self->{"layers"} = \@arr;

}

sub AddLayer {
	my $self = shift;

}

sub AddMachine {
	my $self = shift;

}

1;

package OperationMngr;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"opCreator"};
	$self->{"operationBuilder"};

}
 
sub CreateOperations {
	my $self = shift;

	$self->{"operationBuilder"}->Build($self);

}

1;

package MachineMngr;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	#dotahnout specifikaci machine
	$self->{"machines"};

}

sub AssignMachines {
	my $self = shift;

	my $opManager = shift;

}

sub __GetParamsForLayer {
	my $self      = shift;
	my $operation = shift;

}

sub __GetMahinesByParam {
	my $self  = shift;
	my @param = @{ shift(@_) };
}

1;

package ExportFileMngr;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"operationMngr"};

}

sub Run {
	my $self = shift;

	#loop each operation each machines

}

1;

package MergeFileMngr;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"operationMngr"};

}

sub Run {
	my $self = shift;

	#loop each operation each machines

}

1;

package ExportMngr;

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"layerCnt"}      = shift;
	$self->{"operationMngr"} = OperationMngr->new();
	
	$self->{"machineMngr"}   = MachineMngr->new();
	$self->{"exportFileMngr"}   = ExportFileMngr->new();
	$self->{"mergeFileMngr"}   = MergeFileMngr->new();
	

	# class implement IOperationCreator interface
	if ( $self->{"layerCnt"} <= 2 ) {
		
		$self->{"operationMngr"}->{"operationBuilder"} = SLOperationBuilder->new();
	}
	elsif ( $self->{"layerCnt"} >= 4 ) {
		
		$self->{"operationMngr"}->{"operationBuilder"} = MLOperationBuilder->new();
	}

}

sub Run {
	my $self = shift;

	#create sequence of dps operation
	$self->{"operationMngr"}->CreateOperations();
	
	#for every operation filter suitable machines
	$self->{"machineMngr"}->AssignMachines($self->{"operationMngr"});

	#Export physical file
	$self->{"exportFileMngr"}->ExportFiles($self->{"operationMngr"});

	#Merge an move files
	$self->{"mergeFileMngr"}->MergeFiles($self->{"operationMngr"});
}

1;

