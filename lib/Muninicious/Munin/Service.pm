package Muninicious::Munin::Service;

use strict;
use warnings;

use Mojo::Base -base;

use Muninicious::Munin::RRD::Graph;
use Muninicious::Munin::RRD::Data;
use Muninicious::Munin::State;

has name      => undef;
has host      => undef;
has _metadata => sub { return {} };
has _fields   => sub { return [] };
has children  => sub { return [] };
has parent    => undef;

sub fields {
  my ($self, $fields) = @_;
  $self->_fields = $fields if (defined $fields);
  $_->host($self) foreach (@$fields);

  if (defined $self->metadata('order')) {
    my @order = split('\s+', $self->metadata('order'));
    foreach my $name (map { $_->name } @{$self->_fields}) {
      push(@order, $name) if (!grep /^\Q$name\E$/, @order);
    }

    # remove duplicates.
    my %seen = ();
    my @new_order = ();
    foreach my $field (@order) {
      push(@new_order, $field) if (!$seen{$field});
      $seen{$field} = 1;
    }

    my @new_fields = map { $self->field_by_name($_) } @new_order;
    return \@new_fields;
  }

  return $self->_fields;
}

sub metadata {
  my ($self, $attr, $value) = @_;

  if (!defined $attr && !defined $value) {
    return $self->_metadata;
  }
  elsif (!defined $value) {
    my $str = $self->_metadata->{$attr};
    if (defined $str && $str =~ /\$\{graph_(.*)\}/) {
      my $replace = $self->_metadata->{$1};
      $replace = 'second' if (!defined $replace && $1 eq 'period');
      $str =~ s/\$\{graph_\Q$1\E\}/$replace/g;
      return $str;
    }
    return $self->_metadata->{$attr};
  }
  else {
    $self->_metadata->{$attr} = $value;
    return $self->_metadata->{$attr};
  }
}

sub add_field {
  my ($self, $field) = @_;
  push(@{$self->_fields}, $field);
  $field->service($self);
  return;
}

sub field_by_name {
  my ($self, $name) = @_;

  foreach my $field (@{$self->_fields}){
    if ($field->name eq $name) {
      return $field;
    }
  }
  return;
}

sub add_child {
  my ($self, $child) = @_;
  push(@{$self->children}, $child);
  return;
}

sub child_by_name {
  my ($self, $name) = @_;

  foreach my $child (@{$self->children}){
    if ($child->name eq $name) {
      return $child;
    }
  }
  return;
}

sub get_graph_url {
  my ($self, $type) = @_;

  if ($self->parent) {
    return '/graph/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->parent->name.'/'.$self->name.'/'.$type;
  }
  return '/graph/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name.'/'.$type;
}

sub get_data_url {
  my ($self, $type) = @_;

  my $type_str = '';
  $type_str = '?type='.$type if (defined $type);

  if ($self->parent) {
    return '/data/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->parent->name.'/'.$self->name.$type_str;
  }
  return '/data/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name.$type_str;
}

sub get_page_url {
  my ($self) = @_;

  if ($self->parent) {
    return '/service/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->parent->name.'/'.$self->name;
  }
  if (@{$self->children}) {
    return '/child/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name;
  }
  return '/service/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name;
}

sub get_graph {
  my ($self, $type) = @_;

  return Muninicious::Munin::RRD::Graph->new(service => $self, type => $type);
}

sub get_data {
  my ($self) = @_;

  return Muninicious::Munin::RRD::Data->new(service => $self);
}

sub state {
  my ($self) = @_;

  my $state;
  foreach my $child (@{$self->children}) {
    $state = $child->state if (!defined $state);
    $state = $child->state if ($state < $child->state);
  }
  return $state if (defined $state);

  foreach my $field (@{$self->_fields}) {
    next if (!defined $field->state);
    $state = $field->state if (!defined $state);
    $state = $field->state if ($state < $field->state);
  }
  return $state if (defined $state);

  return Muninicious::Munin::State->new(state => 'ok');
}

1;
