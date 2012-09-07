require 'pry'
require 'drb'
require 'openssl'
require 'rinda/ring'
require 'irb'
require 'irb/completion'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
require 'firts'

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

$tm = Taskmaster.new $ts

IRB.start
