require 'drb'
require 'rinda/ring'
require 'utils'
require 'job'
require 'worker'

# Avengers Ahoy!
class Taskmaster
  def initialize(ts=nil)
    @ts = ts
    if ts.nil?
      DRb.start_service
      @ts = Rinda::RingFinger.primary
    end
  end

  ##
  # Runs the job on a remote worker. Args passed in here
  # will either be Marshalled or a Reference (DRbObject)
  # will be sent over.
  def run_job *args, &block
    require 'sourcify'
    block_string = block.to_source
    jt = Job::START_TEMPLATE.dup
    jt['id'] = Utils::random_str
    jt['run'] = {
      'proc' => block_string,
      'args' => args
    }
    @ts.write jt
    jt['id']
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
