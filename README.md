# fluent-plugin-sentry

[Fluentd](https://fluentd.org/) output plugin to do something.

TODO: write description for you plugin.

## Installation

### RubyGems

```
$ gem install fluent-plugin-sentry
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-sentry"
```

And then execute:

```
$ bundle
```

## Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format output sentry
```

## Fluent::Plugin::SentryOutput

* **default_level** (string) (optional): 
  * Default value: `error`.
* **default_logger** (string) (optional): 
  * Default value: `fluentd`.
* **endpoint_url** (string) (required): 
* **flush_interval** (time) (optional): 
  * Default value: `0`.
* **hostname_command** (string) (optional): 
  * Default value: `hostname`.

## Copyright

* Copyright(c) 2021- mengino
* License
  * Apache License, Version 2.0
