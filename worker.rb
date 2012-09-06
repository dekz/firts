require 'drb'
require 'rinda/tuplespace'
require 'timeout'
require './utils.rb'

class JobExists < Exception; end

Job = Struct.new(:id) do
  def to_s; @id; end
  def ==(j); j.id == id; end
  def self.load job
    j = Job.new job['id']
    j
  end
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
    st = { 'job' => :stop, 'id' => job_id }
    stop = ts.read(st, 0) rescue nil
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
      jt = { 'job' => :start, 'id' => String }
      job = ts.take(jt,  0)
      job = Job.load job
    rescue Rinda::RequestExpiredError
    end
  end

  def job_done job, results
    jt = { 'job' => :complete, 'id' => job.id, 'result' => results }
    puts jt
    ts.write jt
  end
end

#1.times do
#  fork do
    worker = Worker.new
    File.write("#{worker.name}.pid", Process.pid)
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

        worker.current_jobs << job
        t0 = Time.now.to_r
        counter = 0
        begin
          Timeout::timeout(1) do
            puts "#{worker.name}: Run #{job.id}"
            loop do
              counter += 1
            end
          end
        rescue Timeout::Error
        end
        puts "#{worker.name}: Done #{counter}"
        t1 = Time.now.to_r
        result = { :began => t0, :end => t1, :msg => 'yay' }
        worker.job_done job, result
        worker.current_jobs.delete job
      end
    end
#  end
#end
