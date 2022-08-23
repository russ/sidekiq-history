require 'sidekiq/component'

module Sidekiq
  module History
    class Middleware
      include Sidekiq::Component

      attr_accessor :msg

      def call(_worker, msg, queue)
        self.msg = msg

        # Use the Sidekiq API to unwrap the job
        job = sidekiq_job_class.new(msg)
        job_class = job.display_class

        # Setup a unwraped copy of the bare job data
        payload = msg.dup
        payload['class'] = job_class
        payload['args'] = job.display_args

        data = {
          started_at: Time.now.utc,
          payload: payload,
          worker: job_class,
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
              if record_history(job_class) == true
                conn.zadd(LIST_KEY, data[:started_at].to_f,
                          Sidekiq.dump_json(migrated_data))
              end
            end
          end

          # regular storage of history
          if record_history(job_class) == true
            conn.zadd(LIST_KEY, data[:started_at].to_f, Sidekiq.dump_json(data))
          end
          unless Sidekiq.history_max_count == false
            conn.zremrangebyrank(LIST_KEY, 0, -(Sidekiq.history_max_count + 1))
          end
        end

        yield
      end

      private

      # check if this job should be recorded
      def record_history(job_class)
        # first check inclusion, when present
        # it will take precedence over exclude
        if !Sidekiq.history_include_jobs.nil?
          return Sidekiq.history_include_jobs.include?(job_class)
        elsif !Sidekiq.history_exclude_jobs.nil?
          return !Sidekiq.history_exclude_jobs.include?(job_class)
        end

        true
      end

      def sidekiq_job_class
        @sidekiq_job_class ||= begin
          actual = Gem.loaded_specs['sidekiq'].version
          if Gem::Dependency.new('', '>= 6.2.2').match?('', actual)
            # Renamed internal API class Sidekiq::Job to Sidekiq::JobRecord,
            # since 6.2.2. See: https://bit.ly/3gtxViK
            Sidekiq::JobRecord
          else
            Sidekiq::Job
          end
        end
      end
    end
  end
end
