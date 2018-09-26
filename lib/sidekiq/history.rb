require 'sidekiq/web'
require 'sidekiq/history/version'
require 'sidekiq/history/middleware'
require 'sidekiq/history/web_extension'

module Sidekiq
  def self.history_max_count=(value)
    @history_max_count = value
  end

  def self.history_max_count
    # => use default 1000 unless specified in config.
    # Max is 4294967295 per Redis Sorted Set limit
    hmc = if defined? MAX_COUNT
            [MAX_COUNT, 4_294_967_295].min
          else
            1000
          end
    return hmc if @history_max_count.nil?
    @history_max_count
  end

  def self.history_exclude_jobs=(value)
    @history_exclude_jobs = value
  end

  def self.history_exclude_jobs
    if defined? Sidekiq::History::Middleware::EXCLUDE_JOBS
      jobs = Sidekiq::History::Middleware::EXCLUDE_JOBS
    end
    return jobs if @history_exclude_jobs.nil?
    @history_exclude_jobs
  end

  def self.history_include_jobs=(value)
    @history_include_jobs = value
  end

  def self.history_include_jobs
    if defined? Sidekiq::History::Middleware::INCLUDE_JOBS
      jobs = Sidekiq::History::Middleware::INCLUDE_JOBS
    end
    return jobs if @history_include_jobs.nil?
    @history_include_jobs
  end

  module History
    LIST_KEY = :history

    def self.reset_history(options = {})
      Sidekiq.redis do |c|
        c.multi do
          c.del(LIST_KEY)
          c.set('stat:history', 0) if options[:counter] || options['counter']
        end
      end
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
