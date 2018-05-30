
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CouponSingle;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::XMLParser';
use aliased 'Packages::Coupon::Enums';

use alised 'Packages::Coupon::MicrostripBuilders::SEBuilder';
use aliased 'Packages::Coupon::MicrostripBuilders::CoatedMicrostrip';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"settings"} = shift;
 

	$self->{"constrains"} = shift;
 
	$self->{"microstrips"} = [];
	
	$self->{"origin"} = {"x" => 0; "y" => 0};
	
	$self->{"build"} = 0;

	return $self;
}

 
sub Build {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	my $xmlParser = $self->{"settings"}->GetXmlParser();
	
	# Built miscrostip builers

	for(my $i= 0;  $i < scalar(@{$self->{"constrains"}}); $i++){
	
 
		my $constr = $xmlParser->GetConstrain($self->{"constrains"}->[$i]);

		my $mStripBuilder = undef;

		if ( $constrain->{"type"} eq Enums->Type_SE ) {

			$mStripBuilder = SEBuilder->new();

		}
		else {

			die "No known constrain type id defined";
		}

		# set model to microstrip builder
		my $modelBuilder = undef;

		if ( $constrain->{"model"} eq Enums->Model_COATED_MICROSTRIP ) {

			$modelBuilder = CoatedMicrostrip->new();
		}
		else {

			die "No known constrain model id defined";
		}

		$modelBuilder->Init( $inCAM, $jobId, $self->{"settings"}, $constr );
		$mStripBuilder->Init( $inCAM, $jobId, $modelBuildern $self->{"settings"},  $constr );

		push( @{ $self->{"microstrips"} }, $mStripBuilder );
		
		$mStripBuilder->Build($self, $i);

	}
	
	$self->{"build"} = 1;
 
}
 
sub IsMultistrip{
		my $self = shift;
	
	return scalar(@{$self->{"constrains"}}) > 1 : 1 : 0;
} 
 
sub GetMicrostipCnt{
	my $self = shift;
	
	return scalar(@{$self->{"constrains"}});
} 
 
sub GetCouponH{
	my $self = shift;
	
	die "coupon was not builded" unless($self->{"build"});
	
	return 50;
}
#
#}
#
## Add new  section in NIF file
#sub AddSection {
#	my $self       = shift;
#	my $name       = shift;
#	my $secBuilder = shift;
#
#	#new section object
#	my $sec = NifSection->new($name);
#
#	#add handler for item result
#	$sec->{"onRowResult"}->Add( sub { $self->__ResultAddRowError(@_) } );
#
#	#save new section object
#	push( @{ $self->{"sections"} }, $sec );
#
#	$secBuilder->Init( $self->{"inCAM"}, $self->{"jobId"}, $self->{"nifData"}, $self->{"layerCnt"} );
#
#	#buil section
#	$secBuilder->Build($sec);
#
#	return $sec;
#}
#
## Save built NIF to job archive
#sub __Save {
#	my $self = shift;
#
#	my @sections = @{ $self->{"sections"} };
#
#	my @nif      = ();
#	my $saveSucc = 0;
#
#	# 1) join all nif section and ther rows
#	foreach my $sec (@sections) {
#
#		my $titleLen = length( $sec->GetName() );
#		my $fillCnt = int( ( 60 - $titleLen ) / 2 );    #60 is requested total title len
#
#		my $fill = "";
#
#		for ( my $i = 0 ; $i < $fillCnt ; $i++ ) {
#			$fill .= "=";
#		}
#
#		push( @nif, "[$fill SEKCE " . $sec->GetName() . " $fill]\n" );
#
#		foreach my $r ( $sec->GetRows() ) {
#
#			push( @nif, $r . "\n" );
#		}
#
#		push( @nif, "\n" );
#	}
#
#	# 2) If exist former nif contain payments section and ne nif doesn't contain this section
#	#  => copy it to new nif
#
#	my $formerNif = NifFile->new( $self->{"jobId"} );
#	if (    $formerNif->Exist()
#		 && !scalar( grep { $_->GetName() =~ /Priplatky/i } @sections ) )
#	{
#
#		my @rows = ();
#		if ( $formerNif->GetSection("Priplatky", \@rows ) ) {
#			push( @nif, @rows );
#		}
#	}
#
#	push( @nif, "complete=1\n" );
#
#	# 3) Delete fomer nif and save new nif file
#
#	my $path = JobHelper->GetJobArchive( $self->{"jobId"} );
#
#	$path = $path . $self->{"jobId"} . ".nif";
#
#	if ( -e $path ) {
#		unlink($path);
#	}
#
#	my $tmp = EnumsPaths->Client_INCAMTMPOTHER . $self->{"jobId"} . "nif";
#
#	if ( -e $tmp ) {
#		unlink($tmp);
#	}
#
#	my $nifFile;
#	if ( open( $nifFile, "+>", $tmp ) ) {
#
#		$saveSucc = 1;
#
#		#use Encode;
#
#		#		my @nif2 = ();
#		#
#		#		foreach my $str (@nif){
#		#			print STDERR "before$str\n";
#		#			my $str2 = encode("cp1250", $str );
#		#			print STDERR "after$str2\n";
#		#
#		#			print STDERR "before$str\n";
#		#			my $str3 = encode("cp1251", $str );
#		#			print STDERR "after$str3\n";
#		#
#		#
#		#			$str2 = $str;
#		#
#		#			push(@nif2, $str2);
#		#
#		#		}
#
#		#$str = encode("cp1250", $str );
#
#		print $nifFile @nif;
#
#		close($nifFile);
#
#		open my $IN,  "<:encoding(utf8)",   $tmp  or die $!;
#		open my $OUT, ">:encoding(cp1250)", $path or die $!;
#		print $OUT $_ while <$IN>;
#		close $IN;
#		close $OUT;
#
#		#my $f = FileHelper->ChangeEncoding( $path, "utf8", "cp1250" ); #change encoding because of diacritics and helios
#		#unlink($path);
#
#		#FileHelper->Copy($f, $path);
#	}
#	else {
#		$saveSucc = $_;
#
#	}
#
#	$self->__ResultNifCreation();
#	$self->__ResultSaving($saveSucc);
#
#}
#
#sub __ResultSaving {
#	my $self     = shift;
#	my $saveSucc = shift;
#
#	my $resultItem = $self->_GetNewItem("File save");
#
#	unless ($saveSucc) {
#		$resultItem->AddError( "Unable to save nif file. " . $saveSucc );
#	}
#
#	$self->_OnItemResult($resultItem);
#
#}
#
#sub __ResultAddRowError {
#	my $self = shift;
#	my $mess = shift;
#
#	push( @{ $self->{"rowResults"} }, $mess );
#}
#
#sub __ResultNifCreation {
#	my $self = shift;
#
#	my $resultItem = $self->_GetNewItem("File build");
#
#	foreach my $err ( @{ $self->{"rowResults"} } ) {
#
#		$resultItem->AddError($err);
#	}
#
#	$self->_OnItemResult($resultItem);
#
#}
#
#sub TaskItemsCount {
#
#	my $self = shift;
#
#	my $totalCnt = 0;
#
#	$totalCnt++;    #  nc merging
#
#	$totalCnt++;    # variable cnt - nc exporting
#
#	return $totalCnt;
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

