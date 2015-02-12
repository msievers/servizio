require "active_model"

class Servizio::Service
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :result

  OperationFailedError = Class.new(StandardError)
  OperationInvalidError = Class.new(StandardError)
  OperationNotCalledError = Class.new(StandardError)

  # http://stackoverflow.com/questions/14431723/activemodelvalidations-on-anonymous-class
  def self.name
    super ? super : "__anonymous_servizio_service_class__"
  end

  # shortcut to call operations, which returns the result and/or throws errors
  def self.call(*args)
    operation = self.new(*args)

    if operation.valid?
      if operation.call!.succeeded?
        operation.result
      else
        raise Servizio::Service::OperationFailedError
      end
    else
      raise Servizio::Service::OperationInvalidError
    end
  end

  def result
    called? ? @result : (raise OperationNotCalledError)
  end

  def called?
    @called == true
  end

  def failed?
    called? && errors.present?
  end

  def succeeded?
    called? && errors.blank?
  end

  #
  # This code does some metaprogramming magic. It overwrites .new, so that every
  # instance of a class derived from Servizio::Service, gets a module prepended
  # automatically. This way, one can easily "wrap" the methods, e.g. #call.
  #
  module MethodDecorators
    module Call
      def call
        if valid?
          self.result = super
          @called = true
        else
          @called = false
        end

        self
      end

      alias_method :call!, :call
    end

    def inherited(subclass)
      subclass.instance_eval do
        alias :original_new :new

        def self.inherited(subsubclass)
          subsubclass.extend(Servizio::Service::MethodDecorators)
        end

        def self.new(*args, &block)
          (obj = original_new(*args, &block)).singleton_class.send(:prepend, Servizio::Service::MethodDecorators::Call)
          return obj
        end
      end
    end
  end

  extend MethodDecorators
end
