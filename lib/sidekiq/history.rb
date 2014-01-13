begin
  require "sidekiq/web"
rescue LoadError
  # client-only usage
end

require "sidekiq/history/version"
require "sidekiq/history/middleware"
require "sidekiq/history/web_extension"

module Sidekiq
  def self.history_max_count=(value)
    @history_max_count = value
  end

  def self.history_max_count
    return 1000 if @history_max_count.nil?
    @history_max_count
  end

  module History
    LIST_KEY = :history

    def self.reset_history(options = {})
      Sidekiq.redis { |c|
        c.multi do
          c.del(LIST_KEY)
          c.set('stat:history', 0) if options[:counter] || options['counter']
        end
      }
    end

    def self.count
      Sidekiq.redis { |r| r.llen(LIST_KEY) }
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::History::Middleware
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register(Sidekiq::History::WebExtension)

  if Sidekiq::Web.tabs.is_a?(Array)
    # For sidekiq < 2.5
    Sidekiq::Web.tabs << "history"
  else
    Sidekiq::Web.tabs['History'] = 'history'
  end
end
