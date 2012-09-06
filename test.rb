require 'pry'
require 'drb'
require 'openssl'
require './utils.rb'
require 'rinda/ring'

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

job = { 'job' => :start, 'id' => Utils::random_str(15) }
job2 = { 'job' => :start, 'id' => Utils::random_str(15) }
stop_job = { 'job' => :stop, 'id' => job['id'] }
stop_job2 = { 'job' => :stop, 'id' => job2['id'] }

def clear_jobs
  stopped = []
  st = { 'job' => :stop, 'id' => nil }
  stop = $ts.take(st, 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take(st, 0) rescue nil
  end

  jt = { 'job' => :start, 'id' => nil }
  stop = $ts.take(jt, 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take(jt, 0) rescue nil
  end
  stopped
end

def completed_jobs
  stopped = []
  while stop = jobs_complete?
    stopped << stop
  end
  stopped
end

def jobs_complete? num=1, timeout=30
  completed = []
  num.times do 
    jt = { 'job' => :complete, 'id' => nil, 'result' => nil }
    puts jt
    job =  $ts.take(jt, timeout) rescue nil
    return completed unless job
    completed << job
  end
  completed
end

pry
