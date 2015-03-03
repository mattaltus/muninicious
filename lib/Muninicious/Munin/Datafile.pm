package Muninicious::Munin::Datafile;

use strict;
use warnings;

use base qw/Muninicious::Munin::File/;

use Muninicious::Munin::Group;
use Muninicious::Munin::Host;
use Muninicious::Munin::Service;
use Muninicious::Munin::Field;

use File::Spec::Functions qw/catfile/;
use Carp qw/croak/;

sub new {
  my ($class, $args) = @_;

  my $self = $class->SUPER::new('datafile', $args);

  $self->{'data'} = $self->_parse($self->{'filename'});

  return $self;
}

sub _parse {
  my ($self, $filename) = @_;

  my $data = {};
  open(my $fd, "<", $filename) || croak "Error opening file '$filename': $!";
  while (<$fd>) {
    chomp;
    next if (/^version\s/i);
    if ($_ =~ /^([^;]+);([^\:]+)\:([^\.]+)\.(.+)$/) {
      next if ($4 =~ /^host_name\s+(.+)$/);

      my $group = $data->{$1};
      if (!defined $group) {
        $group = Muninicious::Munin::Group->new({'name' => $1});
        $data->{$1} = $group;
      }

      my ($host) = $group->host_by_name($2);
      if (!defined $host) {
        $host = Muninicious::Munin::Host->new({'name' => $2});
        $group->add_host($host);
      }

      my ($service) = $host->service_by_name($3);
      if (!defined $service) {
        $service = Muninicious::Munin::Service->new({'name' => $3});
        $host->add_service($service);
      }

      if ($4 =~ /^graph_(\S+)\s(.+)$/) {
        $service->metadata($1, $2);
      }
      elsif ($4 =~ /^([^\.]+)\.graph_(\S+)\s(.+)$/) {
        next if ($2 eq 'data_size');
        my $child = $service->child_by_name($1);
        if (!defined $child) {
          $child = Muninicious::Munin::Service->new({'name' => $1, 'host' => $host, 'parent' => $service});
          $service->add_child($child);
        }
        $child->metadata($2, $3);
      }
      elsif ($4 =~ /^([^\.]+)\.([^\.]+)\.(\S+)\s(.+)$/) {
        my $child = $service->child_by_name($1);
        if (!defined $child) {
          $child = Muninicious::Munin::Service->new({'name' => $1, 'host' => $host, 'parent' => $service});
          $service->add_child($child);
        }
        my $field = $child->field_by_name($2);
        if (!defined $field){
          $field = Muninicious::Munin::Field->new({'name' => $2, 'dbdir' => $self->{'dbdir'}});
          $child->add_field($field);
        }
        $field->metadata($3, $4);
      }
      elsif ($4 =~ /^([^\.]+)\.(\S+)\s(.+)$/) {
        my $field = $service->field_by_name($1);
        if (!defined $field){
          $field = Muninicious::Munin::Field->new({'name' => $1, 'dbdir' => $self->{'dbdir'}});
          $service->add_field($field);
        }
        $field->metadata($2, $3);
      }
      else {
        warn "Unmatched line: $_";
      }
    }
    else {
      warn "Unmatched line: $_";
    }
  }
  close ($fd);

  return $data;
}

sub groups {
  my ($self) = @_;
  return [sort { $a->name cmp $b->name } values %{$self->{'data'}}];
}

sub group_by_name {
  my ($self, $name) = @_;

  return $self->{'data'}->{$name};
}


sub hosts {
  my ($self, $args) = @_;

  my @list;
  foreach my $group (values %{$self->{'data'}}) {
    if (!defined $args->{'group'} || $args->{'group'} eq $group->name) {
      foreach my $host (@{$group->hosts}) {
        push(@list, $host);
      }
    }
  }
  return [sort { $a->name cmp $b->name } @list];
}


sub _filter_services {
  my ($self, $args) = @_;

  my @list;
  foreach my $group (values %{$self->{'data'}}) {
    if (!defined $args->{'group'} || $args->{'group'} eq $group->name) {
      foreach my $host (@{$group->hosts}) {
        if (!defined $args->{'host'} || $args->{'host'} eq $host->name) {
          foreach my $service (@{$group->services}) {
            push(@list, $service);
          }
        }
      }
    }
  }

  return \@list;
}

sub get_services {
  my ($self, $args) = @_;

  my $services = $self->_filter_services($args);

  return [sort { $a->name cmp $b->name } @$services];
}


sub get_service_categories {
  my ($self, $args) = @_;

  my $services = $self->_filter_services($args);

  my %list;
  foreach my $service (@$services) {
    my $category = $service->metadata('category');
    $list{$category} = 1 if (defined $category);
  }

  return sort keys %list;
}


1;
