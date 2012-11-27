require 'utils'
class JobExists < Exception; end

class Job

  JOB_TEMPLATE = { 'type' => :job, 'job' => nil }
  STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
  COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }

  # Don't dump this object, but make the proc accessible to be ran remotely
  include DRb::DRbUndumped
  attr_accessor :id, :proc, :args, :result, :begin, :end
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
    obj = Object.new
    obj.instance_eval do
      begin
        prc = eval job.proc
        args = Job::grab_args job
        job.result = prc.call *args
      rescue Exception => e
        puts e
      rescue NameError => e
        puts e
      end
    end
    job.end = Time.now
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
end
