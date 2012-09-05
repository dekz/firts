require 'drb'
require 'rinda/tuplespace'

class JobExists < Exception; end

Job = Struct.new(:id) do
  def to_s
    @id
  end
  def ==(j)
    j.id == id
  end
end

class Worker
  attr_accessor :ts, :current_jobs, :running
  def initialize(uri='druby://:12345')
    @ts = DRbObject.new_with_uri(uri)
    @current_jobs = []
    @running = true
    DRb.start_service
  end

  def job_stopped? job_id
    stop = ts.read([:stop, job_id], 0) rescue nil
    !stop.nil?
  end

  def get_job
    job = grab_job
    if job
      has_job = current_jobs.select { |j| j == job  }
      yield job if has_job.empty?
      puts "Already have this job"
    end
  end

  def grab_job
    begin
      job = ts.take([:job, String], 0)
      job = Job.new(job[1])
    rescue Rinda::RequestExpiredError
    end
  end
end

worker = Worker.new
while worker.running do
  worker.current_jobs.each do |job|
    if worker.job_stopped? job.id
      puts "Stopping: #{job.id}"
      worker.current_jobs.delete job
    end
  end

  worker.get_job do |job|
    p job
    if worker.job_stopped? job.id
      puts "Err: Job stopped before processed" 
      next
    end
    puts "Running #{job.id}"
    worker.current_jobs << job
  end
end
