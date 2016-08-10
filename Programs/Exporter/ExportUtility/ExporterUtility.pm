
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExporterUtility;
use base 'Managers::AsyncJobMngr::AsyncJobMngr';

#3th party library

use Wx;
use strict;
use warnings;

#local library
use Widgets::Style;
use aliased 'Widgets::Forms::MyWxFrame';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::JobExport';
 
use aliased 'Managers::MessageMngr::MessageMngr';


#my $THREAD_MESSAGE_EVT : shared;
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

#use constant {
#			   ITEM_RESULT  => "itemResult",
#			   ITEM_ERROR   => "itemError",
#			   GROUP_EXPORT => "groupExport"
#};


sub new {
	my $class  = shift;
	my $parent = shift;

	if ( defined $parent && $parent == -1 ) {
		$parent = undef;
	}

	my $self = $class->SUPER::new( $parent, @_ );

	bless($self);

	#set handlers

	$self->{'onJobStartRun'}->Add( sub    { $self->__OnJobStartRunHandler(@_) } );
	$self->{'onJobDoneEvt'}->Add( sub     { $self->__OnJobDoneEvtHandler(@_) } );
	$self->{'onJobProgressEvt'}->Add( sub { $self->__OnJobProgressEvtHandler(@_) } );
	$self->{'onJobMessageEvt'}->Add( sub  { $self->__OnJobMessageEvtHandler(@_) } );
	$self->{'onRunJobWorker'}->Add( sub { $self->__OnRunJobWorker(@_) } );

	my $mainFrm = $self->__SetLayout();
	$mainFrm->Show(1);

	$self->__RunTimers();

	#$self->{'onSetLayout'}->Add( sub { $self->__OnSetLayout(@_)});

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Handler methods
#-------------------------------------------------------------------------------------------#

sub __RunTimers {
	my $self = shift;

	my $timerFiles = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerFiles, sub { __CheckFilesHandler( $self, @_ ) } );
	$self->{"timerFiles"} = $timerFiles;

	my $timerRefresh = Wx::Timer->new( $self->{"mainFrm"}, -1, );
	Wx::Event::EVT_TIMER( $self->{"mainFrm"}, $timerRefresh, sub { __Refresh( $self, @_ ) } );
	$timerRefresh->Start(200);

}

sub __OnJobStartRunHandler {
	my $self    = shift;
	my $jobGUID = shift;

	print "Exporter utility: Start job id: $jobGUID\n";

}
 
sub __OnJobDoneEvtHandler {
	my $self     = shift;
	my $jobGUID  = shift;
	my $exitType = shift;

	print "Exporter utility: Job DONE job id: $jobGUID, exit type: $exitType\n";

}

sub __OnJobProgressEvtHandler {
	my $self    = shift;
	my $jobGUID = shift;
	my $value   = shift;

	$self->{"gauge"}->SetValue($value);

	print "Exporter utility:  job progress, job id: " . $jobGUID . " - value: " . $value . "\n";

}

sub __OnJobMessageEvtHandler {
	my  $self = shift; 
	my $jobGUID = shift;
	my $messType = shift;
	my $data = shift;
	
	print "Exporter utility::  job id: " . $jobGUID . " - messType: " . $messType . " - data: " . $data. "\n";	
}


#this handler run, when new job thread is created
sub __OnRunJobWorker {
	my $self = shift;
	my $pcbId   = shift;
	my $jobGUID = shift;
	my $inCAM   = shift;
	my $THREAD_PROGRESS_EVT : shared = ${ shift(@_) };
	my $THREAD_MESSAGE_EVT : shared = ${ shift(@_) };
	
	#vytvorit nejakou Base class ktera bude obsahovat odesilani zprav prostrednictvim messhandler
	my $jobExport = JobExport->new($pcbId, $jobGUID, $inCAM, "data", \$THREAD_PROGRESS_EVT, \$THREAD_MESSAGE_EVT,  $self->{"mainFrm"} );
	
	$jobExport->RunExport();
	
	
	#$jobExport->{'onItemResult'}->Add{  sub    { $self->__OnItemResultHandler(@_) }  };
	#$jobExport->{'onItemError'}->Add{  sub    { $self->__OnItemErrorHandler(@_) }  }
	#$jobExport->{'onGroupExport'}->Add{  sub    { $self->__OnGroupExportHandler(@_) }  }
	

	#use aliased 'Packages::Export::NCExport::NC_Group';

	#my $jobId    = "F13608";
	#my $stepName = "panel";

	#use aliased 'CamHelpers::CamHelper';

	#CamHelper->OpenJobAndStep( $inCAM, $pcbId, $stepName );

	#my $ncgroup = NC_Group->new( $inCAM, $pcbId );

	#$ncgroup->Run();

	#doExport($pcbId,$inCAM)
#
#	my %res : shared = ();
#	for ( my $i = 0 ; $i < 50 ; $i++ ) {
#
#		$res{"jobGUID"} = $jobGUID;
#		$res{"port"}    = "port";
#		$res{"value"}   = $i;
#
#		my $threvent2 = new Wx::PlThreadEvent( -1, $THREAD_PROGRESS_EVT, \%res );
#		Wx::PostEvent( $self->{"mainFrm"}, $threvent2 );
#
#		sleep(1);
#	}
	print "TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT KONEEEEC";

}


