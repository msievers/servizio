require "active_model"

class Servizio::Service
  require_relative "./service/call"
  require_relative "./service/inherited_handler"

  extend ActiveModel::Callbacks
  include ActiveModel::Model
  include ActiveModel::Validations
  extend Servizio::Service::InheritedHandler

  @@states = %i(denied error invalid success)

  define_model_callbacks :call
  
  # watch out for ActiveModel::Callbacks method names
  before_call :reset_callbacks
  after_call :execute_callbacks

  attr_accessor :ability # a cancan(can) ability
  attr_accessor :result

  # this is only to dry things up
  @@states.each do |state|
    class_eval <<-code
      def on_#{state}(callable)
        add_callback(:on_#{state}, callable)
      end

      def once_on_#{state}(callable)
        add_callback(:on_#{state}, callable, only_execute_once: true)
      end
    code
  end

  def authorized?; can?(:call, self);        end
  def denied?;     !authorized?;             end
  def called?;     @called == true;          end

  def error?
    called? && errors.present?
  end
  alias_method :failed?, :error?

  def i18n_scope
    model_name.i18n_key.to_s.gsub("/", ".")    
  end

  def success?
    called? && errors.blank?
  end
  alias_method :succeeded?, :success?

  #
  private
  #
  def add_callback(queue, callable, options = {})
    new_callback = { callable: callable, executed: false, queue: queue.to_sym }.merge!(options)
    callbacks.push(new_callback)
    execute_callback(new_callback) if called? # execute it immediately, if operation was called previously
  end

  def callbacks
    @callbacks ||= []
  end

  def can?(*args)
    @ability.respond_to?(:can?) ? @ability.can?(*args) : true # default to true
  end

  def execute_callback(callback)
    if
      denied?  &&             callback[:queue] == :on_denied ||
      error?   &&             callback[:queue] == :on_error ||
      !called? && invalid? && callback[:queue] == :on_invalid || # don't call invalid? here, it might erase the errors object
      success? &&             callback[:queue] == :on_success
    then
      unless callback[:executed]
        callback[:callable].call(self)
        callback[:executed] = true
      end

      callbacks.delete(callback) if callback[:only_execute_once]
    end
  end

  def execute_callbacks
    callbacks.each { |callback| execute_callback(callback) }
  end

  def reset_callbacks
    callbacks.each { |callback| callback[:executed] = false }
  end
end
