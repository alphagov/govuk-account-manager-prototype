RSpec.describe Healthcheck do
  let(:subject) { Healthcheck.check }

  let(:active_record) { double(:active_record, connection: true) }

  let(:redis_info) { double(:redis_info) }
  let(:sidekiq) { double(:sidekiq, redis_info: redis_info) }

  before do
    stub_const("ActiveRecord::Base", active_record)
    stub_const("Sidekiq", sidekiq)
  end

  context "database connectivity" do
    context "the database is connected" do
      it "returns :ok" do
        expect(subject.dig(:checks, :database_connectivity, :status)).to be(:ok)
      end
    end

    context "the database is not connected" do
      before do
        allow(active_record).to receive(:connection) { raise }
      end

      it "returns :critical" do
        expect(subject.dig(:checks, :database_connectivity, :status)).to be(:critical)
      end

      it "sets the overall status to :critical" do
        expect(subject.dig(:status)).to be(:critical)
      end
    end
  end

  context "redis connectivity" do
    context "redis is connected" do
      it "returns :ok" do
        expect(subject.dig(:checks, :redis_connectivity, :status)).to be(:ok)
      end
    end

    context "redis is not connected" do
      let(:redis_info) { nil }

      it "returns :critical" do
        expect(subject.dig(:checks, :redis_connectivity, :status)).to be(:critical)
      end

      it "sets the overall status to :critical" do
        expect(subject.dig(:status)).to be(:critical)
      end
    end

    context "redis raises an error" do
      before do
        allow(sidekiq).to receive(:redis_info) { raise }
      end

      it "returns :critical" do
        expect(subject.dig(:checks, :redis_connectivity, :status)).to be(:critical)
      end

      it "sets the overall status to :critical" do
        expect(subject.dig(:status)).to be(:critical)
      end
    end
  end
end
