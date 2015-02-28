package Muninicious::Munin::Service;

use strict;
use warnings;

sub new {
  my ($class, $args) = @_;

  my $self = bless({}, $class);
  $self->{'metadata'} = {};
  $self->{'fields'}   = [];
  $self->name($args->{'name'});
  $self->host($args->{'host'});
  $self->metadata($args->{'metadata'});
  $self->fields($args->{'fields'});

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{'name'} = $name if (defined $name);
  return $self->{'name'};
}

sub host {
  my ($self, $host) = @_;
  $self->{'host'} = $host if (defined $host);
  return $self->{'host'};
}

sub fields {
  my ($self, $fields) = @_;
  $self->{'fields'} = $fields if (defined $fields);
  $_->host($self) foreach (@$fields);
  return $self->{'fields'};
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

sub add_field {
  my ($self, $field) = @_;
  push(@{$self->{'fields'}}, $field);
  $field->service($self);
  return;
}

sub field_by_name {
  my ($self, $name) = @_;

  foreach my $field (@{$self->fields}){
    if ($field->name eq $name) {
      return $field;
    }
  }
  return;
}

1;