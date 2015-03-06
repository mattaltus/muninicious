package Muninicious::Munin::RRD::Data;

use strict;
use warnings;

use Mojo::Base -base;

use Muninicious::Munin::RRD::Colours;

use Math::BigFloat;
use RRDs;

use constant {
  RRD_STARTS => {day => '-2d', week => '-9d', month => '-6w', year => '-15mon'},
  RRD_ORDER  => ['day', 'week', 'month', 'year'],
};

has service => undef;
has colours => sub { Muninicious::Munin::RRD::Colours->new() };

sub is_negative {
  my ($self, $check_field) = @_;
  my @list = ();
  foreach my $field (@{$self->service->fields}) {
    my $neg_name = $field->metadata('negative');
    return 1 if (defined $neg_name && $neg_name eq $check_field->name);
  }
  return 0;
}

sub parse_value {
  my ($value) = @_;

  if ($value eq '-nan') {
    return Math::BigFloat->bnan();
  }
  return eval "return $value;";
  return $value;
}

sub apply_cdef {
  my ($field, $value) = @_;

  return Math::BigFloat->bnan() if (!defined $value);

  my $cdef = $field->metadata('cdef');

  return $value if (!defined $cdef);

  my ($f, $num, $op) = split(/,/, $cdef);

  return eval "return $value $op $num;";
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
    my $value = $self->apply_negative($field, apply_cdef($field, $fdata->[$i]->[0]));
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
    $field_data->{'data'}   = [];
    foreach my $clock (sort keys %{$values{'MIN'}}) {
      push(@{$field_data->{'data'}}, [$clock, [$values{'MIN'}->{$clock}, $values{'AVERAGE'}->{$clock}, $values{'AVERAGE'}->{$clock}]]);
    }
    push(@{$data->{'data'}}, $field_data);
  }

  return $data;
}

1;
