require 'drb'
require 'rinda/tuplespace'
require 'rinda/ring'
require 'utils'
require 'job'
require 'command'
require 'network'

class Firts::Worker
  include Network
  include Network::Reader
  include Network::Writer
  attr_accessor :ts, :running, :name, :id, :current_job, :selectors

  WORKER_TEMPLATE = { 'name' => String, 'type' => :worker }
  def initialize(opts = {})
    drb_init
    @id = opts[:name] || Utils.random_str
    @name = "worker::#{@id}"

    @pid = Process.pid
    File.write(my_pid_file, @pid)
    @current_job = nil
    @completed_jobs = []
    @running = true

    @job_exec_timeout = opts[:job_exec_timeout] || 300
    @job_search_timeout = opts[:job_search_timeout] || 0.1
    @heartbeat_refresh = opts[:heartbeat] || 10

    @threads = []

    # Selector, Processor, Executor
    # Processor calls #process or #call
    # Executor calls #load or #call
    @selectors = [
     # Any worker job
     [ Job::JOB_TEMPLATE.dup, Proc.new { |j| j }, Job ],
     # Specific Job for me
     [ { 'worker' => @id, 'job' => nil }, Proc.new { |j| j['job'] }, Job  ],
     # Some form of Command Job
     [ { 'worker' => @id, 'cmd' => nil }, Command , Command ],
    ]

    connect opts
  end

  def status
    return :running if @running
    :dead
  end

  def my_pid_file
    "#{@name}.pid"
  end

  # Connect to TupleSpace and turn on a heart beat to keep us alive in there
  def connect opts
    @ts = find_tuplespace opts
    puts "#{@name} connected to #{@ts.to_s}"
    t = Utils::repeat_every(@heartbeat_refresh) do
      begin
        heartbeat
      rescue Exception => e
        @heartbeat_entry = nil
        @running = false
        cleanup rescue nil
        raise e
      end
    end
  end

  # Let others know we're around
  def heartbeat
    me = WORKER_TEMPLATE.dup
    me['name'] = id
    @heartbeat_entry ||= write(me, @heartbeat_refresh + 10)
    @heartbeat_entry.renew(@heartbeat_refresh) unless @heartbeat_entry.canceled?
  end

  def cleanup publish=true
    puts "#{name} cleanup"
    @running = false
    if @current_job
      result = {}
      result[:began] = @current_job.run_begin rescue nil
      result[:end] = @current_job.run_end rescue nil
      result[:result] = @current_job.result rescue 'Killed - Cleanup'
      result[:worker] = name

      job_done(@current_job, result) if publish
    end
    @heartbeat_entry.cancel if @heartbeat_entry
  ensure
    File.delete(my_pid_file)
    drb_close
  end


  ## Check if our job has been cancelled
  def job_stopped? job=@current_job
    return false unless job and job.respond_to? :run_proc
    job_id = job.id
    st = Job::STOP_TEMPLATE.dup
    st['id'] = job_id
    stop = read st
    if stop
      puts "#{name}: Asked to stop #{@current_job.id}"
      @current_job = nil
    end
    !stop.nil?
  end


  def start_a_job
    get_job do |job|
      @current_job = job
      @threads << run_job(job)
    end
  end

  def run_cmd cmd
      time_before = Time.now
      cmd.run_cmd self
      time_after = Time.now
      result = {
        :began => time_before,
        :end => time_after,
        :worker => name,
        :result => nil
      }
      job_done cmd, result
      @completed_jobs << @current_job
      @current_job = nil
  end

  def run_job job
    return run_cmd job if job.respond_to? :run_cmd
    puts "Err: Job stoped before processing #{job.id}" if job_stopped? job.id
    job_thread = Thread.new do |t|
      begin
        Timeout::timeout(@job_exec_timeout) do
          puts "#{name}: Run #{job.id}"
          Job::run job
        end
      rescue Timeout::Error
          puts "#{name}: Job timeout #{job.id}"
          job.result = 'Timeout'
      ensure
          @current_job = nil
          result = {
            :began => job.begin,
            :end => job.end,
            :worker => name,
            :result => job.result
          }
          job_done job, result
          @completed_jobs << job
      end
    end
    job_thread
  end

  # Rotate through selectors and return one to use
  def selector
    s = @selectors.pop
    @selectors.unshift s
    s
  end

  ##
  # Grab a job from by searching on one of our selectors
  # job is yielded.
  def get_job
    begin
      s, sproc, clazz = selector
      # Take the job from TS using the job selector
      job = take s, 0, false

      # Remove job from envelope
      sproc_meth = sproc.respond_to?(:process) ? :process : :call
      job = sproc.send sproc_meth, job

      yield job['job']
    rescue Rinda::RequestExpiredError => e
      # This happens when the lookup expires, it's an OK exception
      # TODO use wait time in take?
      sleep @job_search_timeout
    end
  end

  # Write job completion to TS
  def job_done job, results
    puts "#{name}: Done #{job.id}"
    jc = Job::COMPLETE_TEMPLATE.dup
    jc['id'] = job.id
    jc['result'] = results
    ts.write jc
  end

end
