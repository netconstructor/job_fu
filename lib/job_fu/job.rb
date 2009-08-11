# Kontrollera hur man smidigt gör en background mailer

module JobFu
  class Job < ActiveRecord::Base
    include Serialization
    named_scope :next_in_queue, lambda {
      { :conditions => ["(status IS NULL) AND (process_at IS NULL OR process_at  <= ?)", time_now], :order => 'priority DESC' }
    }

    class << self
      attr_accessor :min_priority, :max_priority
    end

    def self.next
      next_job = next_in_queue
      next_job = next_job.scoped(:conditions => ['priority <= ?', max_priority]) if max_priority
      next_job = next_job.scoped(:conditions => ['priority >= ?', min_priority]) if min_priority
      next_job = next_job.first(:lock => true)

      if next_job
        next_job.mark_in_process!
      end
      next_job
    end

    def self.force_process_all!
      all(:order => 'priority DESC').each { |job| job.process! }
    end

    def self.add(processable_object, priority = 0, process_at = nil)
      create!(:processable => processable_object, :priority => priority, :process_at => process_at)
    end
    class << self
      alias enqueue add
    end

    def self.time_now
      Time.now.utc
    end

    def self.priority?
      min_priority || max_priority
    end

    def mark_in_process!
      self.status = "in_progress"
      self.processed_at = Time.now
      save!
    end

    def process!
      mark_in_process! if self.status == nil

      begin
        processable.process!
      rescue ActiveRecord::RecordNotFound
        self.status = 'deleted'
        delete
      rescue Exception => e
        self.status = "failure"
        self.status_description = "n#{e.message} - #{e.backtrace.join("\n")}"
        save!
      else
        self.status = 'processed'
        delete
      end
    end

    def processable=(job)
      self[:processable] = object_to_string(job)
      @_processable = job
    end

    def processable
      @_processable ||= object_from_string(self[:processable])
    rescue ActiveRecord::RecordNotFound
      nil
    end

  end
end
