require 'rinda/ring'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
require 'job'
require 'ringnotify'

class Watcher
  attr_accessor :ts, :patterns, :watchers
  def initialize(opts = {})
    drb_init
    @ts = Utils::find_tuplespace opts
    raise "Unable to find TupleSpace" unless @ts
    @patterns = [
      [:name, :worker, String],
      Job::START_TEMPLATE,
      Job::STOP_TEMPLATE,
      Job::COMPLETE_TEMPLATE,
    ]
  end

  def drb_init
      DRb.start_service
  end

  def watch
    puts "Watching..."
    @watchers = []
    patterns.each do |pattern|
      t = Thread.new do
        ns = RingNotify.new(ts, pattern)
        ns.each do |tuple|
          p tuple
        end
      end
      @watchers << t
    end
    @watchers.each { |t| t.join }
  end
end

