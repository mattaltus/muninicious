package Muninicious::Munin::Service;

use strict;
use warnings;

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

sub get_rrd_graph_args {
  my ($self, $type, $filename) = @_;

  my %start = (day   => '-2000m',
               week  => '-12000m',
               month => '-48000m',
               year  => '-400d');

  my @default_fonts = ('DejaVuSans','DejaVu Sans','DejaVu LGC Sans','Bitstream Vera Sans');
  my @legent_fonts = ('DejaVuSansMono','DejaVu Sans Mono','DejaVu LGC Sans Mono','Bitstream Vera Sans Mono','monospace');
  my %colours = ('back'   => 'F0F0F0',
                 'frame'  => 'F0F0F0',
                 'font'   => '666666',
                 'canvas' => 'FFFFFF',
                 'axis'   => 'CFD6F8',
                 'arrow'  => 'CFD6F8');
  my @palette = qw(00CC00 0066B3 FF8000 FFCC00 330099 990099 CCFF00 FF0000 808080
                   008F00 00487D B35A00 B38F00         6B006B 8FB300 B30000 BEBEBE
                   80FF80 80C9FF FFC080 FFE680 AA80FF EE00CC FF8080
                   666600 FFBFFF 00FFCC CC6699 999900
                  );

  my @args = ();
  push(@args, $filename);
  push(@args, '--title', $self->metadata('title').' - by '.$type);
  push(@args, '--start', $start{$type} || '1200m');
  push(@args, split(/\s+/, $self->metadata('args')));
#  push(@args, '--rigid');
  push(@args, '--vertical-label', $self->metadata('vlabel'));
  push(@args, '--slope-mode');
  push(@args, '--height', 175);
  push(@args, '--width', 400);
  push(@args, '--imgformat', 'PNG');
  push(@args, '--font', 'DEFAULT:0:'.join(',', @default_fonts));
  push(@args, '--font', 'LEGEND:7:'.join(',', @legent_fonts));
  foreach my $key (keys %colours) {
    push(@args, '--color', uc($key).'#'.$colours{$key});
  }
  push(@args, '--border', '0');
  push(@args, '-W', 'Muninicious');

  foreach my $field (@{$self->fields}) {
    push(@args, 'DEF:a'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:AVERAGE');
    push(@args, 'DEF:l'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:MIN');
    push(@args, 'DEF:h'.$field->get_rrd_name.'='.$field->get_rrd_file.':42:MAX');
    push(@args, 'CDEF:n'.$field->get_rrd_name.'=a'.$field->get_rrd_name);
    if (defined $field->metadata('warning')) {
      foreach my $limit (split(/\:/, $field->metadata('warning'))) {
        push(@args, 'HRULE:'.$limit.'#0066B3')
      }
    }
    if (defined $field->metadata('critical')) {
      foreach my $limit (split(/\:/, $field->metadata('critical'))) {
        push(@args, 'HRULE:'.$limit.'#FF0000')
      }
    }
  }
  push(@args, 'COMMENT:                  ');
  push(@args, 'COMMENT: Cur\\:');
  push(@args, 'COMMENT:Min\\:');
  push(@args, 'COMMENT:Avg\\:');
  push(@args, 'COMMENT:Max\\:  \\j');


  my $max_label_length = 0;
  foreach my $field (@{$self->fields}) {
    if (length($field->metadata('label')) > $max_label_length) {
      $max_label_length = length($field->metadata('label'));
    }
  }
  $max_label_length+=1;

  my $palette_index = 0;
  foreach my $field (@{$self->fields}) {
    my $colour = $field->metadata('colour') || $field->metadata('color') || $palette[$palette_index++];
    my $type   = $field->metadata('draw') || 'LINE1';
    if ($type eq 'AREASTACK') {
      if ($field eq $self->fields->[0]) {
        $type = 'AREA';
      }
      else {
        $type = 'STACK';
      }
    }

    push(@args, $type.':a'.$field->get_rrd_name.'#'.$colour.':'.
                  sprintf("%-${max_label_length}s", $field->metadata('label')));
    push(@args, 'GPRINT:n'.$field->get_rrd_name.':LAST:%6.2lf%s');
    push(@args, 'GPRINT:l'.$field->get_rrd_name.':MIN:%6.2lf%s');
    push(@args, 'GPRINT:a'.$field->get_rrd_name.':AVERAGE:%6.2lf%s');
    push(@args, 'GPRINT:h'.$field->get_rrd_name.':MAX:%6.2lf%s\\j');
    if (defined $field->metadata('cdef')) {
      push(@args, 'CDEF:acdef'.$field->get_rrd_name.'=a'.$field->metadata('cdef'));
      push(@args, 'CDEF:lcdef'.$field->get_rrd_name.'=l'.$field->metadata('cdef'));
      push(@args, 'CDEF:hcdef'.$field->get_rrd_name.'=h'.$field->metadata('cdef'));
      push(@args, 'CDEF:ncdef'.$field->get_rrd_name.'=n'.$field->metadata('cdef'));
    }
  }
  my $clock = localtime();
  $clock =~ s/\:/\\\:/g;
  push(@args, 'COMMENT:Last Update\\: '.$clock.'\\r');

  push(@args, '--end');
  push(@args, time());

  return \@args;
}

1;
