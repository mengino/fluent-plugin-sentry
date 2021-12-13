#
# Copyright 2021- TODO: Write your name
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"

module Fluent
  module Plugin
    class SentryOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("sentry", self)

      EVENT_KEYS = %w(message timestamp time_spent level logger culprit server_name release tags)

      config_param :endpoint_url, :string, :secret => true
      config_param :default_level, :enum, list: [:fatal, :error, :warning, :info, :debug], :default => 'error'
      config_param :default_logger, :string, :default => 'fluentd'
      config_param :flush_interval, :time, :default => 1
      config_param :hostname_command, :string, :default => 'hostname'

      config_section :buffer do
        config_set_default :flush_mode, :immediate
      end

      def initialize
        require 'time'
        require "sentry-ruby"

        super
      end

      def configure(conf)
        super

        if @endpoint_url.nil?
          raise Fluent::ConfigError, "sentry: missing parameter for 'endpoint_url'"
        end
    
        Sentry.init do |config|
          config.environment = 'fluentd'
          config.dsn = @endpoint_url
          config.send_default_pii = true
          config.send_modules = false
          config.transport.timeout = 2
          config.breadcrumbs_logger = [:sentry_logger, :http_logger]
          config.before_send = lambda do |event, hint|
            log.debug(event, hint)
            if hint[:exception].is_a?(ZeroDivisionError)
              nil
            else
              event
            end
          end
          config.before_breadcrumb = lambda do |breadcrumb, hint|
            log.debug("wewweerwr")
            log.debug(breadcrumb, hint)
            breadcrumb.message = "foo"
          end
        end
      end

      def write(chunk)
        chunk.msgpack_each do |tag, time, record|
          log.debug(time)
          begin
            Sentry.with_scope do |scope|
              scope.set_user(id: 1)
              scope.set_tags(foo: "bar")

              scope.set_context(
                'character',
                {
                  timestamp: record['timestamp'] || Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S'),
                  time_spent: record['time_spent'] || nil,
                  level: record['level'] || @default_level,
                  logger: record['logger'] || @default_logger,
                  culprit: record['culprit'] || nil,
                  server_name: record['server_name'] || `#{@hostname_command}`.chomp,
                  # release: record['release'] if record['release'],
                  tags: record['tags'],
                  extra: record.reject{ |key| EVENT_KEYS.include?(key) }
                }
              )

              scope.add_breadcrumb(Sentry::Breadcrumb.new(
                category: "auth",
                message: "Authenticated user 1111",
                level: "info"
              ))
              
              Sentry.capture_message(record['message'] || "test message", level: record['level'] || @default_level)
            end
          rescue => e
            log.error("Sentry Error:", :error_class => e.class, :error => e.message)
          end
        end
      end

      def format(tag, time, record)
        [tag, time, record].to_msgpack
      end

      def formatted_to_msgpack_binary
        true
      end
    end
  end
end
