module Sidekiq
  module History
    module WebExtension
      ROOT = File.expand_path('../../../../web', __FILE__)

      def self.registered(app)
        app.get '/history' do
          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page('history', params[:page], @count)
          @messages = @messages.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }

          render(:erb, File.read("#{ROOT}/views/history.erb"))
        end

        app.post "/history/remove" do
          Sidekiq::History.reset_history(counter: params['counter'])
          redirect("#{root_path}history")
        end

        app.settings.locales << File.expand_path('locales', ROOT)
      end
    end
  end
end
