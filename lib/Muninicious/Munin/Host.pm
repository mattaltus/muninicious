package Muninicious::Munin::Host;

use strict;
use warnings;

use Scalar::Util qw/looks_like_number/;

sub new {
  my ($class, $args) = @_;

  my $self = bless({}, $class);
  $self->{'services'} = [];
  $self->name($args->{'name'});
  $self->group($args->{'group'});
  $self->services($args->{'services'});

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{'name'} = $name if (defined $name);
  return $self->{'name'};
}

sub group {
  my ($self, $group) = @_;
  $self->{'group'} = $group if (defined $group);
  return $self->{'group'};
}

sub services {
  my ($self, $services) = @_;
  $self->{'services'} = $services if (defined $services);
  $_->host($self) foreach (@$services);
  return $self->{'services'};
}

sub add_service {
  my ($self, $service) = @_;
  push(@{$self->{'services'}}, $service);
  $service->host($self);
  return;
}

sub get_services_by_value {
  my ($self, $args) = @_;

  my @list = @{$self->services};
  foreach my $key (keys %$args) {
    my $value = $args->{$key};
    my @new_list;
    foreach my $service (@list) {
      if (looks_like_number($value) || ref $value) {
        push(@new_list, $service) if ($service->$key() == $value);
      }
      else {
        push(@new_list, $service) if ($service->$key() eq $value);
      }
    }
    @list = @new_list;
  }

  return \@list;
}

sub get_services_by_metadata {
  my ($self, $args) = @_;

  my @list = @{$self->services};
  foreach my $key (keys %$args) {
    my $value = $args->{$key};
    my @new_list;
    foreach my $service (@list) {
      if (looks_like_number($value) || ref $value) {
        push(@new_list, $service) if ($service->metadata($key) == $value);
      }
      else {
        push(@new_list, $service) if ($service->metadata($key) eq $value);
      }
    }
    @list = @new_list;
  }

  return \@list;
}

sub service_categories {
  my ($self, $args) = @_;

  my %list;
  foreach my $service (@{$self->services}) {
    my $category = $service->metadata('category');
    $list{$category} = 1 if (defined $category);
  }

  return [sort keys %list];
}

sub service_by_name {
  my ($self, $name) = @_;

  foreach my $service (@{$self->services}){
    if ($service->name eq $name) {
      return $service;
    }
  }
  return;
}

sub get_page_url {
  my ($self) = @_;

  return '/host/'.$self->group->name.'/'.$self->name;
}

1;