# Muninicious

A [Mojolicious](http://mojolicio.us) frontend to [Munin](http://munin-monitoring.org/).

Should be complete enough to display all the pages and graphs that the standard munin interface does.

This only works with the 2.0.X series of Munin, not the SQL based 2.1.X series.

## Deploying
You should be able to deploy this as you would any other Mojolicous app.  See the [Mojolicious Cookbook](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook) for details.

You may need to set the *MUNIN_DB_DIR* environment variable so Mininicious can read your Munin data.  The default location seems to be '/var/lib/munin'.  It should read this automatically out of '/etc/munin/munin.conf', but it hasn't been extensively tested.

The following works for me with Apache and mod_perl:
```
    PerlOptions +Parent
    PerlSwitches -I/var/www/monitor/muninicious/lib
    PerlSetEnv PLACK_ENV production
    PerlSetEnv MOJO_HOME /var/www/monitor/muninicious/
    PerlSetEnv MOJO_MODE deployment
    PerlSetEnv MUNIN_DB_DIR /var/lib/munin
    PerlSetEnv MOJO_LOG_LEVEL debug

    <Location />
      SetHandler perl-script
      PerlResponseHandler Plack::Handler::Apache2
      PerlSetVar psgi_app /var/www/monitor/muninicious/script/muninicious
    </Location>
```
**Note:** This is still a work in progress and probably has bugs.

## TODO
* Graph zooming.
* Limits file parsing.
* Add limits/warnings/critical to service pages.
* Add bootstrap badges to indicate warnings/critical services.
* Add coloured borders to panels on warning/critical.
* What ever else I haven't thought of yet.
