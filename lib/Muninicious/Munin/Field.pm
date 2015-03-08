package Muninicious::Munin::Field;

use strict;
use warnings;

use Mojo::Base -base;

use File::Spec::Functions qw/catfile/;

has name      => undef;
has service   => undef;
has _metadata => sub { return {} };
has dbdir     => undef;
has state     => undef;

sub metadata {
  my ($self, $attr, $value) = @_;

  my $md = $self->_metadata;

  if (!defined $attr && !defined $value) {
    return $md;
  }
  elsif (!defined $value) {
    return $md->{$attr};
  }
  else {
    $md->{$attr} = $value;
    return $md->{$attr};
  }
}

sub get_negative {
  my ($self)  = @_;

  my $neg_field_name = $self->metadata('negative');
  return if (!defined $neg_field_name);

  return $self->service->field_by_name($neg_field_name);
}

sub get_rrd_file {
  my ($self) = @_;

  my $type_suffix = {
    'DERIVE'   => 'd',
    'GAUGE'    => 'g',
    'ABSOLUTE' => 'a',
    'COUNTER'  => 'c',
  };

  my $group;
  my $host;
  my $filename;
  if (defined $self->service->parent) {
    $group    = $self->service->parent->host->group->name;
    $filename = $self->service->parent->host->name.'-'.$self->service->parent->name.'-'.$self->service->name.'-';
  }
  else {
    $group    = $self->service->host->group->name;
    $filename = $self->service->host->name.'-'.$self->service->name.'-';
  }

  $filename .= $self->name.'-';
  $filename .= $type_suffix->{$self->metadata('type') || 'GAUGE'}.'.rrd';

  return catfile($self->dbdir, $group, $filename);
}

sub get_rrd_name {
  my ($self) = @_;

  return $self->name;
}

1;
