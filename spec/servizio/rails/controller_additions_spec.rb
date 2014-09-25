describe Servizio::Rails::ControllerAdditions do
  let(:addition_service) do
    Class.new(Servizio::Service) do
      attr_accessor :operands
      def call
        operands.inject(0) { |sum, operand| sum += operand }
      end
    end
  end

  let(:operation) { addition_service.new(operands: [1,2,3]) }

  it "foo" do
    described_class.call_operation(operation)
  end
end
