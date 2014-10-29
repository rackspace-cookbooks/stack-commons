stack_commons CHANGELOG
=======================

This file is used to list changes made in each version of the stack_commons cookbook.

0.0.19
------
- @seeafish - Added redis meetme functionality and cleaned up newrelic in general by removing refs to stackname and updating recipe inclusion checks.

0.0.16
------
- @cybermerc - Added glusterfs

0.0.15
------
- @jujugrrr - Fixed missing monitoring #26

0.0.12
------
- @martinb3 - Migrated the `logstash_commons` calls to use attributes on elkstack instead. Added tests to verify the templates are pushed out successfully when converged with elkstack::agent in a wrapper recipe.

0.0.11
-----
- @jujugrrr - Added newrelic recipe

0.0.9
-----
- @jujugrrr - Removed systemd workaround as we don't support Centos7 anymore

0.0.8
-----

Knife complained about uploading 0.0.7, but still uploaded, so I version bumped to be sure we had the latest/freshest:

```
$ knife cookbook site share stack_commons 'Other'
Generating metadata for stack_commons from /tmp/chef-stack_commons-build20141021-673-supw6x/stack_commons/metadata.rb
Making tarball stack_commons.tgz
ERROR: Error uploading cookbook stack_commons to the Opscode Cookbook Site: parse error: trailing garbage
                                   500 Internal Server Error If you ar
                     (right here) ------^
. Increase log verbosity (-VV) for more information.
```

0.0.7
-----
- @martinb3 - Added redis

0.0.6
-----
- [Julien Berard] - Added memcached

0.0.3
-----
- [Julien Berard] - Added mongodb_standalone

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
