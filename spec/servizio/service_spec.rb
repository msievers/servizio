describe Servizio::Service do
  context "when instantiated" do
    let(:service) { described_class.new }
    let(:states)  { described_class.class_variable_get(:@@states) }

    it "has on_[state] registration function for each state" do
      states.each do |state|
        expect(service).to respond_to("on_#{state}")
      end
    end
  end

  context "when derived" do
    let(:service) do
      Class.new(described_class) do
        def call
          1 + 1
        end
      end.new
    end

    describe ".call" do
      it "triggers activemodel callbacks" do
        global_state = false
        service.on_success -> (operation) { global_state = true }
        service.call
        expect(global_state).to be(true)
      end

      context "failed" do
        let(:service) do
          Class.new(described_class) do
            def call
              errors.add(:call, "failed")
            end
          end.new
        end

        it "triggers on_error service callbacks" do
          global_state = nil
          service.on_error -> (operation) { global_state = "error" }
          service.on_success -> (operation) { global_state = "success" }
          service.call
          expect(global_state).to eq("error")
        end
      end
      
      context "was successfull" do
        it "triggers on_success service callbacks" do
          global_state = false
          service.on_success -> (operation) { global_state = true }
          service.call
          expect(global_state).to be(true)
        end
      end
    end
  end
end
