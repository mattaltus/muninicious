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
  $self->{'filename'} = $filename;
  $self->{'dbdir'}    = $ENV{'MUNIN_DB_DIR'} || $self->get_param('dbdir');
  $self->{'datafile'} = Muninicious::Munin::Datafile->new({'dbdir' => $self->{'dbdir'}});
  $self->{'limits'}   = Muninicious::Munin::Limits->new({'dbdir' => $self->{'dbdir'}});

  return $self;
}

sub get_param {
  my ($self, $name) = @_;

  my $value;
  open (my $fh, "<", $self->{'filename'}) || croak "Error opening config file";
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

  $self->{'datafile'}->reload();
  $self->{'limits'}->reload();

  return;
}

sub getDatafile {
  my ($self) = @_;

  return $self->{'datafile'};
}

sub getLimits {
  my ($self) = @_;

  return $self->{'limits'};
}

1;