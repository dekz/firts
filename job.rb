class JobExists < Exception; end

class Job
  START_TEMPLATE = { 'job' => :start, 'id' => nil, 'proc' => nil }
  STOP_TEMPLATE = { 'job' => :stop, 'id' => nil }
  COMPLETE_TEMPLATE = { 'job' => :complete, 'id' => nil, 'result' => nil }
  attr_accessor :id, :prc
  def initialize id, prc
    @id = id
    @prc = eval prc
  end

  def to_s
    @id
  end

  def ==(j)
    j.id == id
  end

  def self.load job
    j = Job.new job['id'], job['proc']
  end
end
