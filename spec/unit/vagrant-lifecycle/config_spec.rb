require "spec_helper"

describe VagrantPlugins::Lifecycle::Config do
  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#events" do
    it "defaults to empty hash" do
      subject.finalize!
      expect(subject.events).to eq(Hash.new)
    end
  end

  describe "#default_event" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.default_event).to be(nil)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: File.expand_path("..", __FILE__),
        ))

      subject.default_event = nil
      subject.events = {}
    end

    let(:result) do
      subject.finalize!
      subject.validate(machine)
    end

    let(:errors) { result["Lifecycle"] }

    context "when multiple events are configured with correct default_event" do
      before {
        subject.default_event = :deploy
        subject.events = {
            :configure => lambda {|x, y| x},
            :deploy => lambda {|x, y| x},
            :setup => lambda {|x, y| x}
        }
      }

      it "returns success" do
        subject.finalize!
        expect(errors).to be_empty
      end
    end

    context "when events is not a hash" do
      before {
        subject.events = "dummy"
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("events configuration is expected to be a hash!")
      end
    end

    context "when an event has non-lambda configuration" do
      before {
        subject.events = {
            :deploy => "dummy"
        }
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("deploy event configuration is expected to be lambda!")
      end
    end

    context "when an event has lambda configuration with 1 parameter" do
      before {
        subject.events = {
            :deploy => lambda {|x| x}
        }
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("deploy event configuration is expected to be lambda with 2 arguments!")
      end
    end

    context "when the default_event is defined but not configured in events" do
      before { subject.default_event = :deploy }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("deploy event configuration not found!")
      end
    end
  end
end
