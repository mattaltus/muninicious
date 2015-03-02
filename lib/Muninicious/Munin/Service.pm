package Muninicious::Munin::Service;

use strict;
use warnings;

use Muninicious::Munin::Graph;

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

  if (defined $self->metadata('order')) {
    my @order = split('\s+', $self->metadata('order'));
    foreach my $name (map { $_->name } @{$self->{'fields'}}) {
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

  foreach my $field (@{$self->{'fields'}}){
    if ($field->name eq $name) {
      return $field;
    }
  }
  return;
}


sub get_graph_url {
  my ($self, $type) = @_;

  return '/graph/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name.'/'.$type;

  my $url = 'https://monitor.altus.id.au/munin-cgi/munin-cgi-graph/'.$self->host->group->name.'/'.$self->host->name.'/'.$self->name.'-'.$type.'.png';

  return $url;
}

sub get_graph {
  my ($self, $type) = @_;

  return Muninicious::Munin::Graph->new(service => $self, type => $type);
}


1;
