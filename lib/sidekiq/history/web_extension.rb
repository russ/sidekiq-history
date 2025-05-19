module Sidekiq
  module History
    module WebExtension
      ROOT = File.expand_path('../../../web', __dir__)

      # Helpers module provides utility methods for the Sidekiq History web extension.
      module Helpers
        # Fetches the query parameters or body from the request based on the Sidekiq version.
        #
        # Sidekiq 8.0 recommended `url_params` as a replacement for `params`.
        # This method ensures compatibility with both older and newer versions of Sidekiq.
        #
        # @param key [String] The key to fetch from the request.
        # @return [String, nil] The value associated with the key, or nil if not found.
        def request_params(key)
          if Gem::Dependency.new('', '>= 8.0.0').match?('', Gem.loaded_specs['sidekiq'].version)
            url_params(key.to_s)
          else
            params[key]
          end
        end
      end

      def self.registered(app)
        app.helpers Helpers

        app.get '/history' do
          @count = (request_params(:count) || 25).to_i
          (@current_page, @total_size, @messages) = page('history', request_params(:page), @count, reverse: true)
          @messages = @messages.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }

          render(:erb, File.read("#{ROOT}/views/history.erb"))
        end

        app.post '/history/remove' do
          Sidekiq::History.reset_history(counter: request_params(:counter))
          redirect("#{root_path}history")
        end

        app.get '/filter/history' do
          return redirect "#{root_path}history" unless request_params(:substr)

          @messages = search(HistorySet.new, request_params(:substr))
          render(:erb, File.read("#{ROOT}/views/history.erb"))
        end

        app.post '/filter/history' do
          return redirect "#{root_path}history" unless request_params(:substr)

          @messages = search(HistorySet.new, request_params(:substr))
          render(:erb, File.read("#{ROOT}/views/history.erb"))
        end

        if Gem::Dependency.new('', '< 8.0.0').match?('', Gem.loaded_specs['sidekiq'].version)
          app.settings.locales << File.expand_path('locales', ROOT)
        end
      end
    end
  end
end
