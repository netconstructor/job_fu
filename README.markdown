JobFu - Simple Asynchronous Processing
======================================

Simple Asynchronous Processing solution that uses the database as queue. There are plenty of plugins for off loading expense tasks to background workers, and this one is similar to delayed_job but simpler implementation. I was about to replace this solution with delayed_job because I needed the priority feature, but realized that it would take less effort to implement priority in to this project. I also added the possibility to send emails through the background workers.

Features
========

* Priority for new jobs
* Asynchronous deliver emails
* Daemon background worker
* Serialize ActiveRecord objects so they are re-fetched from database before processing

Install
=======

First install the plugin
		
    ruby script/plugin install git://github.com/jnstq/job_fu.git

Create the table migration for background jobs

    ruby script/generate migration create_jobs
    
Paste in the migration

    create_table :jobs do |t|
      t.column :priority,           :integer, :default => 0
      t.column :status,             :string,  :limit => 20
      t.column :status_description, :text
      t.column :processable,        :text
      t.column :processed_at,       :datetime
    end
    
    
Controll the background worker with start/stop/status

    ruby vender/plugins/job_fu/bin/job_ctl start
    

Jobs that are processed successfully will be deleted.

Example
=======

A background task is something that respond to process!

    class RemoteUpdater      
      def process!
        # something heavy
      end
    end

    # Using standard interface, add also aliased to enqueue
    JobFu::Job.add(RemoteUpdater.new)
    
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

Se the specs for more examples


Copyright (c) 2009 Jon Stenqvist, released under the MIT license