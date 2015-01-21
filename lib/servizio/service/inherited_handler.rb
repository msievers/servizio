module Servizio::Service::InheritedHandler
  def inherited(subclass)
    subclass.instance_eval do
      alias :original_new :new

      def self.inherited(subsubclass)
        subsubclass.extend(Servizio::Service::InheritedHandler)
      end

      def self.new(*args, &block)
        (obj = original_new(*args, &block)).singleton_class.send(:prepend, Servizio::Service::Call)
        return obj
      end
    end
  end
end
