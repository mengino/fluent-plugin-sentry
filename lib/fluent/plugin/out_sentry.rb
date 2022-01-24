require "fluent/plugin/output"
require "sentry-ruby"

module Fluent
  module Plugin
    class SentryOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("sentry", self)

      config_param :dsn, :string
      config_param :title, :string, :default => 'test'
      config_param :level, :enum, list: [:fatal, :error, :warning, :info, :debug], :default => 'info'
      config_param :environment, :string, :default => 'local'
      config_param :type, :enum, list: [:event, :exception], :default => :event
      # for event
      config_param :user_keys, :array, :default => [], value_type: :string
      config_param :tag_keys, :array, :default => [], value_type: :string
      config_param :data_keys, :array, :default => [], value_type: :string
      # for exception
      config_param :e_message, :string, :default => 'message'
      config_param :e_describe, :string, :default => 'describe'
      config_param :e_filename, :string, :default => 'filename'
      config_param :e_stack, :string, :default => 'stack'
      config_param :e_line, :string, :default => 'line'


      def initialize
        require 'time'

        super
      end

      def configure(conf)
        super

        config = Sentry::Configuration.new
        config.dsn = @dsn
        config.send_modules = false
        config.transport.timeout = 5

        @client = Sentry::Client.new(config)
      end

      def write(chunk)
        chunk.msgpack_each do |tag, time, record|
          begin
            event = Sentry::Event.new(configuration: @client.configuration)

            event.level = (record['level'] || @level).downcase
            event.environment = record['env'] || @environment

            if @type === :event
              log.warn(record, @tag_keys, @user_keys, @data_keys)
              event.message = record['message']
              event.user = record.select{ |key| @user_keys.include?(key) }
              event.extra = @data_keys.length() > 0 ? record.select{ |key| @data_keys.include?(key) } : record
              event.contexts = {'data' => { origin_data: record }}
              event.tags = event.tags.merge({ :tag => tag })
                .merge({ :timestamp => Time.at(time).strftime('%Y-%m-%d %H:%M:%S %Z') })
                .merge(record.select{ |key| (@tag_keys + @user_keys).include?(key) })
              event = event.to_hash
            elsif @type === :exception
              event = event.to_hash
              event['exception'] = Sentry::CustomExceptionInterface.new(
                type: record['message'] || '',
                message: (record[@e_describe] + (record[@e_line] ? (' on line:' + record[@e_line]) : '')) || '',
                stacktrace: Sentry::StacktraceInterface.new(frames: [Sentry::CustomStacktraceFrame.new(
                  filename: record[@e_filename] || '',
                  context_line: (record[@e_describe] + (record[@e_line] ? (' on line:' + record[@e_line]) : '')) || '',
                  post_context: record[@e_stack] || (record[@e_describe] || ''),
                )])
              ).to_hash
              event['tags'] = { :tag => tag }
                .merge({ :timestamp => Time.at(time).strftime('%d-%b-%Y %H:%M:%S %Z') })
                .merge(record.select{ |key| (@tag_keys + @user_keys).include?(key) })
            end

            event['logger'] = @title

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

module Sentry
  class CustomExceptionInterface < Sentry::Interface
    attr_reader :type
    attr_reader :message

    SKIP_INSPECTION_ATTRIBUTES = [:@stacktrace]

    def initialize(type:, message:, stacktrace: nil)
      @type = type
      @value = message
      @stacktrace = stacktrace
    end

    def to_hash
      data = super
      data[:stacktrace] = data[:stacktrace].to_hash if data[:stacktrace]
      data
    end
  end

  class CustomStacktraceFrame < Sentry::Interface
    attr_accessor :filename, :pre_context, :context_line, :post_context, :lineno

    def initialize(filename:, context_line:, pre_context: '', post_context: '', lineno: 1)
      @filename = filename
      @context_line = context_line
      @pre_context = pre_context.split("\n")
      @post_context = post_context.split("\n")
      @lineno = lineno
    end

    def to_hash(*args)
      data = super(*args)
      data.delete(:pre_context) unless pre_context && !pre_context.empty?
      data.delete(:post_context) unless post_context && !post_context.empty?
      data.delete(:context_line) unless context_line && !context_line.empty?
      data
    end
  end
end
