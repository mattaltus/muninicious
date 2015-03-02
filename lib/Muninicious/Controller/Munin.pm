package Muninicious::Controller::Munin  ;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub home {
  my $self = shift;

  $self->render(template => 'munin/home');
}


sub page {
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
    $self->render(template => 'munin/page_group_host');
    return;
  }
  if (defined $group && ! defined $host) {
    $self->render(template => 'munin/page_group');
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

  my $group   = $self->stash('datafile')->group_by_name($group_name);
  my $host    = $group->host_by_name($host_name);
  my $service = $host->service_by_name($service_name);

  my $graph = $service->get_graph($type);

  my $png = $graph->get_png_data();

  $self->render(data => $png, format => 'png');

  return;
}



1;
