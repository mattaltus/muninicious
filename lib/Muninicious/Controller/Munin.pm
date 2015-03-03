package Muninicious::Controller::Munin  ;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub home {
  my $self = shift;

  $self->render(template => 'munin/home');
}


sub group {
  my $self = shift;

  my $group_name = $self->param('group');

  my $group = $self->stash('datafile')->group_by_name($group_name);
  $self->stash('group' => $group);

  $self->render(template => 'munin/group');
  return;
}

sub host {
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
    $self->render(template => 'munin/host');
    return;
  }

  $self->render(text => 'Error displaying page', status => 404);
  return;
}

sub service {
  my $self = shift;

  eval {
    my $group_name   = $self->param('group')   || die 'No group specified';
    my $host_name    = $self->param('host')    || die 'No host specified';
    my $service_name = $self->param('service') || die 'No service specified';
    my $child_name   = $self->param('child');

    my $group = $self->stash('datafile')->group_by_name($group_name) || die "Group $group_name not found";
    $self->stash('group' => $group);
    my $host = $group->host_by_name($host_name) || die "Host $host_name not found";
    $self->stash('host' => $host);
    if (defined $child_name) {
      my $parent = $host->service_by_name($service_name) || die "Service $service_name not found";
      $self->stash('parent' => $parent);
      my $service;
      $service = $parent->child_by_name($child_name) || die "Child $child_name not found";
      $self->stash('service' => $service);
    }
    else {
      my $service = $host->service_by_name($service_name) || die "Service $service_name not found";
      $self->stash('service' => $service);
      $self->stash('parent'  => undef);
    }

    $self->render(template => 'munin/service');
    return;
  };
  if ($@) {
    $self->render(text => "Error: $@", status => 500);
    return;
  }
}

sub graph {
  my $self = shift;

  eval {
    my $group_name   = $self->param('group')   || die 'No group specified';
    my $host_name    = $self->param('host')    || die 'No host specified';
    my $service_name = $self->param('service') || die 'No service specified';
    my $type         = $self->param('type')    || die 'No type specified';
    my $child        = $self->param('child')   || die 'No child specified';

    my $group   = $self->stash('datafile')->group_by_name($group_name) || die "Group $group_name not found";
    my $host    = $group->host_by_name($host_name) || die "Host $host_name not found";
    my $service = $host->service_by_name($service_name) || die "Service $service_name not found";
    if (defined $child) {
      $service = $service->child_by_name($child) || die "Service $child not found";
    }

    my $graph = $service->get_graph($type) || die "Could not generate graph";

    my $png = $graph->get_png_data() || die "Failed to retrieve png data";

    $self->render(data => $png, format => 'png');

    return;
  };
  if ($@) {
    $self->render(text => "Error: $@", status => 500);
    return;
  }
}



1;
