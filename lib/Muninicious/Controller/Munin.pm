package Muninicious::Controller::Munin  ;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub home {
  my $self = shift;

  $self->render(template => 'munin/home');
}


sub page_group {
  my $self = shift;

  my $group_name = $self->param('group');

  my $group = $self->stash('datafile')->group_by_name($group_name);
  $self->stash('group' => $group);

  $self->render(template => 'munin/page_group');
  return;
}

sub page_host {
  my $self = shift;

  my $group_name = $self->param('group') || '*';
  my $host_name  = $self->param('host')  || '*';
  my $cat_name   = $self->param('cat')  || '*';

  my $group;
  $group = $self->stash('datafile')->group_by_name($group_name)
    if ($group_name ne '*');
  $self->stash('group' => $group);
  my $host;
  $host = $group->host_by_name($host_name)
    if ($host_name ne '*' && defined $group);
  $self->stash('host' => $host);

  $cat_name = $host->service_categories->[0]
    if ($cat_name eq '*');
  $self->stash('category' => $cat_name);

  if (defined $group && defined $host) {
    $self->render(template => 'munin/page_host');
    return;
  }

  $self->render(text => 'Error displaying page', status => 404);
  return;
}




sub graph {
  my $self = shift;

  my $config = $self->stash('config');

  my $group_name   = $self->param('group');
  my $host_name    = $self->param('host');
  my $service_name = $self->param('service');
  my $type         = $self->param('type');
  my $child        = $self->param('child');

  my $group   = $self->stash('datafile')->group_by_name($group_name);
  my $host    = $group->host_by_name($host_name);
  my $service = $host->service_by_name($service_name);
  if (defined $child) {
    $service = $service->child_by_name($child);
  }

  my $graph = $service->get_graph($type);

  my $png = $graph->get_png_data();

  $self->render(data => $png, format => 'png');

  return;
}



1;
