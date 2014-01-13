module Sidekiq
  module History
    module WebExtension
      def self.registered(app)
        app.get '/history' do
          view_path = File.join(File.expand_path('..', __FILE__), 'views')

          @count = (params[:count] || 25).to_i
          (@current_page, @total_size, @messages) = page('history', params[:page], @count)
          @messages = @messages.map { |msg| Sidekiq.load_json(msg) }

          render(:erb, File.read(File.join(view_path, 'history.erb')))
        end

        app.post "/history/remove" do
          Sidekiq::History.reset_history(counter: params['counter'])
          redirect("#{root_path}history")
        end
      end
    end
  end
end
