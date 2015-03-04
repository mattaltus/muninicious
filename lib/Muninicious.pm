package Muninicious;
use Mojo::Base 'Mojolicious';

use Muninicious::Munin::Config;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $config = Muninicious::Munin::Config->new('/etc/munin/munin.conf');
  $self->defaults('config' => $config);

  # Router
  my $r = $self->routes;

  # Because the namespace changes between mojo versions...
  $r->namespaces(['Muninicious::Controller']);

  $r->get('/')->to(controller => 'munin', action => 'home');

  $r->get('/group/:group/')->to(controller => 'munin', action => 'group');
  $r->get('/host/:group/#host/:cat')->to(controller => 'munin', action => 'host', cat => '*');
  $r->get('/service/:group/#host/:service')->to(controller => 'munin', action => 'service');
  $r->get('/service/:group/#host/:service/:child')->to(controller => 'munin', action => 'service');
  $r->get('/child/:group/#host/:service')->to(controller => 'munin', action => 'service_child');

  $r->get('graph/:group/#host/:service/:type')->to(controller => 'munin', action => 'graph', type => 'day');
  $r->get('graph/:group/#host/:service/:child/:type')->to(controller => 'munin', action => 'graph', type => 'day');

  $r->get('data/:group/#host/:service')->to(controller => 'munin', action => 'data');
  $r->get('data/:group/#host/:service/:child')->to(controller => 'munin', action => 'data');
}



1;