#sub __JobExportMessHandler{
#	my ( $self, $frame, $event) =  @_;
#	my $test = shift;
#	#my %event = %{shift(@_)};
#	
#	#my $jobGUID = $event{"jobGUID"};
#	#my $messType = $event{"messType"};
#	#my $data = $event{"data"};
#	
#	 print $test;
#	
#	#print "JobExport:  job id: " . $jobGUID . " - messType: " . $messType . " - data: " . $data. "\n";
#}


sub __SetLayout {

	my $self    = shift;
	my $mainFrm = $self->{"mainFrm"};

	#SIZERS
	my $sz = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	#CONTROLS
	my $txt = Wx::StaticText->new( $mainFrm, -1, "ahoj", &Wx::wxDefaultPosition, [ 300, 200 ] );
	$self->{"txt"} = $txt;

	my $txt2 = Wx::StaticText->new( $mainFrm, -1, "ahoj2", &Wx::wxDefaultPosition, [ 300, 200 ] );
	$self->{"txt2"} = $txt2;

	my $button = Wx::Button->new( $mainFrm, -1, "test click" );

	Wx::Event::EVT_BUTTON( $button, -1, sub { $self->__OnClick($button) } );

	my $button2 = Wx::Button->new( $mainFrm, -1, "exit job" );

	Wx::Event::EVT_BUTTON( $button2, -1, sub { $self->__OnClickExit($button2) } );

	my $button3 = Wx::Button->new( $mainFrm, -1, "run new job" );

	Wx::Event::EVT_BUTTON( $button3, -1, sub { $self->__OnClickNew($button3) } );

	my $pcbidTxt   = Wx::TextCtrl->new( $mainFrm, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );
	my $pcbguidTxt = Wx::TextCtrl->new( $mainFrm, -1, "", &Wx::wxDefaultPosition, [ 150, 25 ] );

	my $gauge = Wx::Gauge->new( $mainFrm, -1, 100, [ -1, -1 ], [ 300, 20 ], &Wx::wxGA_HORIZONTAL );

	$gauge->SetValue(0);

	$sz->Add( $txt,        1, &Wx::wxEXPAND );
	$sz->Add( $txt2,       1, &Wx::wxEXPAND );
	$sz->Add( $gauge,      0, &Wx::wxEXPAND );
	$sz->Add( $button,     0, &Wx::wxEXPAND );
	$sz->Add( $button2,    0, &Wx::wxEXPAND );
	$sz->Add( $button3,    0, &Wx::wxEXPAND );
	$sz->Add( $pcbidTxt,   0, &Wx::wxEXPAND );
	$sz->Add( $pcbguidTxt, 0, &Wx::wxEXPAND );

	$mainFrm->SetSizer($sz);

	$self->{"gauge"}      = $gauge;
	$self->{"pcbidTxt"}   = $pcbidTxt;
	$self->{"pcbguidTxt"} = $pcbguidTxt;
	
	
	
	#$THREAD_MESSAGE_EVT = Wx::NewEventType;
	#Wx::Event::EVT_COMMAND( $self->{"mainFrm"}, -1, $THREAD_MESSAGE_EVT, sub { $self->__JobExportMessHandler(@_) } );

	return $mainFrm;

}

