package Muninicious::Munin::Graph;

use strict;
use warnings;

use Mojo::Base -base;


use constant {
  START => {
    day   => '-2000m',
    week  => '-12000m',
    month => '-48000m',
    year  => '-400d'
  },
  FONTS => [
    'DejaVuSans',
    'DejaVu Sans',
    'DejaVu LGC Sans',
    'Bitstream Vera Sans'
  ],
  FIXED_FONTS => [
    'DejaVuSansMono',
    'DejaVu Sans Mono',
    'DejaVu LGC Sans Mono',
    'Bitstream Vera Sans Mono',
    'monospace'
  ],
  COLOURS => {
    'back'   => 'F0F0F0',
    'frame'  => 'F0F0F0',
    'font'   => '666666',
    'canvas' => 'FFFFFF',
    'axis'   => 'CFD6F8',
    'arrow'  => 'CFD6F8'
  },
  PALETTE => [qw(
    00CC00 0066B3 FF8000 FFCC00 330099 990099 CCFF00 FF0000 808080
    008F00 00487D B35A00 B38F00         6B006B 8FB300 B30000 BEBEBE
    80FF80 80C9FF FFC080 FFE680 AA80FF EE00CC FF8080
    666600 FFBFFF 00FFCC CC6699 999900
  )],
};

has service       => undef;
has type          => 'day';
has name          => undef;
has filename      => '-';
has palette_index => 0;
has stack         => 0;


sub _get_applicable_fields {
  my ($self) = @_;
  my @list = ();
  foreach my $field (@{$self->service->fields}) {
    push(@list, $field);
  }
  return \@list;
}


sub _get_negative_names {
  my ($self) = @_;
  my @list = ();
  foreach my $field (@{$self->_get_applicable_fields}) {
    push(@list, $field->metadata('negative'))
      if (defined $field->metadata('negative'));
  }
  return \@list;
}

