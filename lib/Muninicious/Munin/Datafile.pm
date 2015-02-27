package Muninicious::Munin::Datafile;

use strict;
use warnings;

use base qw/Muninicious::Munin::File/;

use File::Spec::Functions qw/catfile/;
use Carp qw/croak/;

sub new {
  my ($class, $args) = @_;

  my $self = $class->SUPER::new('datafile', $args);

  $self->{'DATA'} = $self->_parse($self->{'FILENAME'});

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
      my $group = $1;
      my $host  = $2;
      my $graph = $3;
      $data->{$group}->{$host}->{$graph}->{'host'} = $host;
      $data->{$group}->{$host}->{$graph}->{'group'} = $group;
      $data->{$group}->{$host}->{$graph}->{'name'} = $graph;
      if ($4 =~ /^graph_(\S+)\s(.+)$/) {
        $data->{$group}->{$host}->{$graph}->{'graph'}->{$1} = $2;
      }
      elsif ($4 =~ /^([^\.]+)\.(\S+)\s(.+)$/) {
        $data->{$group}->{$host}->{$graph}->{'value'}->{$1}->{$2} = $3;
      }
    }
  }
  close ($fd);

  return $data;
}

sub getGroups {
  my ($self) = @_;
  return sort keys %{$self->{'DATA'}};
}

sub getHosts {
  my ($self, $args) = @_;

  my %list;
  foreach my $group (keys %{$self->{'DATA'}}) {
    if (!defined $args->{'group'} || $args->{'group'} eq $group) {
      foreach my $host (keys %{$self->{'DATA'}->{$group}}) {
        $list{$host} = 1;
      }
    }
  }
  return sort keys %list;
}


sub _filter_graphs {
  my ($self, $args) = @_;

  my @list;
  foreach my $group (keys %{$self->{'DATA'}}) {
    if (!defined $args->{'group'} || $args->{'group'} eq $group) {
      foreach my $host (keys %{$self->{'DATA'}->{$group}}) {
        if (!defined $args->{'host'} || $args->{'host'} eq $host) {
          foreach my $graph (keys %{$self->{'DATA'}->{$group}->{$host}}) {
            push(@list, $self->{'DATA'}->{$group}->{$host}->{$graph});
          }
        }
      }
    }
  }

  use Data::Dumper;
  warn Dumper(\@list);

  return \@list;
}

sub getGraphs {
  my ($self, $args) = @_;

  my $graphs = $self->_filter_graphs($args);

  my %list;
  foreach my $graph (@$graphs) {
    $list{$graph->{'name'}} = 1;
  }

  return sort keys %list;
}


sub getGraphCategories {
  my ($self, $args) = @_;

  my $graphs = $self->_filter_graphs($args);

  my %list;
  foreach my $graph (@$graphs) {
    $list{$graph->{'graph'}->{'category'}} = 1
      if (defined $graph->{'graph'} && defined $graph->{'graph'}->{'category'});
  }

  return sort keys %list;
}

sub getGraphMetadata {
  my ($self, $group, $host, $graph) = @_;

  return $self->{'DATA'}->{$group}->{$host}->{$graph}->{'graph'};
}

sub getGraphFields {
  my ($self, $group, $host, $graph) = @_;

  return sort keys %{$self->{'DATA'}->{$group}->{$host}->{$graph}->{'value'}};
}

sub getGraphFieldMetadata {
  my ($self, $group, $host, $graph, $field) = @_;

  return $self->{'DATA'}->{$group}->{$host}->{$graph}->{'value'}->{$field};
}


1;