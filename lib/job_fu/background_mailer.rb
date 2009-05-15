module JobFu
  module BackgroundMailer
    
    def self.included(mailer)
      mailer.extend ClassMethods
    end
    
    module ClassMethods
      
      def method_missing(name, *args)
        if name.to_s =~ /^asynch?_deliver_(\S+)$/
          create_and_enqueue_mail($1, *args)
        else
          super
        end
      end
      
      private
      
      def create_and_enqueue_mail(mail_name, *args)
        mail = send(:"create_#{mail_name}", *args)
        Job.add ProcessableMethod.new(self, :deliver, mail)      
      end

    end
  end
end

