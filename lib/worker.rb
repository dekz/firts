require 'drb'
require 'rinda/tuplespace'
require 'rinda/ring'
require 'utils'
require 'job'

class Worker
  attr_accessor :ts, :running, :name, :id, :current_job, :selectors
  WORKER_TEMPLATE = [:name, :worker, String]
  def initialize(opts = {})
    drb_init
    @id = Utils.random_str
    @name = "worker::#{@id}"
    @ts = Utils::find_tuplespace opts

    @pid = Process.pid
    File.write("#{@name}.pid", @pid)
    @current_job = nil
    @completed_jobs = []
    @running = true
    @job_exec_timeout = opts[:job_exec_timeout] || 300
    @job_search_timeout = opts[:job_search_timeout] || 0.1
    @heartbeat_refresh = opts[:heartbeat] || 10
    @threads = []

    @selectors = [
     [ Job::START_TEMPLATE.dup, Proc.new { |j| j } ],
     [ { 'worker' => @id, 'job' => nil }, Proc.new { |j| puts 'invididual job';j['job'] }  ],
    ]
    connect
  end

  def drb_init
    DRb.start_service
  end

  def connect
    puts "#{@name} connected to #{@ts.to_s}"
    Utils::repeat_every(@heartbeat_refresh) { heartbeat }
  end

  def cleanup
    puts "#{name} cleanup"
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
    File.delete("#{name}.pid")
  end

  # # Let others know we're around
  def heartbeat
    me = WORKER_TEMPLATE.dup
    me[2] = name
    @heartbeat_entry ||= @ts.write(me, @heartbeat_refresh + 10)
    @heartbeat_entry.renew(@heartbeat_refresh) unless @heartbeat_entry.canceled?
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
