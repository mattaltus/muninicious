package Muninicious::Munin::Config;

use strict;
use warnings;

use base qw/Muninicious::Munin::File/;

use Muninicious::Munin::Datafile;
use Muninicious::Munin::Limits;

use File::Spec::Functions qw/catfile/;
use Carp qw/croak/;

sub new {
  my ($class, $filename) = @_;

  my $self = bless({}, $class);
  $self->{'FILENAME'} = $filename;
  $self->{'DBDIR'}    = $ENV{'MUNIN_DB_DIR'} || $self->get_param('dbdir');
  $self->{'DATAFILE'} = Muninicious::Munin::Datafile->new({'dbdir' => $self->{'DBDIR'}});
  $self->{'LIMITS'}   = Muninicious::Munin::Limits->new({'dbdir' => $self->{'DBDIR'}});

  return $self;
}

sub get_param {
  my ($self, $name) = @_;

  my $value;
  open (my $fh, "<", $self->{'FILENAME'}) || croak "Error opening config file";
  while (<$fh>) {
    if ($_ =~ /^\s*\Q$name\E\s+([^#])/){
      $value = $1;
      last;
    }
  }
  close ($fh);

  return $value;
}

sub reload {
  my ($self) = @_;

  $self->{'DATAFILE'}->reload();
  $self->{'LIMITS'}->reload();

  return;
}

sub getDatafile {
  my ($self) = @_;

  return $self->{'DATAFILE'};
}

sub getLimits {
  my ($self) = @_;

  return $self->{'LIMITS'};
}

1;