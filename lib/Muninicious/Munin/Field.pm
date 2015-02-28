package Muninicious::Munin::Field;

use strict;
use warnings;

sub new {
  my ($class, $args) = @_;

  my $self = bless({}, $class);
  $self->{'metadata'} = {};
  $self->name($args->{'name'});
  $self->service($args->{'service'});
  $self->metadata($args->{'metadata'});

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{'name'} = $name if (defined $name);
  return $self->{'name'};
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

1;