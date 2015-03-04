package Muninicious::Munin::RRD::Data;

use strict;
use warnings;

use Mojo::Base -base;

use Muninicious::Munin::RRD::Colours;

use constant {
  RRD_STARTS => ['-2d', '-9d', '-6w', '-15mon']
};

has service => undef;
has colours => sub { Muninicious::Munin::RRD::Colours->new() };

sub parse_value {
  my ($value) = @_;

  if ($value eq '-nan') {
    return;
  }
  elsif ($value =~ /(\d\.\d+)e([\-\+])(\d+)/) {
    if ($2 eq '-') {
      return $1 / (10 ^ $3);
    }
    else {
      return $1 * (10 ^ $3);
    }
  }
  return $value;

}

sub get_field_data {
  my ($self, $field, $type, $start) = @_;

  my $command = "rrdtool fetch '".$field->get_rrd_file."' '$type' -s '$start'";
  open(my $rrd, '-|', $command) || die "Error rrdtool fetch: $!";
  my %data;
  while (<$rrd>) {
    if ($_ =~ /^(\d+)\:\s+(.*)$/) {
      $data{$1} = parse_value($2);
    }
  }
  close($rrd);

  return \%data;
}

sub extract_data {
  my ($self, $field, $type) = @_;

  my $data;
  foreach my $start (@{&RRD_STARTS}) {
    my $field_data = $self->get_field_data($field, $type, $start);
    if (!defined $data) {
      $data = $field_data;
    }
    else {
      foreach my $clock (keys %$field_data) {
        $data->{$clock} = $field_data->{$clock};
      }
    }
  }

  return $data;
}



sub get_data {
  my ($self) = @_;

  my $data = {
    'name'   => $self->service->name,
    'title'  => $self->service->metadata('title'),
    'vlabel' => $self->service->metadata('vlabel'),
    'data'   => [],
  };

  foreach my $field (@{$self->service->fields}) {
    my $average = $self->extract_data($field, 'AVERAGE');
    my $min     = $self->extract_data($field, 'MIN');
    my $max     = $self->extract_data($field, 'MAX');

    my $field_data;
    $field_data->{'name'}   = $field->name;
    $field_data->{'label'}  = $field->metadata('label');
    $field_data->{'info'}   = $field->metadata('info');
    $field_data->{'colour'} = $self->colours->get_field_colour($field);
    $field_data->{'data'}   = [];
    foreach my $clock (sort keys %$average) {
      push(@{$field_data->{'data'}}, [$clock, [$min->{$clock}, $average->{$clock}, $max->{$clock}]]);
    }

    push(@{$data->{'data'}}, $field_data);
  }
  return $data;
}

1;
