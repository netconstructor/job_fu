JobFu - Simple Asynchronous Processing
======================================

Simple Asynchronous Processing solution that uses the database as queue. There are plenty of plugins for off loading expense tasks to background workers, and this one is similar to delayed_job but simpler implementation. I was about to replace this solution with delayed_job because I needed the priority feature, but realized that it would take less effort to implement priority in to this project. I also added the possibility to send emails through the background workers.

Features
========

* Priority for new jobs
* Asynchronous deliver emails
* Daemon background worker
* Serialize ActiveRecord objects so they are re-fetched from database before processing
* Setup workers and their priority scope in config/job_fu.yml

Install
=======

Install the daemons gem, where the patch from Chris Kline's in applyed, it will "Making sure Ruby Daemons die" from http://blog.rapleaf.com/dev/?p=19.

    sudo gem install FiXato-daemons --source http://gems.github.com    

Use can also add this line, to be explicit about the dependency

    # In you environemnt.rb
    config.gem 'FiXato-daemons', :lib => false, :source => 'http://gems.github.com'
    

Then install the plugin
		
    ruby script/plugin install git://github.com/jnstq/job_fu.git

Create the table migration and the background job dameon with

    ruby script/generate job_fu
    
This will generate the migration

    create_table :jobs do |t|
      t.column :priority,           :integer, :default => 0
      t.column :status,             :string,  :limit => 20
      t.column :status_description, :text
      t.column :processable,        :text
      t.column :processed_at,       :datetime
    end
    
Run the rake db:migrate

    rake db:migrate
    
Controll the background worker with start/stop/status

    ruby script/job_fu start
    ruby script/job_fu stop
    ruby script/job_fu status
        
If you want to set a different Rails environment then production, use

    RAILS_ENV=development ruby script/job_fu start
    
If you have some problem to start the worker, add -t to run on top.   

Include the JobFu::AsynchInvokeMethod in normal classes and JobFu::BackgroundMailer for classes derived from ActiveMailer::Base. It will enable you to call all methods with async-syntax

    class Foo
      include JobFu::AsynchInvokeMethod   
      def bar(arg1, arg2)
      edn
    end

    foo.asynch_bar(this, arguments)
    or 
    foo.async_bar(this, arguments)
   

Example
=======

A background task is something that respond to process!

    class RemoteUpdater      
      def process!
        # something heavy
      end
    end

    # Using standard interface, add also aliased to enqueue
    priority = 4
    JobFu::Job.add RemoteUpdater.new, priority
    
    class RemoteUpdater < ActiveRecord::BAse
      include JobFu::AsynchInvokeMethod
      def fetch_lat_and_long_for(user)
        # perform lookup
      end
    end
    
    # Using asynch_ syntax
    # AsynchInvokeMethod has to be included
    remote_updater = RemoteUpdater.new
    remote_updater.asynch_fetch_lat_and_long_for(@user)


AsynchInvokeMethod will create a ProcessableMethod wrapper to invoke the method with the given args later on. ActiveRecord::Base objects will be serialized as "AR:{ClassName}:{ID}". A fresh ActiveRecord object will be fetched before the method is executed. The same serialization is used for method arguments.

    class Mailer < ActiveMailer::Base
      include JobFu::BackgroundMailer
      
      def signup_notification(user)
        recipients user.email
        from "do-not-replay@app_name.com"
        body "Body of email message"
      end
    end

The BackgroundMailer will enable call for

    Mailer.asynch_deliver_signup_notification(@user)

This will create a new mail, and use ProcessableMethod to wrap call for Mailer.deliver(mail). We are creating the mail in the main process of the applicaiton to be able to read virutal attributes as, for example, a password. Otherwise this information wouldn't be avalible the next time it's fetched form the database.

Jobs that are processed successfully will be deleted.

Se the specs for more examples

Backgrounded
============

JobFu is packaged with Backgrounded handler out of the box. read more on http://github.com/wireframe/backgrounded/tree/master. Basically it allow syntax as

    #declaration
    class User
      backgrounded :do_stuff
      def do_stuff
        # do all your work here
      end
    end

    #usage
    user = User.new
    user.do_stuff_backgrounded


Configuration
-------------

    # rails config/initializers/backgrounded.rb
    Backgrounded.handler = JobFu::Backgrounded::Handler.new


Production
==========

Monit
-----

Example monit script to ensure that job_daemon is always running.

    check process job_daemon with pidfile /path/to/your/webapp/log/job.pid
    start program = "/usr/bin/ruby /path/to/your/webapp/script/job_ctl start" as uid deploy and gid deploy
    stop program = "/usr/bin/ruby /path/to/your/webapp/script/job_ctl stop"
    if totalmem is greater than 120.0 MB for 4 cycles then restart
    if cpu is greater than 90% for 8 cycles then restart
    if 20 restarts within 20 cycles then timeout
    group job_daemon

Capistrano
----------

Stop and start job_daemon on deployment

    set :job_daemon_monit_name, 'job_daemon'

    namespace :job do
      before 'deploy', 'deploy:job:stop'
      task :stop do
        sudo "/usr/local/bin/monit stop #{job_daemon_monit_name}"
      end
      after 'deploy', 'deploy:job:start'
      task :start do
        sudo "/usr/local/bin/monit start #{job_daemon_monit_name}"
      end
    end
    
Gotchas
=======

I have had problem with error "MySQL has gone away", even if the reconnet option is turend on in config/database.yml. The following code has been added to job-daemon to avoid it.

    [ActiveRecord::Base].each do |klass|
      klass.connection.verify!(15)
    end
    

Copyright (c) 2009 Jon Stenqvist, released under the MIT license