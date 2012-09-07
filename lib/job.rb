class JobExists < Exception; end

class Job
  START_TEMPLATE = {
    'job' => :start,
    'id' => nil,
    'run' => nil,
  }

  STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
  COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }
  attr_accessor :id 
  def initialize id, run_task
    @id = id
    @run_task = run_task
  end

  def to_s
    @id
  end

  def ==(j)
    j.id == id
  end

  def self.load job
    j = Job.new job['id'], job['run']
  end

  def run_proc
    return if @run_task.nil?
    begin
      prc = eval @run_task['proc'] 
      args = []
      if @run_task['args'].class == DRb::DRbObject
        @run_task['args'].each { |t| args << t }
      else
        args = *@run_task['args']
      end
      prc.call *args
    rescue NameError => e
      puts e
    end
  end
end
