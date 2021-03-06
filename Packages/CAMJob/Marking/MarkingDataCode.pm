#-------------------------------------------------------------------------------------------#
# Description: Helper methods for datacode marking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Marking::MarkingDataCode;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Definition of regural expression for text datacodes like:
# $$WW
# $$WW$$YY
# KW $$WW $$YY
# KW $$WW $$YYYY
# KW $$WW-$$YY
# etc..
my $dataCodeReg = qr{
				[\w\s-]* 						  # match some wordfs on begining like KW and dash -
					(
						(\${2}(dd|ww|mm|yy|yyyy)) # match dynamic text \$\$WW, \$\$YY, etc
						[-\s\/]*				  # char behind dynamic text - /
					){1,3}						  # all can repeat 1-3 times
				}xi;

# Return layer name, where dynamic datacode was found
sub GetDatacodeLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @layers = ();

	# search in pc2/pc/mc/c/s/ms/ps/ps2
	my @markLayers = grep { $_->{"gROWname"} =~ /^[pm]?[cs]2?$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@markLayers) {

		if ( $self->DatacodeExists( $inCAM, $jobId, $step, $l->{"gROWname"} ) ) {
			push( @layers, $l->{"gROWname"} );
		}
	}

	return @layers;
}

# Return if dynamic datacode exist in layer
# Note.: Work with S&R
sub DatacodeExists {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $exist = 1;

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => 'break_sr+',
								 parse           => 'no'
	);
	my @feat = ();

	if ( open( my $f, "<" . $infoFile ) ) {
		@feat = <$f>;
		close($f);
		unlink($infoFile);
	}

	my @texts = map { $_ =~ /'(.*)'/ } grep { $_ =~ /^#T.*'(.*)'/ } @feat;

 
	my $datacodeOk = scalar( grep { $_ =~ /$dataCodeReg/i } @texts );

	# Id text daacode doesn't exist, find datacode in sybols
	unless ($datacodeOk) {

		my %hist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $layer );
		my @datacodes = map { $_->{"sym"} } grep { $_->{"sym"} =~ /datacode|data|date|ul|logo/i } @{ $hist{"pads"} };

		@datacodes = uniq(@datacodes);

		if ( scalar(@datacodes) ) {

			my $datacodesOk = 0;
			foreach my $sym (@datacodes) {
				my $f = Features->new();
				$f->ParseSymbol( $inCAM, $jobId, $sym );

				my @test = $f->GetFeatures();

				if ( grep { $_->{"type"} eq "T" && $_->{"text"} =~ /$dataCodeReg/i } $f->GetFeatures() ) {
					$datacodesOk = 1;
					last;
				}
			}

			unless ($datacodesOk) {
				$exist = 0;
			}

		}
		else {

			$exist = 0;
		}
	}

	return $exist;
}

# Return ifnfo about dynamic datacodes
# Return array of hashes
# Hash: source=> feat/symbol, text=> "text", mirror => 1/0, wrongMirror => 1/0
# Note: Not work with S&R
sub GetDatacodesInfo {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my @datacodes = ();

	my $exist = 1;

	# 1) Get  datacodes inserted as text features
	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => 'feat_index+f0+',
								 parse           => 'no'
	);
	my @feat = ();

	if ( open( my $f, "<" . $infoFile ) ) {
		@feat = <$f>;
		close($f);
		unlink($infoFile);
	}
	 			
	# Parse only lmited amount of features - datacoe features 															 
	my @featsId = map { $_ =~ /^#(\d*)/i } grep { $_ =~ m/^#(\d*)\s*#T.*'$dataCodeReg'/i } @feat;
	my $f = Features->new();
	$f->Parse( $inCAM, $jobId, $step, $layer, 0, 0, \@featsId );

	
	foreach my $f ( grep{ $_->{"text"} =~ /^$dataCodeReg$/ } $f->GetFeatures() ) {

		my %inf = ("source" => "feat", "text" =>$f->{"text"},  "mirror" => $f->{"mirror"} =~ /y/i ? 1 : 0 );
		push( @datacodes, \%inf );
	}

	# 2) Get  datacodes inserted as symbols
	my @dcSyms       = grep { $_ =~ /^#(\d*)\s*#P.*(datacode|data|date|ul|logo)/i } @feat;
	my @symId        = map  { $_ =~ /^#(\d*)/i } @dcSyms;
	
	my @dcDef = map  {   ($_ =~ /^#(\d*)\s*#P.*\s(.*(datacode|data|date|ul|logo).*)\s[pn]\s\d.*/i)[1] } @dcSyms;
	my %dcDef = map {  $_ =>{} } @dcDef;
 
	foreach my $name (keys %dcDef){
 
		my $fSym = Features->new();
		$fSym->ParseSymbol( $inCAM, $jobId, $name );

		my @textFeat =  grep { $_->{"type"} eq "T" && $_->{"text"} =~ /$dataCodeReg/i } $fSym->GetFeatures();
		
		if(scalar(@textFeat)){
			
			$dcDef{$name}->{"ok"} = 1;
			$dcDef{$name}->{"text"} = join("", map {$_->{"text"} } @textFeat);	
		}else{
			$dcDef{$name}->{"ok"} = 0;
		}

	}

	my $fSym = Features->new();
	$fSym->Parse( $inCAM, $jobId, $step, $layer, 0, 0, \@symId );

	foreach my $f ( $fSym->GetFeatures() ) {

		# add datacode only if parsed symbol is real datacode - contain text with datacode
		if ( $dcDef{$f->{"symbol"}}->{"ok"}  ) {
			
			my %inf = ("source" => "symbol", "text" =>$dcDef{$f->{"symbol"}}->{"text"},  "mirror" => $f->{"mirror"} =~ /y/i ? 1 : 0 );

			push( @datacodes, \%inf );
		}
	}

	# check if mirror is ok
	my $mirror = 0;
	if ( $layer =~ /^[mp]?s/ ) {
		$mirror = 1;
	}

	foreach my $d (@datacodes) {

		if ( $d->{"mirror"} != $mirror ) {
			$d->{"wrongMirror"} = 1;
		}
		else {
			$d->{"wrongMirror"} = 0;
		}
	}

	@datacodes = uniq(@datacodes);

	return @datacodes;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Marking::MarkingDataCode';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d166659";
	
	

	my $exist = MarkingDataCode->GetDatacodesInfo( $inCAM, $jobId, "mpanel", "mc" );
	
	print STDERR $exist;

	 

	die;
	
 
}

1;

