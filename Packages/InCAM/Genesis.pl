=head1
Package for running Perl programs in a Genesis environment.

This file is included by Genesis.pm.
See Genesis.pm for general documentation.

=cut

package Genesis;
@ISA       = qw (Exporter);
use Exporter;
use Socket;
require 'shellwords.pl';


my $version = '2.0';

$socketOpen = 0 ;
$DIR_PREFIX = '@%#%@' ; 

END {
    if ($socketOpen == 0 ) { 
          return ; 
    }
    send(SOCK, "${DIR_PREFIX}CLOSEDOWN \n", 0);
    close (SOCK) || warn "close: $!";
}

sub new { 
    local $class  = shift; # name
    local $remote = shift;
    local $genesis;

    $remote = 'localhost' unless defined $remote;

    # If standard input is not a terminal then we are a pipe to csh, and hence
    # presumably running under Genesis. In this case use stdin and stdout as is.
    # If, on the other hand, stdin is a tty, then we are running remotely, in which case
    # set up the communications, namely the socket, so that we communicate.  

    $genesis->{remote} = $remote;
    $genesis->{port} = 'genesis';

    bless $genesis, $class;

    $genesis->{comms} = 'pipe';
    if (-t STDIN) {
	$genesis->{comms} = 'socket';
	$genesis->openSocket();
	$genesis->{socketOpen} = 1;
	$genesis->inheritEnvironment();
    }
    binmode(STDOUT);
    return $genesis; 
}

sub closeDown { 
    local ($genesis) = shift;
    $genesis->sendCommand("CLOSEDOWN","");     
}

sub inheritEnvironment {
    local ($genesis) = shift;
    $genesis->sendCommand("GETENVIRONMENT","");
    while (1) {
	$reply = $genesis->getReply();
	if ($reply eq 'END') {
	    last;
	}
	($var,$value) = split('=',$reply,2);
	$ENV{$var} = $value;
    }
    # And here is a patch for LOCALE. IBM AIX defines LC_MESSAGES and LC__FASTMSG
    # which are not right if you are running remotely
    undef $ENV{LC_MESSAGES};
    undef $ENV{LC__FASTMSG};
}

=head
sub DESTROY { 
    local ($genesis) = shift;
    $socketOpen -- ; # reduce reference count
    if ($socketOpen) { 
	return ;
    }
    if ($genesis->{socketOpen}) { 
        $genesis->closeDown() ;
	close (SOCK) || warn "close: $!";; 
    }
}
=cut

