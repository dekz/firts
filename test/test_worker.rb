$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
require 'firts'
require 'timeout'
require 'rinda/ring'

DRb.start_service

ts = Rinda::RingFinger.primary
worker = Worker.new ts
File.write("#{worker.name}.pid", Process.pid)

while worker.running do
  sleep(0.1)
  worker.current_jobs.each do |job|
    if worker.job_stopped? job.id
      puts "#{worker.name}: Stop #{job.id}"
      worker.current_jobs.delete job
    end
  end

  worker.get_job do |job|
    if worker.job_stopped? job.id
      puts "Err: Job stopped before processed" 
      next
    end

    worker.current_jobs << job
    t0 = Time.now.to_r
    counter = 0
    begin
      Timeout::timeout(1) do
        puts "#{worker.name}: Run #{job.id}"
        job.run_proc
      end
    rescue Timeout::Error
    end
    puts "#{worker.name}: Done #{counter}"
    t1 = Time.now.to_r
    result = { :began => t0, :end => t1, :worker => worker.name }
    worker.job_done job, result
    worker.current_jobs.delete job
  end
end
