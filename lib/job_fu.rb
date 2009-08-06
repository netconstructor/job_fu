require 'yaml'

module JobFu
  autoload :Serialization, 'job_fu/serialization'
  autoload :ProcessableMethod, 'job_fu/processable_method'
  autoload :AsynchInvokeMethod, 'job_fu/asynch_invoke_method'
  autoload :BackgroundMailer, 'job_fu/background_mailer'
  autoload :Job, 'job_fu/job'
  autoload :Backgrounded, 'job_fu/backgrounded'
end