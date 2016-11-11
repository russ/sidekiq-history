require 'sidekiq/web'
require 'sidekiq/history/version'
require 'sidekiq/history/middleware'
require 'sidekiq/history/web_extension'

module Sidekiq
  def self.history_max_count=(value)
    @history_max_count = value
  end

  def self.history_max_count
    # => use default 1000 unless specified in config.  Max is 4294967295 per Redis Sorted Set limit
    if defined? MAX_COUNT
      hmc = [MAX_COUNT, 4294967295].min
    else
      hmc = 1000
    end
    return hmc if @history_max_count.nil?
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
      Sidekiq.redis { |r| r.zcard(LIST_KEY) }
    end

    class HistorySet < Sidekiq::JobSet
      def initialize
        super LIST_KEY
      end
    end

  end

end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::History::Middleware
  end
end

Sidekiq::Web.register(Sidekiq::History::WebExtension)

if Sidekiq::Web.tabs.is_a?(Array)
  # For sidekiq < 2.5
  Sidekiq::Web.tabs << 'history'
else
  Sidekiq::Web.tabs['History'] = 'history'
end
