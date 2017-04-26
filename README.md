# Sidekiq::History

A really simple addition to sidekiq web to enable a job history log.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-history'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-history

## Usage

Nothing left to do. Mount sidekiq, and go to the web interface. You'll see a shiny new History tab!

By default it will keep history on the last 1000 jobs.  To change that set `Sidekiq::History::Middleware::MAX_COUNT = 10000`.  Be careful because the data is persisted in Redis Sorted Set and it WILL take up RAM.  Max possible value is 4294967295 per Redis limit.

If you want to only record history for specific jobs you can set `Sidekiq::History::Middleware::EXCLUDE_JOBS = ['OneJob']` (do not record for specified jobs) and `Sidekiq::History::Middleware::INCLUDE_JOBS = ['AnotherJob']` (record ONLY jobs specified).  INCLUDE will take precedence so if you set it to blank array nothing will be recorded.

## Screenshot

![Web UI](https://github.com/russ/sidekiq-history/raw/master/examples/screenshot.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
