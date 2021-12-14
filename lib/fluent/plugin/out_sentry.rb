require "fluent/plugin/output"

module Fluent
  module Plugin
    class SentryOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("sentry", self)

      USER_KEYS = %w('id', 'username', 'email', 'ip_address')

      config_param :flush_interval, :time, :default => 1
      config_param :dsn, :string, :secret => true
      config_param :title, :string, :default => 'test log'
      config_param :level, :enum, list: [:fatal, :error, :warning, :info, :debug], :default => 'info'
      config_param :timestamp, :string, :default => 'timestamp'
      config_param :environment, :string, :default => 'dev'

      config_param :user_keys, :array, :default => [], value_type: :string
      config_param :tag_keys, :array, :default => [], value_type: :string
      config_param :keys, :array, :default => [], value_type: :string

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

        if @dsn.nil?
          raise Fluent::ConfigError, "sentry: missing parameter for 'dsn'"
        end

        # Sentry.init do |config|
        #   config.dsn = @dsn
        #   config.environment = @environment
        #   config.send_modules = false
        #   config.transport.timeout = 5
        #   config.before_send = lambda do |event, hint|
        #     event.contexts.delete(:os)
        #     event.contexts.delete(:runtime)

        #     event.release = nil
        #     event.platform = nil
        #     event.sdk = nil

        #     event
        #   end
        # end

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
            # Sentry.with_scope do |scope|
            #   scope.set_user(record.select{ |key| @user_keys.include?(key) })
            #   scope.set_tags(record.select{ |key| (@tag_keys + @user_keys).include?(key) })
            #   scope.set_tag(:timestamp, record[@timestamp] || Time.at(time).utc.strftime('%Y-%m-%d %H:%M:%S'))
            #   scope.set_extras(@keys.length() > 0 ? record.select{ |key| @keys.include?(key) } : record)
            #   scope.set_context('data', { origin_data: record })

            #   event = Sentry.capture_event(Sentry::Event.new(
            #     configuration: Sentry.get_current_hub.configuration,
            #     message: @title
            #   ))
            # end


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
