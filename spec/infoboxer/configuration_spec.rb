require 'spec_helper'

describe Infoboxer::Configuration do

  describe "#user_agent" do
    subject { described_class.new }

    it "defaults to MediaWiki::UA" do
      expect(subject.user_agent).to eq(Infoboxer::MediaWiki::UA)
    end
  end

  describe "#add_option" do
    let(:key) { :some_config_key }
    let(:value) { "some_config_value" }

    subject { described_class.new }

    before { subject.add_option(key, value) }

    it "creates an accessor for the option" do
      expect(subject).to respond_to(key)
    end

    it "sets the option's value" do
      expect(subject.send(key)).to eq(value)
    end
  end
end
