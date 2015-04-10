require 'sidekiq/util'

module Sidekiq
  module History
    class Middleware
      include Sidekiq::Util

      attr_accessor :msg

      def call(worker, msg, queue)
        self.msg = msg

        data = {
          started_at: Time.now.utc,
          payload: msg,
          worker: msg['class'],
          processor: "#{identity}-#{Thread.current.object_id}",
          queue: queue
        }

        Sidekiq.redis do |conn|
          # migration of list to set for backwards compatibility after v0.0.4
          if conn.type(LIST_KEY) == 'list'
            length = conn.llen(LIST_KEY)
            list = conn.lrange(LIST_KEY, 0, length)
            conn.del(LIST_KEY)
            list.each do |entry|
              migrated_data = JSON.parse(entry)
              conn.zadd(LIST_KEY, data[:started_at].to_f, Sidekiq.dump_json(migrated_data))
            end
          end

          # regular storage of history
          conn.zadd(LIST_KEY, data[:started_at].to_f, Sidekiq.dump_json(data))
          unless Sidekiq.history_max_count == false
            conn.zremrangebyrank(LIST_KEY, 0, -(Sidekiq.history_max_count + 1))
          end
        end

        yield
      end
    end
  end
end
