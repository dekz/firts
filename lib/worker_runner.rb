require 'timeout'

class WorkerRunner
  attr_accessor :workers, :ts, :pid
  def initialize opts={}
    @running = true
    @current_jobs = []
    @workers = []
    @workers << Worker.new(opts)
    trap :INT do
      cleanup
      exit 0
    end
  end

  def running?
    @running
  end

  def stop
    @running = false
  end

  def cleanup
    workers.each do |worker|
      worker.cleanup
      workers.delete worker
    end
  end

  def run
    while running? do
      workers.each do |worker|
        # tell worker to check revoke status
        worker.job_stopped?
        # look for a new job if they don't have one
        worker.start_a_job unless worker.current_job
      end
    end
  end
end

