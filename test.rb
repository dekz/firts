require 'pry'
require 'drb'
require 'openssl'
require './utils.rb'

DRb.start_service
$ts = DRbObject.new_with_uri('druby://:12345')
job = [:job, Utils::random_str(15)]
job2 = [:job, Utils::random_str(15)]
stop_job = [:stop, job[1]]
stop_job2 = [:stop, job2[1]]

def clear_jobs
  stopped = []
  stop = $ts.take([:stop, nil], 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take([:stop, nil], 0) rescue nil
  end
  stop = $ts.take([:job, nil], 0) rescue nil
  while !stop.nil?
    stopped << stop
    stop = $ts.take([:job, nil], 0) rescue nil
  end
  stopped
end

pry
