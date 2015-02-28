package Muninicious::Munin::Group;

use strict;
use warnings;

sub new {
  my ($class, $args) = @_;

  my $self = bless({}, $class);
  $self->{'hosts'} = [];
  $self->name($args->{'name'});
  $self->hosts($args->{'hosts'});

  return $self;
}

sub name {
  my ($self, $name) = @_;
  $self->{'name'} = $name if (defined $name);
  return $self->{'name'};
}

sub hosts {
  my ($self, $hosts) = @_;
  $self->{'hosts'} = $hosts if (defined $hosts);
  $_->group($self) foreach (@$hosts);
  return $self->{'hosts'};
}

sub add_host {
  my ($self, $host) = @_;
  push(@{$self->{'hosts'}}, $host);
  $host->group($self);
  return;
}

sub get_hosts_by_value {
  my ($self, $args) = @_;

  my @list;
  foreach my $key (keys %$args) {
    my $value = $args->{$key};
    my @new_list;
    foreach my $host (@list) {
      if (looks_like_number($value) || ref $value) {
        push(@new_list, $host) if ($host->$key() == $value);
      }
      else {
        push(@new_list, $host) if ($host->$key() eq $value);
      }
    }
    @list = @new_list;
  }

  return \@list;
}

sub host_by_name {
  my ($self, $name) = @_;

  foreach my $host (@{$self->hosts}) {
    if ($host->name eq $name) {
      return $host;
    }
  }
  return;
}

1;