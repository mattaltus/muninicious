package Muninicious::Munin::Field;

use strict;
use warnings;

use File::Spec::Functions qw/catfile/;

sub new {
  my ($class, $args) = @_;

  my $self = bless({}, $class);
  $self->{'metadata'} = {};
  $self->name($args->{'name'});
  $self->service($args->{'service'});
  $self->metadata($args->{'metadata'});
  $self->dbdir($args->{'dbdir'});

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{'name'} = $name if (defined $name);
  return $self->{'name'};
}

sub dbdir {
  my ($self, $dbdir) = @_;
  $self->{'dbdir'} = $dbdir if (defined $dbdir);
  return $self->{'dbdir'};
}

sub service {
  my ($self, $service) = @_;
  $self->{'service'} = $service if (defined $service);
  return $self->{'service'};
}

sub metadata {
  my ($self, $attr, $value) = @_;

  if (!defined $attr && !defined $value) {
    return $self->{'metadata'};
  }
  elsif (!defined $value) {
    return $self->{'metadata'}->{$attr};
  }
  else {
    $self->{'metadata'}->{$attr} = $value;
    return $self->{'metadata'}->{$attr};
  }
}

sub get_rrd_file {
  my ($self) = @_;

  my $type_suffix = {
    'DERIVE'   => 'd',
    'GAUGE'    => 'g',
    'ABSOLUTE' => 'a',
    'COUNTER'  => 'c',
  };

  my $filename = catfile($self->dbdir, $self->service->host->group->name,
    $self->service->host->name.'-'.$self->service->name.'-'.$self->name.'-'.
    $type_suffix->{$self->metadata('type') || 'GAUGE'}.
    '.rrd');

  return $filename;
}

sub get_rrd_name {
  my ($self) = @_;

  return $self->name;
}

1;
