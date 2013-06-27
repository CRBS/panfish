package Panfish::JobSubmitter;

use strict;
use English;
use warnings;

use Panfish::PanfishConfig;
use Panfish::Logger;
use Panfish::FileJobDatabase;
use Panfish::JobState;
use Panfish::Job;
use Panfish::JobHashFactory;
use Panfish::SubmitCommand;


=head1 SYNOPSIS
   
  Panfish::JobSubmitter -- Submits jobs to scheduler 

=head1 DESCRIPTION

Submits jobs to scheduler

=head1 METHODS

=head3 new

Creates new instance of JobSubmitter



=cut

sub new {
   my $class = shift;
   my $self = {
     Config         => shift,
     JobDb          => shift,
     JobHashFactory => shift,
     SubmitCommand  => shift,
     CommandParser  => shift,
     PathSorter     => shift,
     Logger         => shift
   };

   my $blessedself = bless($self,$class);
   return $blessedself;
}

=head3 submitJobs

This method takes a cluster as a parameter and looks for jobs in 
submitted state for that cluster.  The code then submits 
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

    if ($self->{Config}->isClusterPartOfThisCluster($cluster) == 0){
       $self->{Logger}->warn("This should only be run on jobs for local cluster returning.");
       return undef;
    }

    my $runningJobCount = $self->{JobDb}->getNumberOfJobsInState($cluster,Panfish::JobState->QUEUED());
    $runningJobCount += $self->{JobDb}->getNumberOfJobsInState($cluster,Panfish::JobState->RUNNING());

    $self->{Logger}->debug("Max num jobs allowed: ".$self->{Config}->getMaximumNumberOfRunningJobs());
    if ($runningJobCount >= $self->{Config}->getMaximumNumberOfRunningJobs()){
        $self->{Logger}->debug("$runningJobCount jobs running which exceeds ".
                               $self->{Config}->getMaximumNumberOfRunningJobs()." not submitting any jobs");
        return undef;
    }
    
    $self->{JobHashFactory}->setCluster($cluster);
    my ($jobHashByPsub,$error) = $self->{JobHashFactory}->getJobHash();
   
    if (defined($error)){
        return $error;
    }

    my $jobCount = 0;
    my @keys = keys %$jobHashByPsub;
    my @sortedJobPaths = $self->{PathSorter}->sort(\@keys);
    my $psubFile;
    foreach $psubFile (@sortedJobPaths){
 
       if ($runningJobCount >= $self->{Config}->getMaximumNumberOfRunningJobs()){
           $self->{Logger}->debug("Reached maximum number of jobs that can be run on cluster $cluster");
           last;
       }

       # submit array of psub files 
       # TODO: move this method to a separate class
       my ($realJobId,$error) = $self->{SubmitCommand}->run($psubFile);
       if (defined($error) { 
           next; 
       }

       if (defined($realJobId)){
          $self->{Logger}->debug("Submit succeeded updating database");
          my $jobArrayRef = $jobHashByPsub->{$psubFile};
          $jobCount+= @{$jobArrayRef};

          # $self->{JobDb}->updateWithRealJobIdAndState($jobArrayRef,$realJobId,Panfish::JobState->QUEUED());

          for (my $x = 0; $x < @{$jobArrayRef}; $x++){
             ${$jobArrayRef}[$x]->setRealJobId($realJobId);
             ${$jobArrayRef}[$x]->setState(Panfish::JobState->QUEUED());
             $self->{JobDb}->update(${$jobArrayRef}[$x]);
          }
          $runningJobCount++;
       }
       else {
          $self->{Logger}->error("Unable to submit job ".$psubFile);
       }
       $self->{Logger}->info("Submitted ".$jobCount." jobs"); 
    }

    return undef;
}


1;

__END__


=head1 AUTHOR

Panfish::JobSubmitter is written by Christopher Churas<churas@ncmir.ucsd.edu>

=cut

