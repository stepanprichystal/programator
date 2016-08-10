
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::Helper;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use Class::Inspector;
use B qw(svref_2object);
use aliased 'Helpers::GeneralHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#


 

sub GetJobId {
		my $self = shift;
		
		return "F17116+1";
	
}

sub GetChildId {
		my $self = shift;
		
				return "1";
	
}

sub __GetAllActionModules {

	my $self          = shift;
	my @actionModules = ();

	my $dir = GeneralHelper->Root() . '/Programs/CamGuide/Actions';

	opendir( DIR, $dir ) or die $!;

	while ( my $file = readdir(DIR) ) {

		my $module;

		if ( $file =~ m/^\./ ) {
			next;
		}

		$file =~ s/\.pm//;

		$module = 'Programs::CamGuide::Actions::' . $file;

		push( @actionModules, $module );
	}

	return @actionModules;

}

sub LoadAllActionModules {

	my $self          = shift;
	
	my @actionModules = $self->__GetAllActionModules();
	
	foreach my $module (@actionModules) {
		eval("use $module;");
	}

}

sub GetActionInfos {

	my $self = shift;

	my @actionNames = ();
	my @actionInfo  = ();

	my @actionModules = $self->__GetAllActionModules();

	foreach my $module (@actionModules) {
		eval("use $module;");

		my $temp = Class::Inspector->methods( $module, 'full', 'public' );


		if ( defined $temp ) {

			push( @actionNames, @{$temp} );
		}

	}

	foreach my $a (@actionNames) {

		my %info = ();

		$a =~ m/((\S)*\:\:)/;
		my $ns = $1;

		$a =~ m/(\w+)$/;
		my $name = $1;

		$a =~ m/(\w+\:\:\w+)$/;
		my $code = $1;

		$info{"actionCode"} = $code;

		print '$' . $ns . "n{" . $name . "}\n";

		$info{"actionName"} = eval '$' . $ns . "n{" . $name . "}";
		$info{"actionDesc"} = eval '$' . $ns . "d{" . $name . "}";

		push( @actionInfo, \%info );

	}

	return @actionInfo;
}

sub CodeNameOfAction {
	my $self = shift;
	my $r    = shift;

	return unless my $cv = svref_2object($r);
	return
	  unless $cv->isa('B::CV')
		  and my $gv = $cv->GV;
	my $name = '';
	if ( my $st = $gv->STASH ) {
		$name = $st->NAME . '::';
	}
	my $n = $gv->NAME;
	if ($n) {
		$name .= $n;
		if ( $n eq '__ANON__' ) {
			$name .= ' defined at ' . $gv->FILE . ':' . $gv->LINE;
		}
	}

	$name =~ s/Programs::CamGuide::Actions:://;

	return $name;
}

sub NameOfActionPackage {
	my $self = shift;
	my $r    = shift;

	return unless my $cv = svref_2object($r);
	return
	  unless $cv->isa('B::CV')
		  and my $gv = $cv->GV;
	my $name = '';
	if ( my $st = $gv->STASH ) {
		$name = $st->NAME . '::';
	}

	return $name;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	my @infos = Programs::CamGuide::Helper->GetActionInfos();

}

1;

