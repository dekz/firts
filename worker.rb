require 'drb'
require 'rinda/tuplespace'
require './utils.rb'

class JobExists < Exception; end

Job = Struct.new(:id) do
  def to_s; @id; end
  def ==(j); j.id == id; end
end

class Worker

  attr_accessor :ts, :current_jobs, :running, :uri, :name
  def initialize(uri='druby://:12345')
    @uri = uri
    @current_jobs = []
    @running = true
    @name = "worker::#{Utils.random_str}"
    connect
  end

  def connect
    DRb.stop_service
    @ts = DRbObject.new_with_uri(@uri)
    DRb.start_service
    puts "#{name} connected to #{@uri}"
  end

  def job_stopped? job_id
    stop = ts.read([:stop, job_id], 0) rescue nil
    !stop.nil?
  end

  def get_job
    job = grab_job
    if job
      has_job = current_jobs.select { |j| j == job  }
      return yield job if has_job.empty?
      puts "Already have this job #{job.id}"
    end
  end

  def grab_job
    begin
      job = ts.take([:job, String], 0)
      job = Job.new(job[1])
    rescue Rinda::RequestExpiredError
    end
  end

  def job_done job, results
    ts.write [:job, :done, job.id, results]
  end
end

worker = Worker.new
while worker.running do
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

    t0 = Time.now.to_r
    worker.current_jobs << job
    puts "#{worker.name}: Run #{job.id}"
    t1 = Time.now.to_r
    result = { :began => t0, :end => t1, :msg => 'yay' }
    worker.job_done job, result
  end
  sleep 0.1
end
