require 'drb'
require 'rinda/ring'
require 'utils'
require 'job'
require 'worker'

# Avengers Ahoy!
class Taskmaster
  attr_accessor :ts
  def initialize(opts = {})
    drb_init
    @ts = Utils::find_tuplespace opts
    raise "Unable to find TupleSpace" unless @ts
  end

  def drb_init
    DRb.start_service
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
    p 'runall'
    workers.each do |worker|
      p worker
      id = worker[2].gsub("worker::", '')
      p id
      publish_job job, id
    end
    workers.size.times do
      receive_result job, timeout
    end
  end

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
    require 'sourcify'
    block_string = job.run_task['proc'].to_source
    jt = Job::START_TEMPLATE.dup
    jt['id'] = job.id
    jt['run'] = {
      'proc' => block_string,
      'args' => job.run_task['args']
    }
    if worker
      puts "Publishing for worker"
      jt = { "worker" => worker, "job" => jt }
    end
    @ts.write jt
  end

  def receive_result job, timeout
    jc = Job::COMPLETE_TEMPLATE.dup
    jc['id'] = job.id
    job = @ts.take(jc, timeout)
  end

  def clear_jobs
    stopped = []
    st = Job::STOP_TEMPLATE
    stop = @ts.take(st, 0) rescue nil
    while !stop.nil?
      stopped << stop
      stop = @ts.take(st, 0) rescue nil
    end

    jt = Job::START_TEMPLATE
    stop = @ts.take(jt, 0) rescue nil
    while !stop.nil?
      stopped << stop
      stop = @ts.take(jt, 0) rescue nil
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
      job =  @ts.take(jt, timeout) rescue nil
      return completed unless job
      completed ||= []
      completed << job
    end
    completed
  end
  
  def workers
    wt = Worker::WORKER_TEMPLATE 
    @ts.read_all(wt) rescue nil
  end
end
