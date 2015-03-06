package Muninicious::Munin::RRD::Data;

use strict;
use warnings;

use Mojo::Base -base;

use Mojo::JSON;

use Muninicious::Munin::RRD::Colours;

use Math::BigFloat;
use RRDs;

use constant {
  RRD_STARTS => {day => '-2d', week => '-9d', month => '-6w', year => '-15mon'},
  RRD_ORDER  => ['day', 'week', 'month', 'year'],
};

has service     => undef;
has colours     => sub { Muninicious::Munin::RRD::Colours->new() };
has negatives   => undef;
has cdef_op     => undef;
has cdef_factor => undef;

sub is_negative {
  my ($self, $field) = @_;

  if (!defined $self->negatives) {
    $self->negatives({});
    foreach my $field (@{$self->service->fields}) {
      my $neg_name = $field->metadata('negative');
      $self->negatives->{$neg_name} = 1 if (defined $neg_name);
    }
  }

  return $self->negatives->{$field->name} ? 1 : 0;
}

sub populate_cdef_lookups {
  my ($self) = @_;

  return if (defined $self->cdef_op);

  $self->cdef_op({});
  $self->cdef_factor({});

  foreach my $field (@{$self->service->fields}) {
    my $cdef = $field->metadata('cdef');

    next if (!defined $cdef);

    if ($cdef =~ /.*,([\d\.]+),([\/\*])/) {
      $self->cdef_op->{$field->name} = $2;
      $self->cdef_factor->{$field->name} = $1;
    }
  }
}

sub apply_cdef {
  my ($self, $field, $value) = @_;

  return Math::BigFloat->bnan() if (!defined $value);

  $self->populate_cdef_lookups();

  my $op  = $self->cdef_op->{$field->name};
  return $value if (!defined $op);

  my $factor = $self->cdef_factor->{$field->name};

  if ($op eq '/') {
    return $value / $factor;
  }
  elsif ($op eq '*') {
    return $value * $factor;
  }

  return $value;
}

sub apply_negative {
  my ($self, $field, $value) = @_;

  if ($self->is_negative($field)) {
    return $value * -1;
  }
  return $value;
}

sub get_field_data {
  my ($self, $field, $agg, $start) = @_;

  my ($start_clock, $steps, $name, $fdata) = RRDs::fetch($field->get_rrd_file, $agg, '-s', $start);
  my %data;
  foreach my $i (0...@$fdata) {
    my $clock = $start_clock + ($steps * $i);
    my $value = $fdata->[$i]->[0];
    $value = $self->apply_cdef($field, $value);
    $value = $self->apply_negative($field, $value);
    $data{$clock} = $value;
  }

  return \%data;
}

sub extract_data {
  my ($self, $field, $type, $agg) = @_;

  my %data;
  foreach my $start (reverse @{&RRD_ORDER}) {
    next if ($type ne 'all' && $type ne $start);
    my $field_data = $self->get_field_data($field, $agg, &RRD_STARTS->{$start});
    foreach my $clock (keys %$field_data) {
      $data{$clock} = $field_data->{$clock};
    }
  }

  return \%data;
}

sub get_data {
  my ($self, $type) = @_;

  my $data = {
    'name'   => $self->service->name,
    'title'  => $self->service->metadata('title'),
    'vlabel' => $self->service->metadata('vlabel'),
    'data'   => [],
  };

  my $now = time();

  foreach my $field (@{$self->service->fields}) {
    my %values;
    foreach my $agg (qw/AVERAGE MIN MAX/) {
      $values{$agg} = $self->extract_data($field, $type, $agg);
    }

    my $field_data;
    $field_data->{'name'}   = $field->name;
    $field_data->{'label'}  = $field->metadata('label');
    $field_data->{'info'}   = $field->metadata('info');
    $field_data->{'colour'} = $self->colours->get_field_colour($field);
    $field_data->{'area'}   = ($field->metadata('draw') || '') =~ /AREA/ ? Mojo::JSON->true : Mojo::JSON->false;
    $field_data->{'stack'}  = ($field->metadata('draw') || '') =~ /STACK/ ? Mojo::JSON->true : Mojo::JSON->false;
    $field_data->{'data'}   = [];
    foreach my $clock (sort keys %{$values{'MIN'}}) {
      next if ($clock > $now);
      push(@{$field_data->{'data'}}, [$clock, [$values{'MIN'}->{$clock}, $values{'AVERAGE'}->{$clock}, $values{'AVERAGE'}->{$clock}]]);
    }
    push(@{$data->{'data'}}, $field_data);
  }

  return $data;
}

1;
