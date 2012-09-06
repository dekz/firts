require 'drb'
require 'rinda/tuplespace'
require 'rinda/ring'
require 'timeout'
require './utils.rb'
require './job.rb'
class Worker
  attr_accessor :ts, :current_jobs, :running, :uri, :name
  def initialize(uri='druby://:12345')
    @uri = uri
    @current_jobs = []
    @running = true
    @name = "worker::#{Utils.random_str}"

    DRb.start_service
    connect
  end

  def connect
    @ts = Rinda::RingFinger.primary
    puts "#{@name} connected to #{@ts.to_s}"
    Utils::repeat_every(30 ) { heartbeat }
  end

  def heartbeat
    # Let others know we're around
    me = [:name, :worker, name]
    @heartbeat_entry ||= @ts.write(me, 30)
    @heartbeat_entry.renew(31) unless @heartbeat_entry.canceled?
  end

  def job_stopped? job_id
    st = Job::STOP_TEMPLATE.dup
    st['id'] = job_id
    stop = read st
    !stop.nil?
  end

  def read template, timeout=0, rescue_me = true
    if rescue_me 
      @ts.read(template, timeout) rescue nil
    else
      @ts.read(template, timeout)
    end
  end

  def take template, timeout=0, rescue_me = true
    if rescue_me
      @ts.take(template, timeout) rescue nil
    else
      @ts.take(template, timeout)
    end
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
      #jt = { 'job' => :start, 'id' => String }
      jt = Job::START_TEMPLATE.dup
      job = take jt, 0, false
      job = Job.load job
    rescue Rinda::RequestExpiredError
    end
  end

  def job_done job, results
    jc = Job::COMPLETE_TEMPLATE.dup
    jc['id'] = job.id
    jc['result'] = results
    puts jc
    ts.write jc
  end
end

#1.times do
#  fork do
    worker = Worker.new
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
            loop do
              counter += 1
              job.prc.call if job.prc
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
