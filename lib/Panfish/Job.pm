package Panfish::Job;

use strict;
use English;
use warnings;

=head1 SYNOPSIS
   
Panfish::Job -- Represents a Panfish job

=head1 DESCRIPTION

This object represents a Panfish Job.

=head1 METHODS

=head3 new

Creates new instance of Job object

my $job = Panfish::Job->new()

=cut

sub new {
  my $class = shift;
  my $self = {
     Cluster           => shift,
     JobId             => shift,
     TaskId            => shift,
     JobName           => shift,
     CurrentWorkingDir => shift,
     Command           => shift,
     State             => shift,
     ModificationTime  => shift,
     CommandsFile      => shift,
     PsubFile          => shift,
     RealJobId         => shift,
     FailReason        => shift,
     BatchFactor       => shift,
     WallTime          => shift,
     Account           => shift
  };
  my $blessedself = bless($self,$class);
  return $blessedself;
}

=head3 equals

Compares job passed in with this job.
Returns 1 if they are equal or 0 if they
are not.  This code does not check if its
the same object being checked against itself.
Also the comparison ignores ModificationTime


=cut

sub equals {
  my $self = shift;
  my $job = shift;

  my $equal = 1;
  my $notEqual = 0;

  if (!defined($job)){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getJobId(),$self->getJobId()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getTaskId(),$self->getTaskId()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getCurrentWorkingDir(),
                          $self->getCurrentWorkingDir()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getState(),$self->getState()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getCluster(),$self->getCluster()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getJobName(),$self->getJobName()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getCommand(),$self->getCommand()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getPsubFile(),$self->getPsubFile()) == 0){
    return $notEqual;
  }
    
  if ($self->_safeCompare($job->getCommandsFile(),
                          $self->getCommandsFile()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getRealJobId(),
                            $self->getRealJobId()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getFailReason(),
                          $self->getFailReason()) == 0){
    return $notEqual;
  }
  
  if ($self->_safeCompare($job->getBatchFactor(),
                          $self->getBatchFactor()) == 0){
    return $notEqual;
  }
    
  if ($self->_safeCompare($job->getWallTime(),
                            $self->getWallTime()) == 0){
    return $notEqual;
  }

  if ($self->_safeCompare($job->getAccount(),
                          $self->getAccount()) == 0){
    return $notEqual;
  }

  return $equal;
}


#
# First checks that both values are defined
# then does a string comparison.  
# Returns 1 if they are equal.  Where equal
# means both are undefined or both are defined
# and have the same string value
#
sub _safeCompare {
  my $self = shift;
  my $valOne = shift;
  my $valTwo = shift;

  # both undefined we are the same
  if (!defined($valOne) && !defined($valTwo)){
    return 1;
  }

  if (!defined($valOne) || 
      !defined($valTwo)){
    return 0;
  }
    
  if ($valOne eq $valTwo){
    return 1;
  }
  return 0;
}

=head3 getRealJobId

Id of the job really doing the work

=cut

sub getRealJobId {
  my $self = shift;
  return $self->{RealJobId};
}

sub setRealJobId {
  my $self = shift;
  $self->{RealJobId} = shift;
}

=head3 getPsubFile 

Gets the psub file

=cut

sub getPsubFile {
  my $self = shift;
  return $self->{PsubFile};
}

=head3 setPsubFile

Sets the psub file

=cut

sub setPsubFile {
  my $self = shift;
  $self->{PsubFile} = shift;
}

=head3 getCommandsFile 

Gets the commands file that this job was put in

=cut

sub getCommandsFile {
  my $self = shift;
  return $self->{CommandsFile};
}

=head3 setCommandsFile

Sets the Commands file that this job was put in

=cut

sub setCommandsFile{
  my $self = shift;
  $self->{CommandsFile} = shift;
}


=head3 getModificationTime 

Gets last time this object was modified

=cut

sub getModificationTime {
  my $self = shift;
  return $self->{ModificationTime};
}

=head3 getCluster

=cut

sub getCluster {
  my $self = shift;
  return $self->{Cluster};
}

=head3 getJobId

=cut

sub getJobId {
  my $self = shift;
  return $self->{JobId};
}

=head3 getTaskId

=cut

sub getTaskId {
  my $self = shift;
  return $self->{TaskId};
}


=head3 getCurrentWorkingDir

Gets the current working directory for the job

=cut

sub getCurrentWorkingDir {
  my $self = shift;
  return $self->{CurrentWorkingDir};
}

