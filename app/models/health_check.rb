class HealthCheck < ActiveRecord::Base
  belongs_to :site
  has_many :steps, :order => 'position ASC'
  has_many :check_runs
  has_many :recent_check_runs, :class_name => 'CheckRun', :order => 'created_at DESC', :limit => 50
  
  has_one :last_check_run, :class_name => 'CheckRun', :order => 'created_at DESC'
  
  named_scope :enabled, :conditions => { :enabled => true }

  has_permalink :name, :scope => :site_id
  
  validates_presence_of :site_id, :name
  
  def self.intervals
    [1, 2, 3, 5, 10, 15, 20, 30, 60]
  end
  
  def check_now?
    # This is a small and naive optimization to spread the check times more evenly
    # across the minutes of an hour. Most importantly, this makes sure that not every
    # check runs on the full hour.
    (Time.now.min + (interval / 6.375)).to_i % interval == 0
  end
  
  def to_param
    permalink
  end
  
  def self.from_param!(param)
    find_by_permalink!(param)
  end
  
  def check!
    runner = Runner.new(self)
    attrs = { :started_at => Time.now.to_f, :status => 'success' }

    retry_times = 3
    begin
      runner.run!
    rescue Exception => e
      retry_times -= 1
      retry unless retry_times == 0

      attrs[:status] = 'failure'
      attrs[:error_message] = "#{e.class.name}: #{e.message}"
    end
    attrs[:ended_at] = Time.now.to_f
    attrs[:log] = runner.log_entries

    check_runs.create(attrs)
  end
end
