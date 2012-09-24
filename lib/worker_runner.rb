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
      File.write(my_pid_file, @pid)
    end

    create_workers opts
  end

  def my_pid_file
    "firts-wr-#{@pid}.pid"
  end

  def create_workers opts
    worker_count = opts[:worker_count] || 1
    log "Creating #{worker_count} workers"
    @workers = worker_count.times.map do
      Worker.new(opts)
    end
  end

  def log *args
    puts *args
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
    File.delete(my_pid_file) if @daemonize
  end

  def run
    retry_times = 3
    retry_count = 0
    while running? do
      stopped_workers = []
      workers.each do |worker|
        # Let's collect all the dead workers
        if worker.status != :running
          stopped_workers << worker
          next
        end

        begin
          if worker.current_job
            # tell worker to check revocation status
            worker.job_stopped?
          else
            # look for a new job if they don't have one
            #worker.start_a_job
          end
        rescue DRb::DRbConnError => e
          # Probably lost connection to TS
          retry_count += 1
          retry unless retry_count >= retry_times
          # Try and cleanup as much as possible
          worker.cleanup rescue nil
          stopped_workers << worker
          next
          #cleanup rescue nil
          log 'Lost connection to TupleSpace'
        end
      end

      # Something weird happens here when using attr_accessor, use iv @
      # cannot perform the "-" on Array and assign, nil TODO
      @workers = workers-stopped_workers
      @running = false if workers.size == 0
      sleep 0.1
    end
  ensure
    cleanup rescue nil
  end
end

