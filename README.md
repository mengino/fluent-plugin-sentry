# fluent-plugin-sentry

[Fluentd](https://fluentd.org/) output plugin to do something.

A fluent output plugin which integrated with sentry-ruby sdk

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

### dsn (string) (required)

### title (string) (optional)


Default value: `test log`.

### level (enum) (optional)


Available values: fatal, error, warning, info, debug

Default value: `info`.

### environment (string) (optional)


Default value: `local`.

### user_keys (array) (optional)


Default value: `[]`.

### tag_keys (array) (optional)


Default value: `[]`.

### keys (array) (optional)


Default value: `[]`.


## Copyright

* Copyright(c) 2021 mengino
* License
  * Apache License, Version 2.0
