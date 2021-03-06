require 'rinda/ring'
require 'job'
require 'ringnotify'
require 'worker'
require 'network'

class Watcher

  include Network
  attr_accessor :ts, :selectors, :watchers
  def initialize(opts = {})
    drb_init
    @ts = Utils::find_tuplespace opts
    raise "Unable to find TupleSpace" unless @ts
    @selectors = [
      Firts::Worker::WORKER_TEMPLATE,
      Job::JOB_TEMPLATE,
      Job::STOP_TEMPLATE,
      Job::COMPLETE_TEMPLATE,
      { 'worker' => nil, 'job' => nil },
      { 'worker' => nil, 'cmd' => nil }
    ]
  end

  def watch
    @watchers = []
    selectors.each do |pattern|
      t = Thread.new do
        ns = RingNotify.new(ts, pattern)
        ns.each do |tuple|
          puts "#{pattern}: #{tuple}"
        end
      end
      @watchers << t
    end
    @watchers.each { |t| t.join }
  end
end

