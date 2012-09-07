require 'drb'
require 'rinda/tuplespace'
require 'rinda/ring'
require 'utils'
require 'job'

class Worker
  attr_accessor :ts, :current_jobs, :running, :name
  WORKER_TEMPLATE = [:name, :worker, String]
  def initialize(ts=nil)
    @current_jobs = []
    @running = true
    @name = "worker::#{Utils.random_str}"
    DRb.start_service
    @ts = ts
    connect
  end

  def connect
    @ts = Rinda::RingFinger.primary unless @ts
    puts "#{@name} connected to #{@ts.to_s}"
    Utils::repeat_every(30) { heartbeat }
  end

  def heartbeat
    # Let others know we're around
    me = WORKER_TEMPLATE.dup
    me[2] = name
    @heartbeat_entry ||= @ts.write(me, 30)
    @heartbeat_entry.renew(31) unless @heartbeat_entry.canceled?
  end

  def job_stopped? job_id
    st = Job::STOP_TEMPLATE.dup
    st['id'] = job_id
    stop = read st
    !stop.nil?
  end

  def read template, timeout=0, rescue_me=true
    if rescue_me 
      @ts.read(template, timeout) rescue nil
    else
      @ts.read(template, timeout)
    end
  end

  def take template, timeout=0, rescue_me=true
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
    ts.write jc
  end
end
