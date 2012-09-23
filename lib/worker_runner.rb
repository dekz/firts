require 'worker'
require 'timeout'

class WorkerRunner
  attr_accessor :workers, :ts, :pid
  def initialize opts={}
    @running = true
    @current_jobs = []

    if opts[:daemonize]
      @daemonize = true
      @pid = Process.pid
      File.write("firts-wr-#{@pid}.pid", @pid)
    end

    create_workers opts
  end

  def create_workers opts
    worker_count = opts[:worker_count] || 1
    puts "Creating #{worker_count} workers"
    @workers = worker_count.times.map do
      Worker.new(opts)
    end
  end

  def running?
    @running
  end

  def stop
    @running = false
  end

  def cleanup
    stop
    @workers.each do |worker|
      worker.cleanup
    end
    @workers.clear
  ensure
    if @daemonize
      File.delete("firts-wr-#{@pid}.pid")
    end
  end

  def run
    retry_times = 3
    retry_count = 0
    while running? do
      workers.each do |worker|
        begin
          # tell worker to check revoke status
          worker.job_stopped?
          # look for a new job if they don't have one
          worker.start_a_job unless worker.current_job
        rescue DRb::DRbConnError => e
          # Probably lost connection to TS
          retry_count += 1
          retry unless retry_count >= retry_times
          cleanup rescue nil
          puts "Lost connection to TupleSpace"
          exit 1
        end
      end
    end
  end
end

