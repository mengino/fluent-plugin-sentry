require "fluent/plugin/output"

module Fluent
  module Plugin
    class SentryOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("sentry", self)

      config_param :dsn, :string, :secret => true
      config_param :title, :string, :default => 'test log'
      config_param :level, :enum, list: [:fatal, :error, :warning, :info, :debug], :default => 'info'
      config_param :timestamp, :string, :default => 'timestamp'
      config_param :environment, :string, :default => 'local'

      config_param :user_keys, :array, :default => [], value_type: :string
      config_param :tag_keys, :array, :default => [], value_type: :string
      config_param :keys, :array, :default => [], value_type: :string


      def initialize
        require 'time'
        require "sentry-ruby"

        super
      end

      def configure(conf)
        super

        config = Sentry::Configuration.new
        config.dsn = @dsn
        config.environment = @environment
        config.send_modules = false
        config.transport.timeout = 5

        @client = Sentry::Client.new(config)
      end

      def write(chunk)
        chunk.msgpack_each do |tag, time, record|
          begin
            event = Sentry::Event.new(configuration: @client.configuration)

            event.message = @title
            event.level = record['level'] || @level
            event.timestamp = record[@timestamp] || Time.at(time).utc.strftime('%Y-%m-%dT%H:%M:%S')

            event.user = record.select{ |key| @user_keys.include?(key) }
            event.extra = @keys.length() > 0 ? record.select{ |key| @keys.include?(key) } : record
            event.contexts = {'data' => { origin_data: record }}
            event.tags = event.tags.merge({ :platform => tag })
              .merge(record.select{ |key| (@tag_keys + @user_keys).include?(key) })

            @client.send_event(event)
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
