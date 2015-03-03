# Muninicious

A [Mojolicious](http://mojolicio.us) frontend to [Munin](http://munin-monitoring.org/).

Should be complete enough to display all the pages and graphs that the standard munin interface does.

This only works with the 2.0.X series of Munin, not the SQL based 2.1.X series.

## Deploying
You should be able to deploy this as you would any other Mojolicous app.  See the [Mojolicious Cookbook](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook) for details.

You may need to set the *MUNUN_DB_DIR* environment variable to Mininicious can read your Munin data.  The default location seems to be '/var/lib/munin'.

**Note:** This is still a work in progress and probably has bugs.

## TODO
* Limits file parsing.
* Add limits/warnings/critical to service pages.
* Add bootstrap badges to indicate warnings/critical services.
* Add coloured borders to panels on warning/critical.
* What ever else I haven't thought of yet.
