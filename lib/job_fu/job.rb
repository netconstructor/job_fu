# Kontrollera hur man smidigt gör en background mailer

module JobFu
  class Job < ActiveRecord::Base
    include Serialization
    named_scope :failures, :conditions => ["status = ?", 'failure']
    
    def self.next
      next_job = find(:first, :conditions => "status IS NULL", :order => 'priority DESC', :lock => true)
      if next_job
        next_job.mark_in_process!
      end
      next_job
    end
    
    def self.add(processable_object, priority = 0)
      create!(:processable => processable_object, :priority => priority)
    end
    class << self
      alias enqueue add
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
      rescue Exception => e
        self.status = "failure"
        self.status_description = "#{e.message} - #{e.backtrace.join("\n")}"
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
    end

  end
end
