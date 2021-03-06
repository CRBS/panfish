package Panfish::SSHJobSubmitter;

use strict;
use English;
use warnings;

use Panfish::FileUtil;
use Panfish::PanfishConfig;
use Panfish::Logger;
use Panfish::FileJobDatabase;
use Panfish::JobState;
use Panfish::Job;
use Panfish::JobHashFactory;
use Panfish::PsubHashKeyGenerator;
=head1 SYNOPSIS
   
  Panfish::SSHJobSubmitter -- Submits actual jobs to clusters via ssh

=head1 DESCRIPTION

Submits the real jobs to clusters

=head1 METHODS

=head3 new

Creates new instance of Job object



=cut

sub new {
   my $class = shift;
   my $self = {
     Config         => shift,
     JobDb          => shift,
     Logger         => shift,
     FileUtil       => shift,
     SSHExecutor    => shift,
     JobHashFactory => shift,
     PathSorter     => shift
   };
 
   if (!defined($self->{Logger})){
       $self->{Logger} = Panfish::Logger->new();
   }

   my $blessedself = bless($self,$class);
   return $blessedself;
}

=head3 submitJobs

This method takes a cluster as a parameter and looks for jobs in 
batchedchummed state for that cluster.  The code then submits 
those jobs for processing and updates the state of the job to queued.

my $res = $batcher->submitJobs($cluster);

=cut

sub submitJobs {
    my $self = shift;
    my $cluster = shift;

    if (!defined($cluster)){
        $self->{Logger}->error("Cluster is not set");
        return "Cluster is not set";
    }

    my $res;
    
    # builds a hash where key is the psub file psub
    # and value is an array
    # of jobs which will be run by that psub file
    $self->{Logger}->debug("Looking for jobs in ".Panfish::JobState->BATCHEDANDCHUMMED().
                           " state for $cluster");
    my $jobHashByPsubFile = $self->_buildJobHash($cluster); 

    my $jobCount = 0;
    my @psubArray;
    my @keys = keys %$jobHashByPsubFile;
    my @sortedJobPaths = $self->{PathSorter}->sort(\@keys);    

    my $psubFile;
    # Iterate through hash and get list of psub files
    # put into array and pass to submitter
    foreach $psubFile (@sortedJobPaths){
        $jobCount +=  @{$jobHashByPsubFile->{$psubFile}};
        push(@psubArray,$psubFile);
    }
    
    if (@psubArray <= 0){
       $self->{Logger}->debug("No jobs found in ".Panfish::JobState->BATCHEDANDCHUMMED()." state for $cluster");
       return undef;
    }
    
    $self->{Logger}->debug("Found ".@psubArray." psub files containing ".
                          $jobCount." jobs for $cluster");
    
    # submit array of psub files
    my $submittedPsubFilesRef = $self->_submitPsubFilesViaSSH($cluster,\@psubArray);
    
    if (@{$submittedPsubFilesRef} <= 0){
        $self->{Logger}->warn("No psub files submitted hmmm... for $cluster");
        return undef;
    }

    $jobCount = 0;

    # update database with new status
    $self->{Logger}->debug("Submit succeeded updating database for $cluster");
 
    for (my $x = 0; $x < @{$submittedPsubFilesRef}; $x++){
        $psubFile = ${$submittedPsubFilesRef}[$x];
        $jobCount +=  @{$jobHashByPsubFile->{$psubFile}};
         for (my $x = 0; $x < @{$jobHashByPsubFile->{$psubFile}}; $x++){
           
             ${$jobHashByPsubFile->{$psubFile}}[$x]->setState(Panfish::JobState->QUEUED());
             $self->{JobDb}->update(${$jobHashByPsubFile->{$psubFile}}[$x]);
         } 
    }
    $self->{Logger}->info("Submitted ".
                          @{$submittedPsubFilesRef}.
                          " files containing ".$jobCount.
                          " jobs on $cluster");; 
    
    return undef;
}


#
# 
#
#
#
sub _submitPsubFilesViaSSH {
    my $self = shift;
    my $cluster = shift;
    my $psubFileArrayRef = shift;
    my $remoteBaseDir = $self->{Config}->getBaseDir($cluster);
    my $panfishSubmit = $self->{Config}->getPanfishSubmit($cluster);
    my @noJobs;
   

    #need to tell the command what cluster it is.  yeah its weird
    $panfishSubmit = $panfishSubmit." --stdintodb";
 
    # set to correct cluster
    $self->{SSHExecutor}->setCluster($cluster);   

    # build echo command to pipe to submitter program via ssh
    # need to get all keys and
    # invoke myqsubstdin.sh like this to minimize ssh activity
    # echo -e "1.qsub\\n2.qsub" | ssh gordon.sdsc.edu panfishsubmit
    my $echoArgs = "";
    for (my $x = 0; $x < @{$psubFileArrayRef};$x++){
       if ($echoArgs eq ""){
           $echoArgs = "$remoteBaseDir/${$psubFileArrayRef}[$x]";
       }
       else {
           $echoArgs .= "\\\\n$remoteBaseDir/${$psubFileArrayRef}[$x]";
       }
    }

    if ($echoArgs eq ""){
        $self->{Logger}->debug("No jobs to submit for $cluster");
        return \@noJobs;
    }


    my $exit;
    my $cmd;
    # if the remote base dir is unset assume a local cluster
    # submission and don't use ssh
    if ($remoteBaseDir eq ""){
       $self->{SSHExecutor}->disableSSH();
    }
    else {
       $self->{SSHExecutor}->enableSSH();
    }
   
    $self->{SSHExecutor}->setStandardInputCommand("/bin/echo -e \"$echoArgs\"");
        
    
    $exit = $self->{SSHExecutor}->executeCommand($panfishSubmit,60);
    if ($exit != 0){
        $self->{Logger}->error("Unable to run ".$self->{SSHExecutor}->getCommand().
                               "  : ".$self->{SSHExecutor}->getOutput());
         return \@noJobs;
    }
    $self->{Logger}->debug($self->{SSHExecutor}->getCommand()." : ".
                           $self->{SSHExecutor}->getOutput());
    return $psubFileArrayRef; 
}



#
# Builds a hash of jobs where the key is
# the directory where the psub file resides 
# and the value in the hash is
# all job objects who share that same directory
# for their psub files
#
# Ex:
#   $hash{"/home/foo/blah/1.1.psub"} => {Panfish::Job,Panfish::Job,Panfish::Job};
#
#
sub _buildJobHash {
    my $self = shift;
    my $cluster = shift;
    
    my @jobs = $self->{JobDb}->getJobsByClusterAndState($cluster,
                Panfish::JobState->BATCHEDANDCHUMMED());

    if (!@jobs){
        return undef;
    }

    my ($jobHashByPsub,$error) = $self->{JobHashFactory}->getJobHash(\@jobs);

    return $jobHashByPsub;
}


1;

__END__


=head1 AUTHOR

Panfish::SSHJobSubmitter is written by Christopher Churas<churas@ncmir.ucsd.edu>

=cut

