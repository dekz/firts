require 'pry'
require 'drb'
require 'openssl'
require 'rinda/ring'
require './utils.rb'
require './job.rb'

DRb.start_service
#$ts = DRbObject.new_with_uri('druby://:12345')
$ts = Rinda::RingFinger.primary
#finger = Rinda::RingFinger.new(['<broadcast>', 'localhost'])
puts 'Looking for Finger broadcast'
#finger = Rinda::RingFinger.new(['<broadcast>', 'localhost'])
#$ts = nil
#finger.lookup_ring do |a|
#  $ts = a
#  puts 'Found finger broadcast ' + $ts.inspect
#end
p $ts

job = Job::START_TEMPLATE
job['id'] = Utils::random_str
job2 = Job::START_TEMPLATE
job2['id'] = Utils::random_str

stop_job = Job::STOP_TEMPLATE
stop_job['id'] = job['id']
stop_job2 = Job::STOP_TEMPLATE
stop_job2['id'] = job2['id']

def clear_jobs
  stopped = []
  st = Job::STOP_TEMPLATE
  stop = $ts.take(st, 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take(st, 0) rescue nil
  end

  jt = Job::START_TEMPLATE
  stop = $ts.take(jt, 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take(jt, 0) rescue nil
  end
  stopped
end

def completed_jobs timeout=0
  stopped = []
  while stop = jobs_complete?(1, timeout)
    stopped << stop
  end
  stopped
end

def jobs_complete? num=1, timeout=10
  completed = nil
  num.times do 
    jt = Job::COMPLETE_TEMPLATE
    job =  $ts.take(jt, timeout) rescue nil
    return completed unless job
    completed ||= []
    completed << job
  end
  completed
end

def run_job &block
  require 'sourcify'
  block_string = block.to_source
  jt = Job::START_TEMPLATE.dup
  jt['proc'] = block_string
  $ts.write jt
  p jt
end

require 'irb'
IRB.start
