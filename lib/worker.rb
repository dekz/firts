require 'drb'
require 'rinda/tuplespace'
require 'rinda/ring'
require 'utils'
require 'job'

class Worker
  attr_accessor :ts, :running, :name, :id, :current_job, :selectors

  WORKER_TEMPLATE = { 'name' => String, 'type' => :worker }
  def initialize(opts = {})
    drb_init
    @id = Utils.random_str
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
    @selectors = [
     # Any worker job
     [ Job::START_TEMPLATE.dup, Proc.new { |j| j } ],
     # Specific Job for me
     [ { 'worker' => @id, 'job' => nil }, Proc.new { |j| j['job'] }  ],
    ]

    connect opts
  end

  def status
    return :running if @running
    :dead
  end

  def drb_init
    DRb.start_service
  end

  def my_pid_file
    "#{@name}.pid"
  end

  def connect opts
    @ts = Utils::find_tuplespace opts
    puts "#{@name} connected to #{@ts.to_s}"
    t = Utils::repeat_every(@heartbeat_refresh) do
      begin
        heartbeat
      rescue Exception => e
        puts e
        @heartbeat_entry = nil
        @running = false
        cleanup rescue nil
        raise e
      end
    end
  end

  # # Let others know we're around
  def heartbeat
    me = WORKER_TEMPLATE.dup
    me['name'] = id
    @heartbeat_entry ||= @ts.write(me, @heartbeat_refresh + 10)
    @heartbeat_entry.renew(@heartbeat_refresh) unless @heartbeat_entry.canceled?
  end

  def cleanup
    puts "#{name} cleanup"
    @running = false
    if @current_job
      result = {
        :began => @current_job.run_begin || nil,
        :end => @current_job.run_end || nil,
        :worker => name,
        :result => @current_job.result || "Killed - Cleanup"
      }

      job_done @current_job, result
    end
    @heartbeat_entry.cancel if @heartbeat_entry
  ensure
    File.delete(my_pid_file)
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

  def read template, timeout=0, rescue_me=true
    @ts.read(template, timeout)
  rescue Exception => e
    raise e unless rescue_me
  end

  def take template, timeout=0, rescue_me=true
    @ts.take(template, timeout)
  rescue Exception => e
    raise e unless rescue_me
  end

  def start_a_job
    get_job do |job|
      puts "Err: Job started before processing #{job.id}" if job_stopped? job.id
      @threads = []
      @current_job = job
      run_job @current_job
    end
  end

  def run_job job
    @threads << Thread.new do |t|
      begin
        Timeout::timeout(@job_exec_timeout) do
          puts "#{name}: Run #{@current_job.id}"
          job.run_proc
        end
      rescue Timeout::Error
          puts "#{name}: Job timeout #{@current_job.id}"
          @current.job.result = "Timeout"
      end
      result = {
        :began => job.run_begin,
        :end => job.run_end,
        :worker => name,
        :result => job.result
      }
      job_done job, result
      @completed_jobs << @current_job
      @current_job = nil
    end
  end

  def selector
    s = @selectors.pop
    @selectors.unshift s
    s
  end

  def get_job
    begin
      s, sproc = selector
      job = take s, 0, false
      job = sproc.call job

      job = Job.load job
      yield job
    rescue Rinda::RequestExpiredError
      # TODO use wait time in take?
      sleep @job_search_timeout
    end
  end

  def job_done job, results
    puts "#{name}: Done #{job.id}"
    jc = Job::COMPLETE_TEMPLATE.dup
    jc['id'] = job.id
    jc['result'] = results
    ts.write jc
  end

end
