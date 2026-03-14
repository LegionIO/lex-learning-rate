# frozen_string_literal: true

RSpec.describe Legion::Extensions::LearningRate::Client do
  let(:client) { described_class.new }

  it 'can be instantiated' do
    expect(client).to be_a(described_class)
  end

  it 'includes all runner methods' do
    expect(client).to respond_to(:record_prediction)
    expect(client).to respond_to(:record_surprise)
    expect(client).to respond_to(:record_error)
    expect(client).to respond_to(:current_rate)
    expect(client).to respond_to(:fastest_domains)
    expect(client).to respond_to(:slowest_domains)
    expect(client).to respond_to(:update_learning_rate)
    expect(client).to respond_to(:learning_rate_stats)
  end

  it 'exposes the rate model' do
    expect(client.rate_model).to be_a(Legion::Extensions::LearningRate::Helpers::RateModel)
  end

  describe 'full lifecycle' do
    it 'adapts learning rate based on prediction outcomes' do
      # Initial state
      initial = client.current_rate(domain: :coding)[:rate]

      # Agent makes wrong predictions - rate increases
      5.times { client.record_prediction(domain: :coding, correct: false) }
      after_errors = client.current_rate(domain: :coding)[:rate]
      expect(after_errors).to be > initial

      # Something surprising happens - rate boosts further
      client.record_surprise(domain: :coding, magnitude: 0.8)
      after_surprise = client.current_rate(domain: :coding)[:rate]
      expect(after_surprise).to be > after_errors

      # Agent starts getting things right - rate decreases
      10.times { client.record_prediction(domain: :coding, correct: true) }
      after_learning = client.current_rate(domain: :coding)[:rate]
      expect(after_learning).to be < after_surprise

      # Tick decay
      client.update_learning_rate
      stats = client.learning_rate_stats[:stats]
      expect(stats[:domain_count]).to eq(1)
    end
  end
end
