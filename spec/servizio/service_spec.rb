describe Servizio::Service do
  let(:operation) do
    Class.new(described_class) do
      def call
        1 + 1
      end
    end.new
  end

  context "when instantiated" do
    let(:states)  { described_class.class_variable_get(:@@states) }

    it "has on_[state] registration function for each state" do
      states.each do |state|
        expect(operation).to respond_to("on_#{state}")
      end
    end

    it "has once_on_[state] registration function for each state" do
      states.each do |state|
        expect(operation).to respond_to("once_on_#{state}")
      end
    end

    describe "on_[state]" do
      it "is run everytime the operation is called" do
        global_state = 0
        operation.on_success -> (operation) { global_state += 1 }
        2.times { operation.call }
        expect(global_state).to eq(2)
      end
    end

    describe "once_on_[state]" do
      it "is only run once" do
        global_state = 0
        operation.once_on_success -> (operation) { global_state += 1 }
        2.times { operation.call }
        expect(global_state).to eq(1)
      end
    end
  end

  context "when derived" do
    describe ".call" do
      it "triggers activemodel callbacks" do
        global_state = false
        operation.on_success -> (operation) { global_state = true }
        operation.call
        expect(global_state).to be(true)
      end

      context "failed" do
        let(:operation) do
          Class.new(described_class) do
            def call
              errors.add(:call, "failed")
            end
          end.new
        end

        it "triggers on_error service callbacks" do
          global_state = nil
          operation.on_error -> (operation) { global_state = "error" }
          operation.on_success -> (operation) { global_state = "success" }
          operation.call
          expect(global_state).to eq("error")
        end
      end
      
      context "was successfull" do
        it "triggers on_success service callbacks" do
          global_state = false
          operation.on_success -> (operation) { global_state = true }
          operation.call
          expect(global_state).to be(true)
        end
      end
    end
  end
end