sub _push_defs {
  my ($self, $args, $field) = @_;

  push(@$args, 'DEF:a'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:AVERAGE');
  push(@$args, 'DEF:l'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:MIN');
  push(@$args, 'DEF:h'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:MAX');
  push(@$args, 'CDEF:n'.$field->get_rrd_name.'=a'.$field->get_rrd_name);
  if (defined $field->metadata('warning')) {
    foreach my $limit (split(/\:/, $field->metadata('warning'))) {
      push(@$args, 'HRULE:'.$limit.'#0066B3')
    }
  }
  if (defined $field->metadata('critical')) {
    foreach my $limit (split(/\:/, $field->metadata('critical'))) {
      push(@$args, 'HRULE:'.$limit.'#FF0000')
    }
  }
  return;
}

sub _get_max_label_length {
  my ($self) = @_;

  my $max_label_length = 0;
  foreach my $field (@{$self->_get_applicable_fields}) {
    if (length($field->metadata('label')) > $max_label_length) {
      $max_label_length = length($field->metadata('label'));
    }
  }
  return $max_label_length + 1;
}

sub _get_palette_colour {
  my ($self) = @_;

  my $index = $self->palette_index();
  $index = 0 if ($index >= scalar @{&PALETTE});

  my $colour = &PALETTE->[$index++];

  $self->palette_index($index);

  return $colour;
}

sub _push_labels {
  my ($self, $args, $field, $is_negative) = @_;

  return if (defined $field->metadata('graph') && $field->metadata('graph') eq 'no' && !$is_negative);

  my $max_label_length = $self->_get_max_label_length();
  my $colour = $field->metadata('colour') || $field->metadata('color') || $self->_get_palette_colour();
  my $type   = $field->metadata('draw') || 'LINE1';
  if ($type =~ /(LINE|AREA)STACK/) {
    if (!$self->stack) {
      $type = $1;
      $self->stack(1);
    }
    else {
      $type = 'STACK';
    }
  }
  my $label = sprintf("%-${max_label_length}s", $field->metadata('label'));
  if (!$is_negative) {
    my $cdef = (defined $field->metadata('cdef')) ? 'cdef' : '';
    push(@$args, $type.':a'.$cdef.$field->get_rrd_name.'#'.$colour.':'.$label);
  }
  else {
    my $cdef = (defined $field->metadata('cdef')) ? 'cdef' : '';
    push(@$args, 'CDEF:ngcdef'.$field->get_rrd_name.'=n'.$cdef.$field->get_rrd_name.',-1,*');
    push(@$args, $type.':ngcdef'.$field->get_rrd_name.'#'.$colour);
    push(@$args, 'CDEF:re_zero=n'.$cdef.$field->get_rrd_name.',UN,0,0,IF');
    push(@$args, 'LINE1:re_zero#000000');
  }
}

sub _push_gprint {
  my ($self, $args, $field, $is_negative) = @_;

  my $cdef = (defined $field->metadata('cdef')) ? 'cdef' : '';
  if (!$is_negative) {
    push(@$args, 'GPRINT:n'.$cdef.$field->get_rrd_name.':LAST:%6.2lf%s');
    push(@$args, 'GPRINT:l'.$cdef.$field->get_rrd_name.':MIN:%6.2lf%s');
    push(@$args, 'GPRINT:a'.$cdef.$field->get_rrd_name.':AVERAGE:%6.2lf%s');
    push(@$args, 'GPRINT:h'.$cdef.$field->get_rrd_name.':MAX:%6.2lf%s\\j');
  }
  else {
    push(@$args, 'GPRINT:n'.$cdef.$field->get_rrd_name.':LAST:%6.2lf%s/\\g');
    push(@$args, 'GPRINT:l'.$cdef.$field->get_rrd_name.':MIN:%6.2lf%s/\\g');
    push(@$args, 'GPRINT:a'.$cdef.$field->get_rrd_name.':AVERAGE:%6.2lf%s/\\g');
    push(@$args, 'GPRINT:h'.$cdef.$field->get_rrd_name.':MAX:%6.2lf%s/\\g');
  }

  return;
}

sub _push_cdefs {
  my ($self, $args, $field) = @_;

  return if (!defined $field->metadata('cdef'));

  push(@$args, 'CDEF:acdef'.$field->get_rrd_name.'=a'.$field->metadata('cdef'));
  push(@$args, 'CDEF:lcdef'.$field->get_rrd_name.'=l'.$field->metadata('cdef'));
  push(@$args, 'CDEF:hcdef'.$field->get_rrd_name.'=h'.$field->metadata('cdef'));
  push(@$args, 'CDEF:ncdef'.$field->get_rrd_name.'=n'.$field->metadata('cdef'));

  return;
}


sub get_rrd_args {
  my ($self) = @_;

  my $negatives = $self->_get_negative_names();

  my @args = ();
  push(@args, $self->filename);
  push(@args, '--title', $self->service->metadata('title').' - by '.$self->type);
  push(@args, '--start', &START->{$self->type} || '-1200m');
  push(@args, split(/\s+/, $self->service->metadata('args')));
  push(@args, '--vertical-label', $self->service->metadata('vlabel'));
  push(@args, '--slope-mode');
  push(@args, '--height', 175);
  push(@args, '--width', 400);
  push(@args, '--imgformat', 'PNG');
  push(@args, '--font', 'DEFAULT:0:'.join(',', @{&FONTS}));
  push(@args, '--font', 'LEGEND:7:'.join(',', @{&FIXED_FONTS}));
  foreach my $key (keys %{&COLOURS}) {
    push(@args, '--color', uc($key).'#'.&COLOURS->{$key});
  }
  push(@args, '--border', '0');
  push(@args, '-W', 'Muninicious');

  foreach my $field (@{$self->_get_applicable_fields}) {
    $self->_push_defs(\@args, $field);
    $self->_push_cdefs(\@args, $field);
  }

  if (@$negatives) {
    push(@args, 'COMMENT:   ');
    push(@args, 'COMMENT:Cur (-/+)');
    push(@args, 'COMMENT:Min (-/+)');
    push(@args, 'COMMENT:Avg (-/+)');
    push(@args, 'COMMENT:Max (-/+) \\j');
  }
  else {
    push(@args, 'COMMENT:                  ');
    push(@args, 'COMMENT: Cur\\:');
    push(@args, 'COMMENT:Min\\:');
    push(@args, 'COMMENT:Avg\\:');
    push(@args, 'COMMENT:Max\\:  \\j');
  }

  foreach my $field (@{$self->_get_applicable_fields}) {
    my $name = $field->name;
    if (grep /^\Q$name\E$/, @$negatives) {
    }
  }

  foreach my $field (@{$self->_get_applicable_fields}) {
    my $name = $field->name;
    my $is_negative = grep {/^\Q$name\E$/} @$negatives;
    $self->_push_labels(\@args, $field, $is_negative)
      if (!$is_negative);
  }
  foreach my $field (@{$self->_get_applicable_fields}) {
    my $name = $field->name;
    my $is_negative = grep {/^\Q$name\E$/} @$negatives;
    $self->_push_gprint(\@args, $field, $is_negative);
  }
  foreach my $field (@{$self->_get_applicable_fields}) {
    my $name = $field->name;
    my $is_negative = grep {/^\Q$name\E$/} @$negatives;
    $self->_push_labels(\@args, $field, $is_negative)
      if ($is_negative);
  }
  my $clock = localtime();
  $clock =~ s/\:/\\\:/g;
  push(@args, 'COMMENT:Last Update\\: '.$clock.'\\r');

  push(@args, '--end');
  push(@args, time());

  warn Data::Dumper::Dumper(\@args);

  return \@args;
}

sub get_png_data {
  my ($self) = @_;

  my $rrd_args = $self->get_rrd_args();

  my $command = 'rrdtool graph '.join(' ', map {"'".$_."'"} @$rrd_args);
  open(my $rrd, '-|', $command) || die 'Error rrdtool graph: $!';
  binmode($rrd);
  my $data;
  my $buffer;
  while(read($rrd, $buffer, 1024) > 0){
    $data .= $buffer;
  }
  close($rrd);

  return $data;
}

1;