sub __CheckFilesHandler {
	my ( $self, $mainFrm, $event ) = @_;

	my @actFiles = @{ $self->{"exportFiles"} };
	my @newFiles = ();

	#get all files from path
	opendir( DIR, EnumsPaths->Client_EXPORTFILES ) or die $!;

	my $fileCreated;
	my $fileName;
	my $filePath;

	while ( my $file = readdir(DIR) ) {

		next unless $file =~ /^[a-z](\d+)\.xml$/i;

		$filePath = EnumsPaths->Client_EXPORTFILES . $file;

		#get file attributes
		my @stats = stat($filePath);

		$fileName = lc($file);
		$fileName =~ s/\.xml//;
		$fileCreated = $stats[9];

		my $cnt = scalar( grep { $_->{"name"} eq $fileName && $_->{"created"} == $fileCreated } @actFiles );

		unless ($cnt) {
			my %newFile = ( "name" => $fileName, "created" => $fileCreated );
			push( @newFiles, \%newFile );

		}
	}

	if ( scalar(@newFiles) ) {
		@newFiles = sort { $a->{"created"} <=> $b->{"created"} } @newFiles;
		push( @{ $self->{"exportFiles"} }, @newFiles );
	}

	my $str = "";
	foreach my $f ( @{ $self->{"exportFiles"} } ) {
		$str .= $f->{"name"} . " - " . localtime( $f->{"created"} ) . "\n";

	}

	$self->{"txt"}->SetLabel($str);
	print "Aktualiyace - " . localtime( time() ) . "\n";
}

sub __OnClick {

	my ( $self, $button ) = @_;

	print "\nClick\n";
}

sub __OnClickExit {

	my ( $self, $button ) = @_;
	$self->_AbortJob( $self->{"pcbidTxt"}->GetValue() );

}

sub __OnClickNew {

	my ( $self, $button ) = @_;

	#my @j = @{ $self->{"jobs"} };
	#my $i = ( grep { $j[$_]->{"pcbId"} eq $self->{"pcbidTxt"}->GetValue() } 0 .. $#j )[0];

	#if ( defined $i ) {

	my $jobGUID = $self->_AddJobToQueue( $self->{"pcbidTxt"}->GetValue() );

	#}
}

sub __Refresh {
	my ( $self, $frame, $event ) = @_;

	#$self->_SetDestroyServerOnDemand(1);

	my $txt2 = $self->_GetInfoServers();
	my $txt  = $self->_GetInfoJobs();

	$self->{"txt"}->SetLabel($txt);
	$self->{"txt2"}->SetLabel($txt2);

}

sub doExport {
	my ( $id, $inCAM ) = @_;

	my $errCode = $inCAM->COM( "clipb_open_job", job => $id, update_clipboard => "view_job" );

	#
	#	$errCode = $inCAM->COM(
	#		"open_entity",
	#		job  => "F17116+2",
	#		type => "step",
	#		name => "test"
	#	);

	#return 0;
	for ( my $i = 0 ; $i < 5 ; $i++ ) {

		sleep(3);
		$inCAM->COM(
					 'output_layer_set',
					 layer        => "c",
					 angle        => '0',
					 x_scale      => '1',
					 y_scale      => '1',
					 comp         => '0',
					 polarity     => 'positive',
					 setupfile    => '',
					 setupfiletmp => '',
					 line_units   => 'mm',
					 gscl_file    => ''
		);

		$inCAM->COM(
					 'output',
					 job                  => $id,
					 step                 => 'input',
					 format               => 'Gerber274x',
					 dir_path             => "c:/Perl/site/lib/TpvScripts/Scripts/data",
					 prefix               => "incam1_" . $id . "_$i",
					 suffix               => "",
					 break_sr             => 'no',
					 break_symbols        => 'no',
					 break_arc            => 'no',
					 scale_mode           => 'all',
					 surface_mode         => 'contour',
					 min_brush            => '25.4',
					 units                => 'inch',
					 coordinates          => 'absolute',
					 zeroes               => 'Leading',
					 nf1                  => '6',
					 nf2                  => '6',
					 x_anchor             => '0',
					 y_anchor             => '0',
					 wheel                => '',
					 x_offset             => '0',
					 y_offset             => '0',
					 line_units           => 'mm',
					 override_online      => 'yes',
					 film_size_cross_scan => '0',
					 film_size_along_scan => '0',
					 ds_model             => 'RG6500'
		);

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Exporter::ExporterUtility';

	my $exporter = ExporterUtility->new();

	#$app->Test();

	$exporter->MainLoop;

}

1;

#my $app = MyApp2->new();

#my $worker = threads->create( \&work );
#print $worker->tid();

#
#sub work {
#	sleep(5);
#	print "METODA==========\n";
#
#	#!!! I would like send array OR hash insted of scalar here: my %result = ("key1" => 1, "key2" => 2 );
#	# !!! How to do that?
#
#}
#
#sub OnCreateThread {
#	my ( $self, $event ) = @_;
#	@_ = ();
#}

1;
