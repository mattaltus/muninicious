package Muninicious::Munin::Limits;

use strict;
use warnings;

use base qw/Muninicious::Munin::File/;

use Muninicious::Munin::State;

use File::Spec::Functions qw/catfile/;
use Carp qw/croak/;

sub new {
  my ($class, $args) = @_;

  my $self = $class->SUPER::new('limits', $args);

  $self->{'data'} = $self->_parse($self->{'filename'});

  return $self;
}

sub _parse {
  my ($self, $filename) = @_;

  my $data = [];
  open(my $fd, "<", $filename) || croak "Error opening file '$filename': $!";
  while (<$fd>) {
    chomp;
    next if (/^version\s/i);
    if ($_ =~ /^([^;]+);([^;]+);([^;]+);([^;]+);([^;]+);([^\s]+)\s+(.*)$/) {
      next if ($6 eq 'state');
      push(@$data, Muninicious::Munin::State->new(
                     group         => $1,
                     host          => $2,
                     service       => $3,
                     child_service => $4,
                     field         => $5,
                     state         => $6,
                     message       => $7
                   ));
    }
    elsif ($_ =~ /^([^;]+);([^;]+);([^;]+);([^;]+);([^\s]+)\s+(.*)$/) {
      next if ($5 eq 'state');
      push(@$data, Muninicious::Munin::State->new(
                     group   => $1,
                     host    => $2,
                     service => $3,
                     field   => $4,
                     state   => $5,
                     message => $6
                   ));
    }
    else {
      warn "Failed to parse line: $_";
    }
  }
  close ($fd);

  return $data;
}


sub populate_state {
  my ($self, $datafile) = @_;

  foreach my $state (@{$self->{'data'}}) {
    my $group = $datafile->group_by_name($state->group);
    my $host  = $group->host_by_name($state->host);
    my $service = $host->service_by_name($state->service);
    $service = $service->child_by_name($state->child_service)
      if (defined $state->child_service);
    my $field = $service->field_by_name($state->field);
    $field->state($state);
  }
}

1;