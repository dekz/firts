require 'rinda/ring'
require './ringnotify'
require './job.rb'

DRb.start_service

ts = Rinda::RingFinger.primary

patterns = [
  [:name, :worker, String],
  Job::START_TEMPLATE,
  Job::STOP_TEMPLATE,
  Job::COMPLETE_TEMPLATE,
]
watchers = []
patterns.each do |pattern|
  t = Thread.new do
    ns = RingNotify.new(ts, pattern)
    ns.each do |tuple|
      p tuple
    end
  end
  watchers << t
end

watchers.each { |t| t.join }
