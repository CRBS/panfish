package Mock::FileUtil;

use strict;
use English;
use warnings;


sub new {
   my $class = shift;
   my $self = {
     DirName => undef,
     FileTest => undef
   };

   my $blessedself = bless($self,$class);
   return $blessedself;
}

sub addRunFileTestResult {
   my $self = shift;
   my $flag= shift;
   my $path = shift;
   my $result = shift;
   push(@{$self->{FileTest}->{$flag.$path}},$result);
}

sub runFileTest {
   my $self = shift;
   my $flag = shift;
   my $path = shift;
   return pop(@{$self->{FileTest}->{$flag.$path}});
}



=head3 addGetDirnameResult

Sets expected value for getDirname call.  If the same directory
is set multiple times the values are pushed onto a queue

my $fu->addGetDirnameResult($dir,$result);

=cut

sub addGetDirnameResult {
   my $self = shift;
   my $dir = shift;
   my $res = shift;
   
   push(@{$self->{DirName}->{$dir}},$res);

}


=head3 getDirname

Mock getDirname

=cut

sub getDirname {
   my $self = shift;
   my $dir = shift;

   return pop(@{$self->{DirName}->{$dir}});

}

1;

__END__