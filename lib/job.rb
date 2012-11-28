require 'utils'
require 'logger'
class JobExists < Exception; end

class Job

  JOB_TEMPLATE = { 'type' => :job, 'job' => nil }
  STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
  COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }
  def self.logger_local
    unless @logger_local
      @logger_local ||= ::Logger.new($stdout)
      @logger_local.level = ::Logger::INFO
    end
    @logger_local
  end

  # Don't dump this object, but make the proc accessible to be ran remotely
  include DRb::DRbUndumped
  attr_accessor :id, :proc, :args, :result, :begin, :end, :running, :logger
  def self.job *args, &block
    a = self.new
    if block_given?
      require 'sourcify'
      a.proc = block.to_source
      a.args = *args
    else
      args, source = *args
      a.args = *args
      a.proc = source
    end
    a.id = Utils.random_str
    a
  end

  class << self
    alias :create :job
  end

  # Grab args out of DRbObjects if required
  def self.grab_args job
    args = []
    if job.args.class == DRb::DRbObject
      job.args.each { |t| args << t } if job.args.respond_to? :each
    else
      args = *job.args
    end
    args
  end

  # Run the Proc passing in the args to the proc
  def self.run job
    job.begin = Time.now
    job.running = true
    t = Thread.new do
      obj = Object.new
      obj.instance_eval do
        begin
          prc = eval job.proc
          args = Job::grab_args job
          job.result = prc.call *args
        rescue Exception => e
          Job::handle_exception(job, e)
        rescue NameError => e
          Job::handle_exception(job, e)
        end
        log job, "complete"
      end
    end
    while t.alive?
      if job.stopped?
        t.kill
        log job, "stopped"
      end
      sleep 1
    end
    job.running = false
    job.end = Time.now
  end

  # Executes on remote
  def self.log(job, msg, level=:info)
    msg = job.instance_eval { "Job::#{id} #{msg}" }
    # Puts into local worker log
    logger_local.send(level, msg)
    # Puts back into caller log
    job.log msg, level
  end

  # Executes on caller
  def log(msg, level=:info)
    logger.send(level, msg) if logger
  end

  def self.handle_exception(job, e)
    msg = job.instance_eval { "Job::#{id} Error #{e.message}" }
    job.log(msg, :error)
    logger_local.send(:error, msg)
    logger_local.send(:error, e.backtrace)
    raise e
  end

  # Execute locally to test proc and args
  def dry_run
    Job::run self
  end

  # Simple dup of a job, creating a new job with a new id
  def dup
    a = self.class.new
    a.args = args.map { |arg| arg.dup }
    a.proc = self.proc.dup
    a.id = Utils.random_str
    a
  end

  def stop
    @running = false
    true
  end

  def stopped?
    !@running
  end

end
