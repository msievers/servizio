module Servizio::Rails::ControllerAdditions
  def call_operation(operation, options = {})
    # default to authorize every operation call unless given
    options[:authorize] = true if options[:authorize].nil?

    # use cancan(can) like ability if given or present
    if options[:authorize]
      operation.ability = options[:ability] || (respond_to?(:current_ability) ? current_ability : nil)
    end

    # register a one-time event state handler for every operation state,
    # executing either options[:on_...] or self.handle_operation_...
    operation.states.each do |state|
      operation.method("once_on_#{state}").call -> (op) do
        (options[:"on_#{state}"] || self.method("on_#{state}")).call(op)
      end
    end

    operation.call
  end
end
