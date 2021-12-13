require "helper"
require "fluent/plugin/out_sentry.rb"

class SentryOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::SentryOutput).configure(conf)
  end
end
