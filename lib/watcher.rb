require 'rinda/ring'
require 'job'
require 'ringnotify'
require 'worker'

class Watcher
  attr_accessor :ts, :selectors, :watchers
  def initialize(opts = {})
    drb_init
    @ts = Utils::find_tuplespace opts
    raise "Unable to find TupleSpace" unless @ts
    @selectors = [
      Firts::Worker::WORKER_TEMPLATE,
      Job::START_TEMPLATE,
      Job::STOP_TEMPLATE,
      Job::COMPLETE_TEMPLATE,
      { 'worker' => nil, 'job' => nil },
      { 'worker' => nil, 'cmd' => nil }
    ]
  end

  def drb_init
      DRb.start_service
  end

  def watch
    puts "Watching..."
    @watchers = []
    selectors.each do |pattern|
      t = Thread.new do
        ns = RingNotify.new(ts, pattern)
        ns.each do |tuple|
          p "#{tuple} matched #{pattern}"
        end
      end
      @watchers << t
    end
    @watchers.each { |t| t.join }
  end
end

