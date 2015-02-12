require "active_model"

def Servizio::Service(service_name, &block)
  service_class_name = service_name.split("::").last

  parent_const =
  service_name.split("::")[0..-2].inject(Object) do |constant, child_constant_name|
    constant.const_get(child_constant_name)
  end

  service_class = Class.new(Servizio::Service, &block)
  
  # remove previously defined const if present
  if parent_const.const_defined?(service_class_name)
    # it's wired ... If there is Bar and you ask Foo.const_defined(:Bar) it
    # says true, althouh there is no Foo::Bar, just Bar. So there is no 100%
    # correct way to check of there is Foo::Bar and so we have to rescue.
    begin
      parent_const.send(:remove_const, service_class_name)
    rescue
    end
  end

  parent_const.const_set(service_class_name, service_class)
  
  # Object.define_method does the same as "def some_method", but it's private
  parent_const.send(:define_method, service_class_name.to_sym) do |*args|
    if (operation = service_class.new(*args)).call!.succeeded?
      operation.result
    else
      raise Servizio::Service::OperationFailedError
    end
  end
end

class Servizio::Service
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :result

  OperationFailedError = Class.new(StandardError)
  OperationNotCalledError = Class.new(StandardError)

  # http://stackoverflow.com/questions/14431723/activemodelvalidations-on-anonymous-class
  def self.name
    super ? super : "__anonymous_servizio_service_class__"
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
