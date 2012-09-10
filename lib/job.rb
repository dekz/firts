class JobExists < Exception; end

class Job
  START_TEMPLATE = {
    'job' => :start,
    'id' => nil,
    'run' => nil,
  }

  STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
  COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }
  attr_accessor :id, :result, :run_begin, :run_end
  def initialize id, run_task
    @id = id
    @run_task = run_task
    @result = nil
  end

  def to_s
    @id
  end

  def ==(j)
    return j.id == id if self.class == j.class
    super
  end

  def self.load job
    j = Job.new job['id'], job['run']
  end

  def run_proc
    return if @run_task.nil?
    @run_begin = Time.now
    begin
      prc = eval @run_task['proc'] 
      args = grab_args
      @result = prc.call *args
    rescue NameError => e
      puts e
    rescue Exception => e
      puts e
    end
    @run_end = Time.now
    @result
  end

  def grab_args
    args = []
    if @run_task['args'].class == DRb::DRbObject
      @run_task['args'].each { |t| args << t }
    else
      args = *@run_task['args']
    end
    args
  end
end