=head3 getJobName

Gets the Job Name

=cut

sub getJobName {
  my $self = shift;
  return $self->{JobName};
}

=head3 getCommand

Gets the Command to run

=cut

sub getCommand {
  my $self = shift;
  return $self->{Command};
}

=head3 getState

Gets state of the job

=cut

sub getState {
  my $self = shift;
  return $self->{State};
}

=head3 setState 

=cut

sub setState {
  my $self = shift;
  $self->{State} = shift;
}

sub getJobAndTaskId {
  my $self = shift;
 
  if (defined($self->{JobId}) && defined($self->{TaskId})){
    return $self->{JobId}.".".$self->{TaskId};
  }

  if (defined($self->{JobId})){
    return $self->{JobId};
  }
    
  return undef;
}

=head3 setFailReason

Sets reason, if any, for failure of job

=cut

sub setFailReason {
  my $self = shift;
  $self->{FailReason} = shift;
}

=head3 getFailReason

Gets reason, if any, for failure of job

=cut

sub getFailReason {
  my $self = shift;
  return $self->{FailReason};
}

=head3 setBatchFactor

Sets Batch Factor which defines how many jobs should be batched into a single 
panfish job.  This factor is multipled by the jobs per node value for the 
destination cluster.

=cut

sub setBatchFactor {
  my $self = shift;
  $self->{BatchFactor} = shift;
}

=head3 getBatchFactor

Gets Batch Factor which defines how many jobs should be batched into a single panfish job.  This factor
is multipled by the jobs per node value for the destination cluster.

=cut

sub getBatchFactor {
  my $self = shift;
  return $self->{BatchFactor};
}

=head3 setWallTime 

Sets walltime for job

=cut
sub setWallTime {
  my $self = shift;
  $self->{WallTime} = shift;
}

=head3 getWallTime

Gets the walltime for job

=cut
sub getWallTime {
  my $self = shift;
  return $self->{WallTime};
}


=head3 setAccount 

Sets account to bill job to 

=cut
sub setAccount {
  my $self = shift;
  $self->{Account} = shift;
}

=head3 getAccount

Gets account the job should be billed to

=cut
sub getAccount {
  my $self = shift;
  return $self->{Account};
}


=head3 compareJobByJobAndTaskId

Compares the job id and task id of this (a) job
against the job id and task id of the job
passed in (b).  If (a) job has a lower job id and/or task id
then (b) return value is -1, if (b) has lower job id then
1 is returned.  If job ids match then task ids are compared
using <=> comparison

=cut
sub compareJobByJobAndTaskId {
  my $self = shift;
  my $b = shift;

  if (!defined($b)){
    return -1;
  }

  if ($self->getJobId() < $b->getJobId()){
    return -1;
  }

  if ($self->getJobId() > $b->getJobId()){
    return 1;
  }

  if (!defined($self->getTaskId()) && 
      !defined($b->getTaskId())){
    return 0;
  }

  if (!defined($self->getTaskId())){
    return 1;
  }

  if (!defined($b->getTaskId())){
    return -1;
  }
 
  return $self->getTaskId() <=> $b->getTaskId();
}



=head3 getJobAsString

Generates a String summarizing the job in this format

Cluster:           foo
JobId:             1
TaskId:            23
JobName:           blah
CurrentWorkingDir: /tmp
Command:           /bin/foo.sh
State:             SUBMITTED
ModificationTime:  12313433
CommandsFile:      undef
PsubFile:          undef
RealJobId:         undef
FailReason:        undef

=cut

sub getJobAsString {
  my $self = shift;
  my $res = "";

  my $keyMaxLen = 0;
  my $curLen = 0;
  my $valueMaxLen = 0;
  while (my ($key,$value) = each(%$self)){
    $curLen = length($key);
    if ($curLen > $keyMaxLen){
      $keyMaxLen = $curLen;
    }
    $curLen = length($value);
    if ($curLen > $valueMaxLen){
      $valueMaxLen = $curLen;
    }
  }
    
  my $offset;
  while (my ($key,$value) = each(%$self)){
    if (!defined($value)){
      $value = "undef";
    } 
    $offset = ($keyMaxLen+$valueMaxLen) - (length($key)+($valueMaxLen-length($value)));
    $res .= sprintf("$key: %*2\$s\n",$value,$offset);
  }     
  return $res;
}
1;

__END__


=head1 AUTHOR

Panfish::Job is written by Christopher Churas<churas@ncmir.ucsd.edu>

=cut