sub openSocket {
    local ($genesis) = shift;
    local ($remote,$port, $iaddr, $paddr, $proto);
    $socketOpen ++  ;
    return if $socketOpen != 1 ;
    $port = $genesis->{port} ;
    $remote = $genesis->{remote};

    if ($port =~ /\D/) {
	$port = getservbyname($port, 'tcp');
    }

    if (! defined $port) {
        $port = 56753;
# The port has not been defined. To define it you need to 
# become root and add the following line in /etc/services 
# genesis     56753/tcp    # Genesis port for debugging perl scripts
    }
    $iaddr = inet_aton($remote) || die "no host: $remote";
    $paddr = sockaddr_in($port, $iaddr);
    $proto = getprotobyname('tcp');
    socket(SOCK, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
    connect(SOCK, $paddr) || die "connect: $!";
}

# remove excess white space
sub removeNewlines {
    local($command) = shift;
    $command =~ s/\n\s*/ /g;
    return $command;
}

# send the command to be executed
sub sendCommand {
    local($genesis) = shift;
    local $commandType = shift;
    local $command = shift;

    $genesis->blankStatusResults();
    if ($genesis->{comms} eq 'pipe') {
	$genesis->sendCommandToPipe($commandType,$command);
    } elsif ($genesis->{comms} eq 'socket') {
	$genesis->sendCommandToSocket($commandType,$command);
    }
}

sub sendCommandToPipe {
    local($genesis) = shift;
    local $commandType = shift;
    local $command = shift;
    local $old_select = select (STDOUT);
    local $flush_status = $|;	          # save the flushing status
    $| = 1;			          # force flushing of the io buffer
    print $DIR_PREFIX, "$commandType $command\n";
    $| = $flush_status;		          # restore the original flush status
    select ($old_select);
}

sub sendCommandToSocket {
    local($genesis) = shift;
    local $commandType = shift;
    local $command = shift;
    send(SOCK, "${DIR_PREFIX}$commandType $command\n", 0);
    # should check for errors here !!!
}

# wait for the reply
sub getReply {
    local $reply;
    if ($genesis->{comms} eq 'pipe') {
	chomp ($reply = <STDIN>);  # chop new line character
    } elsif ($genesis->{comms} eq 'socket') {
	chomp ($reply = <SOCK>);  # chop new line character
    }
    return $reply;
}

# Checking is on. If a command fails, the script fail
sub VON {
    local ($genesis) = shift;
    $genesis->sendCommand("VON", "");
}

# Checking is off. If a command fails, the script continues
sub VOF {
    local ($genesis) = shift;
    $genesis->sendCommand("VOF", "");
}

# Allow Genesis privileged activities. Normally this is executed at the 
# start of each script.
sub SU_ON {
    local ($genesis) = shift;
    $genesis->sendCommand("SU_ON", "");
}

sub SU_OFF {
    local ($genesis) = shift;
    $genesis->sendCommand("SU_OFF", "");
}

sub blankStatusResults {
    local ($genesis) = shift;
    undef $genesis->{STATUS};
    undef $genesis->{READANS};
    undef $genesis->{PAUSANS};
    undef $genesis->{MOUSEANS};
    undef $genesis->{COMANS};
}

# Wait for a reply from a popup
sub PAUSE {
    local ($genesis) = shift;
    local ($command) = @_;
    $genesis->sendCommand("PAUSE", removeNewlines($command));
    $genesis->{STATUS}  = getReply();
    $genesis->{READANS} = getReply();
    $genesis->{PAUSANS} = getReply();
}

# Get the mouse position
sub MOUSE {
    local ($genesis) = shift;
    local ($command) = @_;
    $genesis->sendCommand("MOUSE", removeNewlines($command));
    $genesis->{STATUS}   = getReply();
    $genesis->{READANS}  = getReply();
    $genesis->{MOUSEANS} = getReply();
}

# Send a command
sub COM {
    local ($genesis) = shift;
    local $command;
    if (@_ == 1) {
       ($command) = @_;
       $genesis->sendCommand("COM",removeNewlines($command));
    } else {
       $command = shift;
       local %args = @_;
       foreach (keys %args) {
          $command .= ",$_=$args{$_}";
       }
       $genesis->sendCommand("COM", $command);
    }
    $genesis->{STATUS}  = getReply();
    $genesis->{READANS} = getReply();
    $genesis->{COMANS}  = $genesis->{READANS};
}
# Send a command
sub COM2 {
    local ($genesis) = shift;
    local $command;
    if (@_ == 1) {
       ($command) = @_;
       $genesis->sendCommand("COM",removeNewlines($command));
    } else {
       $command = shift;
       local %args = @_;
       foreach (keys %args) {
          $command .= ",$_=$args{$_}";
       }
       $genesis->sendCommand("COM", $command);
    }
    $genesis->{STATUS}  = getReply();
    $genesis->{READANS} = getReply();
    $genesis->{COMANS}  = $genesis->{READANS};
}

# Send an auxiliary command
sub AUX {
    local ($genesis) = shift;
    local $command;
    if (@_ == 1) {
       ($command) = @_;
       $genesis->sendCommand("AUX", removeNewlines($command));
    } else {
       $command = shift;
       local %args = @_;
       foreach (keys %args) {
          $command .= ",$_=$args{$_}";
       }
       $genesis->sendCommand("AUX", $command);
    }
    $genesis->{STATUS}  = getReply();
    $genesis->{READANS} = getReply();
    $genesis->{COMANS}  = $genesis->{READANS};
}

# Get some basic info
# It is received in the form of a csh script, so the information needs 
# hacking to get into a form suitable for perl

sub DO_INFO {
    local ($genesis) = shift;
    local $info_pre = "info,out_file=\$csh_file,write_mode=replace,args=";
    local $info_com = "$info_pre @_ -m SCRIPT";
    $genesis->parse($info_com);
}

sub parse {
  local ($genesis) = shift;
  local($request) = shift;
  local $csh_file  = "$ENV{GENESIS_DIR}/tmp/info_csh.$$";
  $request =~ s/\$csh_file/$csh_file/;
	     $genesis->COM ($request);

  open (CSH_FILE,  "$csh_file") or warn "Cannot open info file - $csh_file: $!\n";
  while (<CSH_FILE>) {
    chomp;
    next if /^\s*$/; # ignore blank lines 
    ($var,$value) = /set\s+(\S+)\s*=\s*(.*)\s*/; # extract the name and value 

    $value =~ s/^\s*|\s*$//g; # remove leading and trailing spaces from the value
    $value =~ s/\cM/<^M>/g;   # change ^M temporarily to something else
    # This happens mainly in giSEP, and shellwords makes it disappear

    @value = shellwords($_);			   

    # Deal with an csh array differently from a csh scalar
    if ($value =~ /^\(/ ) {
      $value =~ s/^\(|\)$//g; # remove leading and trailing () from the value
      @words = shellwords($value); # This is a standard part of the Perl library
      grep {s/\Q<^M>/\cM/g} @words;
      $genesis->{doinfo}{$var} = [@words];
      $genesis->{$var} = [@words];
    } else {
      $value =~ s/\Q<^M>/\cM/g;
      $value =~ s/^'|'$//g;

      $genesis->{doinfo}{$var} = $value;
      $genesis->{$var} = $value;
    }
  }
  close (CSH_FILE);
  unlink ($csh_file);
}


sub INFO {
  local ($genesis) = shift;
  local %args      = @_;
  local ($entity_path, $data_type, $parameters,
         $serial_number, $options, $help, $entity_type) = ("","","","","","","");
  local $i;
  local $units = 'units = inch';
  local $parse = 'yes';

  foreach (keys %args) {
    $i = $args{$_};
    if ($_ eq "entity_type") {
          $entity_type = "-t $i";
       } elsif ($_ eq "entity_path") {
          $entity_path = "-e $i";
       } elsif ($_ eq "data_type") {
          $data_type = "-d $i";
       } elsif ($_ eq "parameters") {
          $parameters = "-p $i"; 
       } elsif ($_ eq "serial_number") {
          $serial_number = "-s $i";
       } elsif ($_ eq "options") {
          $options = "-o $i";
       } elsif ($_ eq "help") {
          $help = "-help";
       } elsif ($_ eq "units") {
          $units = "units= $i";
       } elsif ($_ eq "parse") {
          $parse = $i;
       }
    }
    local $info_pre = "info,out_file=\$csh_file,write_mode=replace,$units,args=";
    local $info_com = "$info_pre $entity_type $entity_path $data_type "
                    . "$parameters $serial_number $options $help";
    if ($parse eq 'yes') {
      $genesis->parse($info_com);
    } else {
      local $csh_file = "$ENV{GENESIS_DIR}/tmp/info_csh.$$";
      $info_com =~ s/\$csh_file/$csh_file/;
	     $genesis->COM ($info_com);
      return $csh_file;
    }
}

sub INFO2 {
  local ($genesis) = shift;
  local $arg      = shift;

#  local $i;
  local $parse = 'yes';

#  foreach (keys %args) {
#    $i = $args{$_};
#    if ($_ eq "entity_type") {
#          $entity_type = "-t $i";
#       } elsif ($_ eq "entity_path") {
#          $entity_path = "-e $i";
#       } elsif ($_ eq "data_type") {
#          $data_type = "-d $i";
#       } elsif ($_ eq "parameters") {
#          $parameters = "-p $i"; 
#       } elsif ($_ eq "serial_number") {
#          $serial_number = "-s $i";
#       } elsif ($_ eq "options") {
#          $options = "-o $i";
#       } elsif ($_ eq "help") {
#          $help = "-help";
#       } elsif ($_ eq "parse") {
#          $parse = $i;
#       }
#    }
    local $info_pre = "info,out_file=\$csh_file,write_mode=replace,args=";
    local $info_com = "$info_pre $arg";
    if ($parse eq 'yes') {
      $genesis->parse($info_com);
    } else {
      local $csh_file = "$ENV{GENESIS_DIR}/tmp/info_csh.$$";
      $info_com =~ s/\$csh_file/$csh_file/;
	     $genesis->COM ($info_com);
      return $csh_file;
    }
}


sub clearDoinfo { 
    local ($me) = shift;
    undef $me->{doinfo};
}



sub parse_csh {
  my $self      = shift;
  my $csh_file  = shift;
  my $resultvar = shift;

  $resultvar = 'parsed_csh' unless defined $resultvar;
  open (CSH_FILE,  "$csh_file") or warn "Cannot open csh file - $csh_file: $!\n";
  while (<CSH_FILE>) {
    chomp;
    next if /^\s*$/; # ignore blank lines 
    ($var,$value) = /set\s+(\S+)\s*=\s*(.*)\s*/; # extract the name and value 

    $value =~ s/(^\s*|\s*$)//g; # remove leading and trailing spaces from the value
    $value =~ s/\cM/<^M>/g;   # change ^M temporarily to something else
    # This happens mainly in giSEP, and shellwords makes it disappear

    @value = Genesis::shellwords($_);

    # Deal with an csh array differently from a csh scalar
    if ($value =~ /^\(/ ) {
      $value =~ s/^\(|\)$//g; # remove leading and trailing () from the value
      @words = Genesis::shellwords($value); # This is a standard part of the Perl library
      grep {s/\Q<^M>/\cM/g} @words;
      $self->{$resultvar}{$var} = [@words];
    } else {
      $value =~ s/\Q<^M>/\cM/g;
      $value =~ s/^'|'$//g;
      $self->{$resultvar}{$var} = $value;
    }
  }
  close (CSH_FILE);
  unlink ($csh_file);
}  # end of parse_csh

=item printFile($file);

=cut

sub printFile {
  local ($genesis) = shift;
  local ($filename) = shift;

  open (FILE, "$filename") or warn "can not open file $filename";
  while (<FILE>) {
    print;
  }
  close (FILE);
}


=item $float = round($value,$precision)

=cut

sub round {
  local ($genesis) = shift;
  local ($value) = shift;
  local ($precision) = shift;

  $precision = 0.05 unless defined $precision;
  if ($precision == 0) {
    return $value;
  }
  return int($value/$precision+1)*$precision;
}



#sub getEntity {
#  local ($genesis,$job,$step,$layer) = @_;
#  local $entity= 'root';

#  $job && $entity='job';
#  $step && $entity='step';
#  $layer && $entity='layer';
#  if ($job) {
#    $genesis->INFO('entity_type'=>$entity);
#  }
#}


#sub getJobs {
#  local ($genesis) = shift;
#  local ($db) = shift;
#  if (!defined $db) {
#    $genesis->INFO('entity_type'=>'root');
#    return @{$genesis->{doinfo}{gJOBS_LIST}};
#  }
#}

#=item @steps = getSteps($job)

#=cut

#sub getSteps {
#  local ($genesis) = shift;
#  local ($job) = shift;

#  $genesis->INFO('entity_type'=>'job',
#                 'entity_path'=>"$job",
#                 'data_type'=>'STEPS_LIST');
#  return @{$genesis->{doinfo}{gSTEPS_LIST}};
#}

#=item @layers = getLayers($job,$step)

#=cut

#sub getLayers {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
 
#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'LAYERS_LIST');
#  return @{$genesis->{doinfo}{gLAYERS_LIST}};
#}


#=item boolean = checkJobExists($job)

#=cut

#sub checkJobExists {
#  local ($genesis) = shift;
#  local ($job) = shift;
 
#  $genesis->INFO('entity_type'=>'job',
#                 'entity_path'=>"$job",
#                 'data_type'=>'exists');
#  return (1) if ($genesis->{doinfo}{gEXISTS} eq 'yes');
#  return (0);
#}


#=item boolean = checkStepExists($job,$step)

#=cut

#sub checkStepExists {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'exists');
#  return (1) if ($genesis->{doinfo}{gEXISTS} eq 'yes');
#  return (0);
#}


#=item boolean = checkLayerExists($job,$step,$layer)

#=cut

#sub checkLayerExists {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  local ($layer) = shift;

#  $genesis->INFO('entity_type'=>'layer',
#                 'entity_path'=>"$job/$step/$layer",
#                 'data_type'=>'exists');
#  return (1) if ($genesis->{doinfo}{gEXISTS} eq 'yes');
#  return (0);
#}


#=item %attr = getAttr($job);

#=item %attr = getAttr($job,$step);

#=item %attr = getAttr($job,$step,$layer);

#=cut

#sub getAttr {
#  my ($genesis,$job,$step,$layer) = @_;
#  my (@attrname, @attrval);
#  my (%attr);
#  my ($i);

#  $job   && ($type = 'job');
#  $step  && ($type = 'step');
#  $layer && ($type = 'layer');

#  $genesis->INFO(entity_type=>$type,
#                 entity_path=>"$job/$step/$layer",
#                 data_type=>'ATTR');
#  @attrname=@{$genesis->{doinfo}{gATTRname}};
#  @attrval=@{$genesis->{doinfo}{gATTRval}};
#  for ($i=0;$i<=$#attrname;$i++) {
#    $attr{$attrname[$i]}=$attrval[$i];
#  }  
#  return %attr;
#}


#=head3  %attr = getJobAttr($job)

#=cut

#sub getJobAttr {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local @attrname;
#  local @attrval;
#  local %attr;
#  local $i;

#  $genesis->INFO('entity_type'=>'job',
#                 'entity_path'=>"$job",
#                 'data_type'=>'ATTR');
#  @attrname=@{$genesis->{doinfo}{gATTRname}};
#  @attrval=@{$genesis->{doinfo}{gATTRval}};
#  for ($i=0;$i<=$#attrname;$i++) {
#    $attr{$attrname[$i]}=$attrval[$i];
#  }  
#  return %attr;
#}


#=item %attr = getStepAttr($job,$step)

#=cut

#sub getStepAttr {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  local @attrname;
#  local @attrval;
#  local %attr;
#  local $i;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'ATTR');
#  @attrname=@{$genesis->{doinfo}{gATTRname}};
#  @attrval=@{$genesis->{doinfo}{gATTRval}};
#  for ($i=0;$i<=$#attrname;$i++) {
#    $attr{$attrname[$i]}=$attrval[$i];
#  }  
#  return %attr;
#}

#=item %attr = getLayerAttr($job)

#=cut

#sub getLayerAttr {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  local ($layer) = shift;
#  local @attrname;
#  local @attrval;
#  local %attr;
#  local $i;

#  $genesis->INFO('entity_type'=>'layer',
#                 'entity_path'=>"$job/$step/$layer",
#                 'data_type'=>'ATTR');
#  @attrname=@{$genesis->{doinfo}{gATTRname}};
#  @attrval=@{$genesis->{doinfo}{gATTRval}};
#  for ($i=0;$i<=$#attrname;$i++) {
#    $attr{$attrname[$i]}=$attrval[$i];
#  }  
#  return %attr;
#}


#=item (xDatum, yDatum)= @stepDatum = getStepDatum($job,$step)

#=cut

#sub getStepDatum {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'DATUM');
#  return ($genesis->{doinfo}{gDATUMx},$genesis->{doinfo}{gDATUMy});
#}


#=item (xmin, ymin, xmax, ymax) = @stepLimits = getStepLimits($job,$step)

#=cut

#sub getStepLimits {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  local (@stepLimits);

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'LIMITS');
#  @stepLimits = ($genesis->{doinfo}{gLIMITSxmin}, 
#		 $genesis->{doinfo}{gLIMITSymin},
#		 $genesis->{doinfo}{gLIMITSxmax},
#		 $genesis->{doinfo}{gLIMITSymax});
#  return @stepLimits;
#}



#=item (xmin, ymin, xmax, ymax) = @profileLimits = getProfileLimits($job,$step)

#=cut

#sub getProfileLimits {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'PROF_LIMITS');
#  return ($genesis->{doinfo}{gPROF_LIMITSxmin}, 
#          $genesis->{doinfo}{gPROF_LIMITSymin},
#          $genesis->{doinfo}{gPROF_LIMITSxmax},
#          $genesis->{doinfo}{gPROF_LIMITSymax});
#}


#=item (xmin, ymin, xmax, ymax) = @SRLimits = getSRLimits($job,$step)

#=cut

#sub getSRLimits {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'SR_LIMITS');
#  return ($genesis->{doinfo}{gSR_LIMITSxmin},
#          $genesis->{doinfo}{gSR_LIMITSymin},
#          $genesis->{doinfo}{gSR_LIMITSxmax},
#          $genesis->{doinfo}{gSR_LIMITSymax});
#}


#=item ($xmin, $ymin, $xmax, $ymax) = @activeArea = getActiveArea($job, $step)

#=cut

#sub getActiveArea {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'ACTIVE_AREA');  
#  return ($genesis->{doinfo}{gACTIVE_AREAxmin},
#          $genesis->{doinfo}{gACTIVE_AREAymin},
#          $genesis->{doinfo}{gACTIVE_AREAxmax},
#          $genesis->{doinfo}{gACTIVE_AREAymax});
#}


#=item (xsize, ysize) = @size = getStepSize($job,$step)

#=cut

#sub getStepSize {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'LIMITS');
#  return ($genesis->{doinfo}{gLIMITSxmax}-$genesis->{doinfo}{gLIMITSxmin}, 
#          $genesis->{doinfo}{gLIMITSymax}-$genesis->{doinfo}{gLIMITSymin});
#}


#=item (xsize, ysize) = @activeStepSize = getActiveStepSize($job,$step)

#=cut

#sub getActiveStepSize {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->INFO('entity_type'=>'step',
#                 'entity_path'=>"$job/$step",
#                 'data_type'=>'ACTIVE_AREA');  
#  return ($genesis->{doinfo}{gACTIVE_AREAxmax}-$genesis->{doinfo}{gACTIVE_AREAxmin},
#          $genesis->{doinfo}{gACTIVE_AREAymax}-$genesis->{doinfo}{gACTIVE_AREAymin});
#} 


#=item status = checkoutJob($job)

#=pod 
#return 1 if successful
#return 0 if error and $genesis->{STATUS}

#=cut

#sub checkoutJob {
#  local ($genesis) = shift;
#  local ($job) = shift;

#  $genesis->VOF;
#  $genesis->COM('check_inout','mode'=>'out',
#                              'type'=>'job',
#                              'job'=>"$job");
#  $genesis->VON;
#  return (1) unless $genesis->{STATUS};
#  return (0);
#}


#=item status = openJob($job)

#=cut

#sub openJob {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  $genesis->VOF;
#  $genesis->COM('open_job', 'job'=>"$job");
#  $genesis->VON;
#  return (1) unless $genesis->{STATUS};
#  return (0);
#}


#=item group = openStep($job,$step)

#=pod return 0 if error

#=cut

#sub openStep {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;

#  $genesis->COM('open_entity','job'=>"$job",
#                              'type'=>'step',
#                              'name'=>"$step",
#                              'iconic'=>'no');
#  return ($genesis->{COMANS}) unless $genesis->{STATUS};
#  return 0;
#}


#=item boolean setUnits(inch|mm)

#=cut

#sub setUnits {
#  local ($genesis) = shift;
#  local ($units) = shift;
  
#  return (1) if ($units != /inch|mm/i);
#  $genesis->COM('units','type'=>"$units");
#  return (0);
#}

#=item ($type,$xstart,$ystart,$xend,$yend,$symbol,$polarity, $decode)[] = getFeatureInfoByAttr($job,$step,$layer,$attribute)

#=cut

#sub getFeatureInfoByAttr {
#  local ($genesis) = shift;
#  local ($job) = shift;
#  local ($step) = shift;
#  local ($layer) = shift;
#  local ($attribute) = shift;
#  local ($group);
#  local (@features);

#  $group = $genesis->openStep($job,$step);
#  $genesis->selectFeatureByAttr($job,$step,$layer,$attribute);

#  $cshfile=$genesis->INFO('entity_type'=>'layer',
#                          'entity_path'=>"$job/$step/$layer",
#                          'data_type'=>'FEATURES',
#                          'options'=>'select',
#                          'parse'=>'no');
#  open(CSHFILE,"$cshfile");
#  while($line=<CSHFILE>) {
#    next unless ($line =~ /$attribute/);
#    ($type, $xstart, $ystart, $xend, $yend, $symbol, $pol, $decode, $attr)= ($line =~ /(\w+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\w\d.]+)\s+([\w])\s+([\d.]+)\s+;.(.*)$/);

#    push(@features,{'type'=>$type,
#                    'xstart'=>$xstart,
#                    'ystart'=>$ystart,
#                    'xend'=>$xend,
#                    'yend'=>$yend,
#                    'symbol'=>$symbol,
#                    'polarity'=>$pol,
#                    'decode'=>$decode,
#                    'attributes'=>[split /,/,$attr]}); 
#  }
#  close(CSHFILE);
#  return @features;
#}


##=item printFile($file);

##=cut

##sub printFile {
##  local ($genesis) = shift;
##  local ($filename) = shift;

##  open (FILE, "$filename") or warn "can not open file $filename";
##  while (<FILE>) {
##    print;
##  }
##  close (FILE);
##}

##
## setGroup($group)
##
#sub setGroup {
#  local ($genesis) = shift;
#  local ($group) = shift;
  
#  $genesis->AUX('set_group','group'=>"$group");
#}

##
##  createLayer($layer,$context,$type,$polarity,$ins_layer);
##

#sub createLayer{
#  local ($genesis) = shift;
#  local ($layer) = shift;
#  local ($context) = shift;
#  local ($type) = shift;
#  local ($polarity) = shift;
#  local ($ins_layer) = shift;

#  $context='misc' unless $context;
#  $type='signal' unless $type;
#  $polarity='positive' unless $polarity;
#  $ins_layer='' unless $ins_layer;

#  $genesis->COM('create_layer','layer'=>$layer,
#                               'context'=>$context,
#                               'type'=>$type,
#                               'polarity'=>$polarity,
#                               'ins_layer'=>$ins_layer);
#}

##
## copyLayer($source_job,$source_step,$source_layer,$dest_layer,$mode,$invert)
##

#sub copyLayer {
#  local ($genesis) = shift;
#  local ($source_job) = shift;
#  local ($source_step) = shift;
#  local ($source_layer) = shift;
#  local ($destination_layer) = shift;
#  local ($mode) = shift;
#  local ($invert) = shift;

#  $mode='append' unless $mode;
#  $invert='no' unless $invert;

#  $genesis->COM('copy_layer','source_job'=>"$source_job",
#                             'source_step'=>"$source_step",
#                             'source_layer'=>"$source_layer",
#                             'dest'=>'layer_name',
#                             'dest_layer'=>"$destination_layer",
#                             'mode'=>"$mode",
#                             'invert'=>"$invert");
#}

##
## Parse csh file and return a hash with the return values in $genesis->{parse_csh}
## $genesis->parse_csh($csh_file)
##

##sub parse_csh {
##  local ($genesis) = shift;
##  local $csh_file  = shift;
  
##  open (CSH_FILE,  "$csh_file") or warn "Cannot open info file - $csh_file: $!\n";
##  while (<CSH_FILE>) {
##    chomp;
##    next if /^\s*$/; # ignore blank lines 
##    ($var,$value) = /set\s+(\S+)\s*=\s*(.*)\s*/; # extract the name and value 
    
##    $value =~ s/^\s*|\s*$//g; # remove leading and trailing spaces from the value
##    $value =~ s/\cM/<^M>/g;   # change ^M temporarily to something else
##    # This happens mainly in giSEP, and shellwords makes it disappear
    
##    @value = shellwords($_);			   
    
##    # Deal with an csh array differently from a csh scalar
##    if ($value =~ /^\(/ ) {
##      $value =~ s/^\(|\)$//g; # remove leading and trailing () from the value
##      @words = shellwords($value); # This is a standard part of the Perl library
##      grep {s/\Q<^M>/\cM/g} @words;
###      print "$var = @words\n";
##      $genesis->{parsed_csh}{$var} = [@words];
##    } else {
##      $value =~ s/\Q<^M>/\cM/g;
##      $value =~ s/^'|'$//g;
      
##      $genesis->{parsed_csh}{$var} = $value;
##    }
##  }
##  close (CSH_FILE);
###  unlink ($csh_file);
##}

##
## $genesis->selectFeatureByAttr($job,$step,$layer,$attr)
##
#sub selectFeatureByAttr {
#  local $genesis = shift;
#  local $job = shift;
#  local $step = shift;
#  local $layer = shift;
#  local $attr = shift;
#  $genesis->COM(display_layer,name=>"$layer",
#                              display=>'yes');
#  $genesis->COM(work_layer,name=>"$layer");
#  $genesis->COM(filter_reset,filter_name=>'script');
#  $genesis->COM(filter_atr_set,filter_name=>'script',condition=>'yes',attribute=>$attr);
#  $genesis->COM(filter_area_strt);
#  $genesis->COM(filter_area_end,layer=>"$layer",
#                                filter_name=>'script',
#                                operation=>'select',
#                                area_type=>'none',
#                                inside_area=>'no',
#                                intersect_area=>'no',
#                                lines_only=>'no',
#                                ovals_only=>'no',
#                                min_len=>'0',
#                                max_len=>'0',
#                                min_angle=>'0',
#                                max_angle=>'0');
#}


#sub getCDR14Stages {
#  local @cdr14stages;
#  local $cdr14_ini = '/opt/genesis/sys/hooks/cdr14.ini';
                                
#  open (CDR14INI, "$cdr14_ini") or die "can not open $cdr14_ini";
#  while ($line = <CDR14INI>) {
#    last if $line =~ /\[Stage-Parameters\]/;
#  }
#  while ($line = <CDR14INI>) {
#    last if $line =~ /\[Toolset-Parameters\]/;
#    if ($line =~ /\[(\w+)\]/) {
#      push (@cdr14stages,$1);
#    }
#  }
#  close(CDR14INI);
#  return @cdr14stages;
#}

#sub deleteJob {
#  local $genesis = shift;
#  local $job = shift;

#  $genesis->COM(delete_entity,type=>'job',
#                              name=>$job);
#}

#sub deleteStep {
#  local $genesis = shift;
#  local $job = shift;
#  local $step = shift;

#  $genesis->COM(delete_entity,type=>'step',
#                              job=>"$job",
#                              step=>"$step");
#}
#sub createJob {
#  local $genesis = shift;
#  local $job = shift;
#  local $db = shift;
  
#  $db = 'genesis' unless defined $db;

#  $genesis->COM(create_entity,type=>'job',
#                              name=>"$job",
#                              db=>"$db");
#}

#=pod
##boolean createStep($job,$step[,$db]);
##if the database parameter is omitted $db='genesis' is taken as a default
##return values:
##0 : Step could not be created
##1 : 

#=cut
#sub createStep {
#  local $genesis = shift;
#  local $job = shift;
#  local $step = shift;
#  local $db = shift;

#  $db = 'genesis' unless defined $db;
#  $genesis->COM(create_entity,type=>'step',
#                              name=>"$step",
#                              job=>"$job",
#                              db=>"$db");
#}

##sub inputJob {
##  local $genesis = shift;
##  local $job = shift;
##  local $step = shift;
##  local $path = shift;
##  local %params = %{shift @_};
 
##  $nf_comp = '0';
##  $nf_comp = $params{nf_comp} if defined $params{nf_comp};
##  $multiplier = '1';
##  $multiplier = $params{multiplier} if defined $params{multiplier};
##  $break_sr = 'no'; 
##  $break_sr = 'yes' if $params{break_sr} eq 'yes';
##  $signed_coords = 'no';
##  $signed_coords = 'yes' if $params{signed_coords} = 'yes';
 
##  $tmp = $ENV{GENESIS_TMP};
##  $tmp = '/tmp' unless defined $ENV{GENESIS_TMP};

##  $genesis->COM(input_identify,path=>"$path",
##                               job=>$job,
##                               script_path=>"${tmp}/inp_identify$$");
##  $genesis->parse_csh("${tmp}/inp_identify$$");
##  unlink("${tmp}/inp_identify$$");
##  $genesis->COM(input_manual_reset);
##  $i=0;
##  foreach (@{$genesis->{parsed_csh}{giPATH}}   ) {

##    if ($genesis->{parsed_csh}{giFORMAT}[$i] !~ /\w+/) {
##      $i++;
##      next;
##    }
##    if ($genesis->{parsed_csh}{giTYPE}[$i] eq 'file' ) {
##      $genesis->COM(input_manual_set,path=>$genesis->{parsed_csh}{giPATH}[$i],
##		                     job=>$job,
##		                     step=>$step,
##		                     format=>$genesis->{parsed_csh}{giFORMAT}[$i],
##                                     data_type=>$genesis->{parsed_csh}{giDATA_TYPE}[$i],
##		                     units=>$genesis->{parsed_csh}{giUNITS}[$i],
##		                     coordinates=>$genesis->{parsed_csh}{giCOORDS}[$i],
##                                     zeroes=>$genesis->{parsed_csh}{giZEROES}[$i],
##		                     nf1=>$genesis->{parsed_csh}{giNF1}[$i],
##		                     nf2=>$genesis->{parsed_csh}{giNF2}[$i],
##		                     decimal=>$genesis->{parsed_csh}{giDECIMAL}[$i],
##		                     separator=>$genesis->{parsed_csh}{giSEP}[$i],
##		                     layer=>$genesis->{parsed_csh}{giLAYER}[$i],
##		                     wheel=>$genesis->{parsed_csh}{giWHEEL}[$i],
##		                     wheel_template=>$genesis->{parsed_csh}{giWHEELTMP}[$i],
##		                     nf_comp=>$nf_comp,
##		                     multiplier=>$multiplier,
##		                     signed_coords=>$signed_coords,
##		                     break_sr=>$break_sr);
##    }
##    $i++;
##  }                             
##  $genesis->COM(input_manual);
##}

#sub getDesignlayers {
#  local $genesis = shift;
#  local $job = shift;
#  local @design_layers;
#  my $i;

#  $genesis->INFO(entity_type=>'matrix',entity_path=>"$job/matrix");
#  $i = 0;
#  while ($i <= $genesis->{doinfo}{gNUM_ROWS}) {
#    if ($genesis->{doinfo}{gROWcontext}[$i] eq 'board' &&
#        $genesis->{doinfo}{gROWlayer_type}[$i] =~ /(signal|mixed|power_ground)/) {
#      push (@design_layers, $genesis->{doinfo}{gROWname}[$i]);
#   }
#    $i++;
#  }
#  return @design_layers;
#}

##########################################################
## cdr14setup(%setup_params)
##########################################################

#sub cdr14setup {
#  local $genesis = shift;
#  %cdr_params = %{shift @_};
   
#  $cdr_params{INSPECT}{margin_x} = '0' unless defined $cdr_params{INSPECT}{margin_x};
#  $cdr_params{INSPECT}{margin_y} = '0' unless defined $cdr_params{INSPECT}{margin_y};
#  $cdr_params{CDR_SET} = 'cdr14' unless defined $cdr_params{CDR_SET};

#  $genesis->COM(cdr_display_layer,name=>$cdr_params{LAYER},
#	                          type=>'physical',
#	                          display=>'yes');
#  $genesis->COM(cdr_work_layer,set_name=>$cdr_params{CDR_SET},
#	                       layer=>$cdr_params{LAYER});
##
## define inspection area
##

#  $genesis->COM(cdr_set_area,mode=>'manual',
#	                     margin_x=>$cdr_params{INSPECT}{margin_x},
#	                     margin_y=>$cdr_params{INSPECT}{margin_Y},
#	                     x1=>"$cdr_params{INSPECT}{xmin}",
#                             x2=>"$cdr_params{INSPECT}{xmax}",
#	                     y1=>"$cdr_params{INSPECT}{ymin}",
#	                     y2=>"$cdr_params{INSPECT}{ymax}");

##
## define exclusion zones
##

#  $i = 1;
#  while (defined $cdr_params{ZONE}[$i]) {
#    ($x,$y) = split /,/,$cdr_params{ZONE}[$i][0];
#    $genesis->COM(cdr_zone_poly_start,duplicate=>'no',
#	                              x=>$x,
#	                              y=>$y,
#                                      type=>'all');
#    $j=0;   
#    while (defined $cdr_params{ZONE}[$i][$j]) {
#      ($x,$y) = split /,/,$cdr_params{ZONE}[$i][$j];
#      $genesis->COM(cdr_zone_poly_add_seg,x=>$x,
#	                                  y=>$y);
#      $j++;
#    } # end of while (defined $cdr_params{ZONE}[$i][$j]
#    $genesis->COM(cdr_zone_poly_close);
#    $i++;
#  } # end of while (defined $cdr_params{ZONE}[$i])
  
##
##  Set line and space values
##
#  $cdr_params{NLINE}=0 unless defined $cdr_params{NLINE};
#  $cdr_params{MLINE}=0 unless defined $cdr_params{MLINE};
  
#  $genesis->COM(cdr_line_width,nom_width=>$cdr_params{NLINE},
#	                       min_width=>$cdr_params{MLINE});

#  $cdr_params{NSPACE}=0 unless defined $cdr_params{NSPACE};
#  $cdr_params{MSPACE}=0 unless defined $cdr_params{MSPASE};
  
#  $genesis->COM(cdr_spacing,nom_space=>$cdr_params{NSPACE},
#	                    min_space=>$cdr_params{MSPACE});

##
## define working stages
##
############################################################# ATTENTION #####################################
#  @working_stages = @{$parsed_aoiprog{'WORKING_STAGES'}};
#  @cdr14_ini_stages = @{$parsed_cdr14_ini{STAGES}};
  
## define a array that does the translation from the index number
## in the cdr14.ini file to the stage name. 
## needed for the assignment of the class file

#  foreach $cdr14_stage (@cdr14_ini_stages) {
#    push @classfiles,$cdr_params{CLASS}{"$cdr14_stage"};  
#  }

#  $genesis->COM(cdr_work_stage,stage1=>$working_stages[0],
#	                       stage2=>$working_stages[1],
#	                       stage3=>$working_stages[2],
#	                       stage4=>$working_stages[3],
#	                       stage5=>$working_stages[4],
#	                       stage6=>$working_stages[5],
#	                       stage7=>$working_stages[6],
#	                       stage8=>$working_stages[7],
#	                       stage9=>$working_stages[8],
#	                       stage10=>$working_stages[9]);
##
## define class files
##

#  $genesis->COM(cdr_stage_classes,stage1=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage2=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage3=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage4=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage5=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage6=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage7=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage8=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage9=>shift @classfiles);
#  $genesis->COM(cdr_stage_classes,stage10=>shift @classfiles);

## start section still to debug
##$f->COM(cdr_stage_classes,stage1=>shift @classfiles,
##	                  stage2=>shift @classfiles,
##	                  stage3=>shift @classfiles,
##	                  stage4=>shift @classfiles,
##	                  stage5=>shift @classfiles,
##	                  stage6=>shift @classfiles,
##	                  stage7=>shift @classfiles,
##	                  stage8=>shift @classfiles,
##	                  stage9=>shift @classfiles,
##	                  stage10=>shift @classfiles);

##$f->COM(cdr_stage_classes,stage1=>'hello',stage2=>'',stage3=>'',stage4=>'',stage5=>'test');
##$f->COM(cdr_stage_classes,stage5=>'test',stage1=>'asdf');
##$f->COM(cdr_stage_classes,stage5=>'test');
## end section still to debug

##
## define etch values and drill layers
##

#  foreach $stage (@working_stages) {
#    $cdr_params{ETCH}{"$stage"} = 0 unless defined $cdr_params{ETCH}{"$stage"};
#    $cdr_params{CLASS}{"$stage"} = '' unless defined  $cdr_params{'CLASS'}{"$stage"};
#    # define etch value
#    $genesis->COM(cdr_stage_etch,etch=>$cdr_params{ETCH}{"$stage"},
#	                         stage1=>"$stage",
#	                         use_config=>'no');

#    # define drill layers
#    if ($cdr_params{DRILL_LAYER}{"$stage"}) {
#      $genesis->COM(cdr_drill_layers,drill_layers=>$cdr_params{DRILL_LAYER}{"$stage"},
#	                             stage1=>$stage);
#    }

#    # define alignment targets
#    $genesis->COM(cdr_add_align_target_no_snap,x=>$cdr_params{CT}{"$stage"}{x1},
#	                                       y=>$cdr_params{CT}{"$stage"}{y1},
#	                                       stage1=>$stage);

#    $genesis->COM(cdr_add_align_target_no_snap,x=>$cdr_params{CT}{"$stage"}{x2},
#	                                       y=>$cdr_params{CT}{"$stage"}{y2},
#	                                       stage1=>$stage);
#    #align panel on table

#    $genesis->COM(cdr_manual_align,offset_x=>$cdr_params{TT}{$stage}{offset_x},
#	                           offset_y=>$cdr_params{TT}{$stage}{offset_y},
#	                           rotate=>$cdr_params{TT}{$stage}{'rotation'},
	  
#                         mirror=>$cdr_params{TT}{$stage}{'mirror'},
#	                           polarity=>$cdr_params{TT}{$stage}{'polarity'},
#	                           stage1=>"$stage",
#	                           create_toolset=>'no',
#	                           toolset_num=>'0');

#  } # end of foreach $stage (@working_stages)

#  # undisplay all layers

#  $genesis->COM(cdr_display_layer,name=>$cdr_params{LAYER},
#	                          type=>'physical',
#	                          display=>'no');
#  $genesis->COM(cdr_display_layer,name=>$cdr_params{LAYER},
#	                          type=>'area',
#	                          display=>'no');
#  $genesis->COM(cdr_display_layer,name=>$cdr_params{LAYER},
#	                          type=>'target',
#	                          display=>'no');

#}




##################################
## sub createAOIOutput
##################################
#=pod
#This subroutine gets a list of hashes passed on the command line and will create an AOIOutput for each set of parameters that are specified inside the hashes. The hash "must" only contain one field which is
#$params{LAYER} which will specify the layer which will be used for output useing the following default parameters.

#The default values that are assumed if you do not specify any parameter
# $params{cdr_set} = 'cdr14'
# $params{output_aoiprog} = 'yes'
# $params{output_aoiimg} = 'yes'
# $params{output_path} = '/id/cdrp'
# $params{output_units} = 'inch'
# $params{output_scale_x} = '1'
# $params{output_scale_y} = '1'
# $params{output_anchor_mode} = 'zero'
# $params{output_anchor_x} = '0'
# $params{output_anchor_y} = '0'
# $params{output_pcb_rpcb} = 'no'
# $params{output_bound_inspect} = 'no'
# $params{output_target_machine} = 'pc14'
# $params{output_break_surf} = 'yes'
# $params{output_break_arc} = 'yes'
# $params{output_break_sr} = 'no'
# $params{output_break_fsyms} = 'no'
# $params{output_min_brush} = '1'

#=cut
####################################

#sub createAOIOutput {
#  my ($output_cdr_set, $output_aoiimg, $output_aoiprog, $output_path, $output_scale_x, $output_scale_y);
#  my ($output_anchor_mode, $output_anchor_x, $output_anchor_y);
#  my ($output_pcb_rpcb, $output_bound_inspect, $output_target_machine);
#  my ($output_break_surf, $output_break_arc, $output_break_sr, $output_break_fsyms, $output_min_brush);
#  my ($output_layer);

#  while (defined (%output_params = %{shift @_})) {
#    $output_layer = $output_params{LAYER};
 
#    # define default values if parameters are ommitted.
#    $output_cdr_set = 'cdr14';
#    $output_cdr_set = $output_params{cdr_set} if defined $output_params{cdr_set};
#    $output_aoiimg = 'yes';
#    $output_aoiimg = $output_params{output_aoiimg} if defined $output_params{output_aoiimg};
#    $output_aoiprog = 'yes';
#    $output_aoiprog = $output_params{output_aoiprog} if defined $output_params{output_aoiprog};
#    $output_units = 'inch';
#    $output_units = $output_params{output_units} if defined $output_params{output_units};
#    $output_path = '/id/cdrp';
#    $output_path = $output_params{output_path} if defined $output_params{output_path};
#    $output_scale_x = '1';
#    $output_scale_x = $output_params{output_scale_x} if defined $output_params{output_scale_x};
#    $output_scale_y = '1';
#    $output_scale_y = $output_params{output_scale_y} if defined $output_params{output_scale_y};
#    $output_anchor_mode = 'zero';
#    $output_anchor_mode = $output_params{output_anchor_mode} if defined $output_params{output_anchor_mode};
#    $output_anchor_x = '0';
#    $output_anchor_x = $output_params{output_anchor_x} if defined $output_params{output_anchor_x};
#    $output_anchor_y = '0';
#    $output_anchor_y = $output_params{output_anchor_y} if defined $output_params{output_anchor_y};
#    $output_pcb_rpcb = 'no';
#    $output_pcb_rpcb = $output_params{output_pcb_rpcb} if defined $output_params{output_pcb_rpcb};
#    $output_bound_inspect = 'no';
#    $output_bound_inspect = $output_params{output_bound_inspect} if defined $output_params{output_bound_inspect};
#    $output_target_machine = 'pc14';
#    $output_target_machine = $output_params{output_target_machine} if defined $output_params{output_target_machine};
#    $output_break_surf = 'yes';
#    $output_break_surf = $output_params{output_break_surf} if defined $output_params{output_break_surf};
#    $output_break_arc = 'yes';
#    $output_break_arc = $output_params{output_break_arc} if defined $output_params{output_break_arc};
#    $output_break_sr = 'no';
#    $output_break_sr = $output_params{output_break_sr} if defined $output_params{output_break_sr};
#    $output_break_fsyms = 'no';
#    $output_break_fsyms = $output_params{output_break_fsyms} if defined $output_params{output_break_fsyms};
#    $output_min_brush = '1';
#    $output_min_brush = $output_params{output_min_brush} if defined $output_params{output_min_brush};



#    $f->COM(cdr_display_layer,name=>$output_layer,
#	                      type=>'physical',
#	                      display=>'yes');

#    $f->COM(cdr_work_layer,set_name=>$output_cdr_set,
#	                   layer=>$output_layer);

#    $f->COM(cdr_output,aoiimg=>$output_aoiimg,
#                       aoiprog=>$output_aoiprog,
#	               units=>$output_units,
#	               path=>$output_path,
#	               scale_x=>$output_scale_x,
#	               scale_y=>$output_scale_y,
#	               anchor_mode=>$output_anchor_mode,
#	               anchor_x=>$output_anchor_x,
#	               anchor_y=>$output_anchor_y,
#	               pcb_rpcb=>$output_pcb_rpcb,
#	               bound_inspect=>$output_bound_inspect,
#	               target_machine=>$output_target_machine,
#	               break_surf=>$output_break_surf,
#	               break_arc=>$output_break_arc,
#	               break_sr=>$output_break_sr,
#	               break_fsyms=>$output_fsysm,
#	               min_brush=>$output_min_brush);

#    $f->COM(cdr_display_layer,name=>$output_layer,
#	                      type=>'physical',
#	                      display=>'no');
#  } # end of while (defined %output_params = %{shift @_})
#} # end of sub createAOIOutput



###################################
## sub parse_aoiprog
###################################

#sub parse_aoiprog {
#  local $aoiprog_file = shift;
#  my $xmin,$ymin,$xmax,$ymax;
#  my $param, $value;
#  my %parse_result;
#  my $zone_nr;
#  my $x,$y;
#  my $unit_div;
#  my @working_stages;

#  local ($job,$layer) = $aoiprog_filename =~ /.+\/(.+)\.(.+)$/;
#  $parse_result{'JOB'} = $job;
#  $parse_result{'LAYER'} = $layer;

#  open (AOIPROG, "<$aoiprog_file") or die "can not open $aoiprog_file";
#  while (<AOIPROG>) {
#    # first split the line at the "=" sign
#    next if /(^;)/; # skip comment lines
#    next if /^$/;   # skip empty lines
#    ($param,$value) = split /=/;
#    $param =~ s/^\s*|\s*$//g; # remove leading and trailing spaces from the parameter name
#    $value =~ s/^\s*|\s*$//g; # remove leading and trailing spaces from the value
   
#    if ($param =~ /^UNIT/) {
#      $unit_div = 1000 if $value =~ /MIL/; 
#      $unit_div = 25.4 if $value =~ /MM/; 
#      $parse_result{UNITS}='inch';
#      next;
#    }
    
#    if ($param =~ /^MLINE/) {
#      $parse_result{'MLINE'}=$value;
#      next;
#    }

#    if ($param =~ /^MSPACE/) {
#      $parse_result{'MSPACE'}=$value;
#      next;
#    }

#    if ($param =~ /^ETCH/) {
#      ($stage)= $param =~ /ETCH\s+\\(\w+)/;
#      $parse_result{'ETCH'}{"$stage"} = $value;
#      next;
#    }
    
#    if ($param =~ /^CLASS/) {
#      ($stage) = $param =~ /CLASS\s+\\(\w+)/;
#      ($class_file,$drill_layer) = split /:/,$value;
#      $parse_result{'CLASS'}{"$stage"} = $class_file;
#      $parse_result{'DRILL_LAYER'}{"$stage"} = $drill_layer if (defined $drill_layer);
#      push(@working_stages,$stage);
#      next;
#    }
  
#    if ($param =~ /^CT/) {
#      ($stage) = $param =~ /CT\s+\\(\w+)/;   
#      # split a line like 1234.2:1234.21:1:12.12,12345.334:22234.34:1:33.343
#      if (($x1,$y1,$shape1,$size1a,$size1add,$x2,$y2,$shape2,$size2a,$size2add) = /(\d+\.\d+)\s*:\s*(\d+\.\d+)\s*:\s*(\d+)\s*:\s*(\d+\.\d+)\s*(.*)?,\s*(\d+\.\d+)\s*:\s*(\d+\.\d+)\s*:\s*(\d+)\s*:\s*(\d+\.\d+)\s*(.*)?$/) {
#        $x1 /= $unit_div;
#        $y1 /= $unit_div;
#        $x2 /= $unit_div;
#        $y2 /= $unit_div;

#        $parse_result{CT}{$stage}={x1=>$x1,
#			           y1=>$y1,
#                		   shape1=>$shape1,
#			           size1a=>$size1a,
#				   size1b=>$size1b,
#				   size1c=>$size1c,
#			           x2=>$x2,
#			           y2=>$y2,
#		  	           shape2=>$shape2,
#	  		           size2a=>$size2a,
#				   size2b=>$size2b,
#				   size2c=>$size2c};
#        next;
#      }
#    }    

#    if ($param =~ /^TT/) {
#      ($stage) = $param =~ /TT\s+\\(\w+)/;   
#      if (($x1,$y1,$pol1,$x2,$y2,$pol2,$tmp,$mirror_information) = /(\d+\.\d+)\s*:\s*(\d+\.\d+)\s*:\s*(\d+)\s*,\s*(\d+\.\d+)\s*:\s*(\d+\.\d+)\s*:\s*(\d+)\s*(,\s*(.+))?$/) {
#        $x1 /= $unit_div;
#        $y1 /= $unit_div;
#        $x2 /= $unit_div;
#        $y2 /= $unit_div;
## extract mirroring information
#        @mirror_params = split /,/,$mirror_information;
#	$rotation = 0;
#	$mirror = 'no';
#	$polarity = 'pos';
#	foreach $mirror_param (@mirror_params) {
#	  $rotation =  90 if $mirror_param =~ /RCCW270/;
#	  $rotation = 180 if $mirror_param =~ /RCCW180/;
#	  $rotation = 270 if $mirror_param =~ /RCCW90/;
#	  $mirror = 'yes' if $mirror_param =~ /H/;
#	  $polarity = 'neg' if $mirror_param =~ /NEGATIVE/;
#	}

#	if ($mirror eq 'no' && $rotation == 0 ) {
#	  $offset_x = $x1 - $parse_result{CT}{$stage}{x1};
#	  $offset_y = $y1 - $parse_result{CT}{$stage}{y1};
#	  print "mirror mode 1\n";
#	} 
#	if ($mirror eq 'no' && $rotation == 90) {
#	  $offset_x = $x1 + $parse_result{CT}{$stage}{y1};
#	  $offset_y = $y1 - $parse_result{CT}{$stage}{x1};
#	  print "mirror mode 2\n";
#	} 
#	if ($mirror eq 'no' && $rotation == 180) {
#	  $offset_x = $x1 + $parse_result{CT}{$stage}{x1};
#	  $offset_y = $y1 + $parse_result{CT}{$stage}{y1};
#	  print "mirror mode 3\n";
#	}
#	if ($mirror eq 'no' && $rotation == 270) {
#	  $offset_x = $x1 - $parse_result{CT}{$stage}{y1};
#	  $offset_y = $y1 + $parse_result{CT}{$stage}{x1};
#	  print "mirror mode 4\n";
#	}
#	if ($mirror eq 'yes' && $rotation == 0) {
#	  $offset_x = $x1 + $parse_result{CT}{$stage}{x1};
#	  $offset_y = $y1 - $parse_result{CT}{$stage}{y1};
#	  print "mirror mode 5\n";
#	}
#	if ($mirror eq 'yes' && $rotation == 90) {
#	  $offset_x = $x1 + $parse_result{CT}{$stage}{y1};
#	  $offset_y = $y1 + $parse_result{CT}{$stage}{x1};
#	  print "mirror mode 6\n";
#	}
#	if ($mirror eq 'yes' && $rotation == 180) {
#	  $offset_x = $x1 - $parse_result{CT}{$stage}{x1};
#	  $offset_y = $y1 + $parse_result{CT}{$stage}{y1};
#	  print "mirror mode 7\n";
#	}
#	if ($mirror eq 'yes' && $rotation == 270) {
#	  $offset_x = $x1 - $parse_result{CT}{$stage}{y1};
#	  $offset_y = $y1 - $parse_result{CT}{$stage}{x1};
#	  print "mirror mode 8\n";
#	}
#	print "offset_x = $offset_x\n";
#	print "offset_y = $offset_y\n";

#        $parse_result{TT}{$stage}={x1=>$x1,
#	  		           y1=>$y1,
#                	           pol1=>$pol1,
#			           x2=>$x2,
#		                   y2=>$y2,
#		                   pol2=>$pol2,
#		                   rotation=>$rotation,
#			           mirror=>$mirror,
#			           polarity=>$polarity,
#			           offset_x=>$offset_x,
#			           offset_y=>$offset_y};
#        next;
#      }
#    }


#    if ($param =~ /^DIM/) {
#      ($xmin,$xmax,$ymin,$ymax) = ($value =~ /(\d+\.\d+)\s*,\s*(\d+\.\d+)\s*,\s*(\d+\.\d+)\s*,\s*(\d+\.\d+)/);
#      # convert units to inch
#      $xmin /= $unit_div;
#      $xmax /= $unit_div;
#      $ymin /= $unit_div;
#      $ymax /= $unit_div;
#      $parse_result{DIM}={xmin=>$xmin,
#			  ymin=>$ymin,
#			  xmax=>$xmax,
#			  ymax=>$ymax};
#    } # end of if $param =~ /DIM/

#    if ($param =~ /^INSPECT/) {
#      ($xmin,$xmax,$ymin,$ymax) = ($value =~ /(\d+\.\d+)\s*:\s*(\d+\.\d+)\s*,\s*(\d+\.\d+)\s*:\s*(\d+\.\d+)/);
#      # convert units to inch
#      $xmin /= $unit_div;
#      $xmax /= $unit_div;
#      $ymin /= $unit_div;
#      $ymax /= $unit_div;
#      $parse_result{INSPECT}={xmin=>$xmin,
#			      ymin=>$ymin,
#			      xmax=>$xmax,
#			      ymax=>$ymax};
#      next;
#    } # end of if $param =~ /INSPECT/
    
#    if (($zone_nr) = ($param =~ /^ZONE(\d+)/)) {
#      (@vertex) = ($value =~ /(\d+\.\d+:\d+\.\d+)+/g);
#      # replace ":" with ","
#      foreach (@vertex) {
#	($x,$y) = split /:/;
#	$x /= $unit_div;
#	$y /= $unit_div;
#	$_=join ',',$x,$y;
#      } #end of foreach (@vertex)
#      $parse_result{ZONE}[$zone_nr]=[@vertex];
#    } # end of if $param =~ /ZONE(\d+)/
#  } # end of while (<AOIPROG>)
#  close (AOIPROG);

#  @parse_result{'WORKING_STAGES'}=[@working_stages];
## make sure that minimum line and space are not bigger then the nominal values
#  $parse_result{MLINE} = $parse_result{NLINE} if $parse_result{NLINE} < $parse_result{MLINE};
#  $parse_result{MSPACE} = $parse_result{NSPACE} if $parse_result{NSPACE} < $parse_result{MSPACE};

#  return %parse_result;

#} # end of sub parse_aoiprog

#sub getJobLocation {
#  my $job = shift;
#  my $joblist = "$ENV{GENESIS_DIR}/share/joblist";
#  my ($dbname, $dblist, $path, $hostname);
#  open (JOBLIST,"$joblist") or die "can not open $joblist: $!\n";
#  while (<JOBLIST>) {
#    next unless /name\s*=\s*$job/i;
#    ($dbname) = (<JOBLIST> =~ /db\s*=\s*(\w+)/i);
#    last;
#  }
#  close (JOBLIST);
#  my $hostname = hostname();
#  my $dblist = "$ENV{GENESIS_DIR}/hosts/$hostname/dblist";
#  if (! -e $dblist) {
#    $dblist = "$ENV{GENESIS_DIR}/sys/dblist";
#  }

#  open (DBLIST, "$dblist") or die "can not open dblist file $db_list: $!\n";
#  while (<DBLIST>) {
#    next unless /name\s*=\s*$dbname/i;
#    ($path) = (<DBLIST> =~ /path\s*=\s*(.+)$/i);
#    last;
#  }
#  close (DBLIST);
#  if ($job =~ /^genesislib$/i) {
#    $path = $path . '/lib';
#  } else {
#    $path = $path . "/jobs/$job";
#  }
#  return $path;
#}

######################################################## panelization wizard ###################################################
#=pod
#$coord{$step}{'datum.x'}
#$coord{$step}{'datum.y'}
#$coord{$step}{'active_area_left.x'}
#$coord{$step}{'active_area_right.x'}
#$coord{$step}{'active_area_bot.y'}
#$coord{$step}{'active_area_top.y'}
#$coord{$step}{'pcb_area_left.x'}
#$coord{$step}{'pcb_area_right.x'}
#$coord{$step}{'pcb_area_top.x'}
#$coord{$step}{'pcb_area_bot.y'}
#$coord{$step}{'pnl_size.x'}
#$coord{$step}{'pnl_size.y'}
#$coord{$step}{'pcb_spacing.x'}
#$coord{$step}{'pcb_spacing.y'}
#$coord{$step}{'top_margin'}
#$coord{$step}{'bot_margin'}
#$coord{$step}{'left_margin'}
#$coord{$step}{'right_margin'}
#$coord{$step}{'pnl_center.x'}
#$coord{$step}{'pnl_center.y'}
#$coord{$step}{'pnl_left.x'}
#$coord{$step}{'pnl_right.x'}
#$coord{$step}{'nl_top.y'}
#$coord{$step}{'nl_bot.y'}
#=cut

#sub getCoordinates {
#  my $genesis = shift;
#  my $job = shift;
#  my $panel = shift;
#  my %coord;

#  @coord =$genesis->getActiveArea($job,$panel);
#  ($coord{$panel}{'active_area_left.x'},
#   $coord{$panel}{'active_area_bot.y'},
#   $coord{$panel}{'active_area_right.x'},
#   $coord{$panel}{'active_area_top.y'})=@coord;

# # @coord=$genesis->get  
  

#}


1;
