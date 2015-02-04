describe Servizio::Service do
  context "if derived" do
    let(:service) do
      Class.new(described_class) do
        attr_accessor :should_fail
        attr_accessor :summands

        validates_presence_of :summands

        def should_fail?
          @should_fail == true
        end

        def call
          if should_fail?
            errors.add(:call, "failed")
          else
            summands.reduce(:+)
          end
        end
      end
    end

    let(:summands)             { [1,2,3] }
    let(:succeeding_operation) { service.new summands: summands }
    let(:failing_operation)    { service.new summands: summands, should_fail: true }
    let(:invalid_operation)    { service.new }

    context "if derived as anonymous class" do
      # http://stackoverflow.com/questions/14431723/activemodelvalidations-on-anonymous-class
      it "sets the class name to something non-blank to allow validations" do
        expect(service.name).not_to be_blank
      end
    end

    context "if derived from a derived class" do
      let(:derived_service) { Class.new(service) }

      it "works as expected" do
        expect(derived_service.new(summands: summands).call.result).to eq(summands.reduce(:+))
      end
    end

    #
    # call
    #
    describe "#call" do
      context "if the operation is valid with respect to its validators" do
        it "makes #called? return true" do
          expect(succeeding_operation.call.called?).to eq(true)
        end
      end

      context "if the operation is not valid with respect to its validators" do
        it "makes #called? return false" do
          expect(invalid_operation.call.called?).to eq(false)
        end
      end
    end

    #
    # call!
    #
    describe "#call!" do
      it "is an alias for call" do
        expect(succeeding_operation.call.result).to eq(service.new(summands: summands).call!.result)
      end
    end

    #
    # called?
    #
    describe "#called?" do
      context "if the operation was called (whether there were failures or not)" do
        it "returns true" do
          expect(succeeding_operation.call.called?).to be(true)
          expect(failing_operation.call.called?).to be(true)
        end
      end
    end

    describe "#failed?" do
      context "if the operation was called without errors" do
        it "returns false" do
          expect(succeeding_operation.call.failed?).to be(false)
        end
      end

      context "if the operation added something to \"errors\"" do
        it "returns true" do
          expect(failing_operation.call.failed?).to be(true)
        end
      end

      context "if the operation was not called" do
        it "returns false" do
          expect(succeeding_operation.failed?).to be(false)
          expect(failing_operation.failed?).to be(false)
        end
      end
    end

    #
    # result
    #
    describe "result" do
      context "if the operation was called" do
        it "provides the return value of the call method" do
          expect(succeeding_operation.call.result).to eq(summands.reduce(:+))
        end
      end

      context "if the operation was not called" do
        it "raises an error" do
          expect { succeeding_operation.result}.to raise_error(described_class::OperationNotCalledError)
        end
      end
    end

    #
    # succeeded?
    #
    describe "#succeeded?" do
      context "if the operation was called without errors" do
        it "returns true" do
          expect(succeeding_operation.call.succeeded?).to be(true)
        end
      end

      context "if the operation added something to \"errors\"" do
        it "returns false" do
          expect(failing_operation.call.succeeded?).to be(false)
        end
      end

      context "if the operation was not called" do
        it "returns false" do
          expect(succeeding_operation.succeeded?).to be(false)
          expect(failing_operation.succeeded?).to be(false)
        end
      end
    end
  end
end
