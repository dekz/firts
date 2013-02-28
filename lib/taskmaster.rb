require 'drb'
require 'rinda/ring'
require 'utils'
require 'job'
require 'worker'
require 'network'
require 'logger'

# Avengers Ahoy!
class Taskmaster
  include Network
  include Network::Reader
  include Network::Writer
  attr_accessor :ts
  def initialize(opts = {})
    drb_init
    @opts = opts
    @opts[:log] ||= $stdout
    @ts = find_tuplespace opts
    raise "Unable to find TupleSpace" unless @ts
  end

  ##
  # Runs the job on a remote worker. Args passed in here
  # will either be Marshalled or a Reference (DRbObject)
  # will be sent over.
  def run_job job, worker=nil, timeout=30
    publish_job job, worker
    receive_result job, timeout
  end

  def run_jobs jobs, timeout=30
    jobs.each do |j|
      publish_job j
    end

    jobs_done = 0
    jobs_total_count = jobs.size
    results = []
    while jobs_done != jobs_total_count
      job = jobs[0]
      found = receive_result job, timeout rescue :not_found
      if found != :not_found
        results << found
        jobs_done += 1
        jobs.delete_at(0)
      end
    end
    results
  end

  def run_all job, timeout=30
    workers.each do |worker|
      publish_job job, worker['name']
    end
    workers.size.times do
      receive_result job, timeout
    end
  end

  # Specifies a job, how many times to run the job and optional worker
  # specified to run the job.
  def task_list
    tasks = Struct.new(:num, :job, :worker).new
    yield tasks
    results = []
    Array(tasks[:job]).each do |job|
      job_results = []
      num = tasks[:num] || 1
      num.times do |i|
        job_results.push run_job(job, tasks[:worker])
      end
      results << job_results
    end
    results
  end

  def publish_job job, worker=nil
    jt = Job::JOB_TEMPLATE.dup
    jt['job'] = job

    jt = { 'worker' => worker, 'job' => jt } if worker
    job.logger = logger unless job.logger

    write jt
  end

  def logger
    @logger ||= Logger.new(opts[:log])
    @logger
  end

  def logger=(log)
    @logger = log
  end

  def receive_result job, timeout
    jc = Job::COMPLETE_TEMPLATE.dup
    jc['id'] = job.id
    job = take jc, timeout
  end

  def clear_jobs
    stopped = []
    temps = [ Job::JOB_TEMPLATE, Job::STOP_TEMPLATE ]
    temps.each do |t|
      begin
        stop = take(t, 0, true)
        (stopped << stop) if stop
      end while !stop.nil?
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
      job =  take(jt, timeout, true)
      return completed unless job
      completed ||= []
      completed << job
    end
    completed
  end

  def workers
    wt = Firts::Worker::WORKER_TEMPLATE
    read_all(wt)
  end
  def close
    drb_close
  end
end
