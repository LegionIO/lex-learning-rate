# frozen_string_literal: true

RSpec.describe Legion::Extensions::LearningRate::Runners::LearningRate do
  let(:client) { Legion::Extensions::LearningRate::Client.new }

  describe '#record_prediction' do
    it 'returns success with rate data' do
      result = client.record_prediction(domain: :math, correct: true)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:math)
      expect(result[:rate]).to be_a(Float)
      expect(result[:accuracy]).to be_a(Float)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'increases rate on incorrect predictions' do
      client.record_prediction(domain: :math, correct: true)
      slow_rate = client.current_rate(domain: :math)[:rate]
      client.record_prediction(domain: :math, correct: false)
      fast_rate = client.current_rate(domain: :math)[:rate]
      expect(fast_rate).to be > slow_rate
    end
  end

  describe '#record_surprise' do
    it 'returns success with updated rate' do
      result = client.record_surprise(domain: :physics, magnitude: 0.7)
      expect(result[:success]).to be true
      expect(result[:rate]).to be > Legion::Extensions::LearningRate::Helpers::Constants::DEFAULT_RATE
    end
  end

  describe '#record_error' do
    it 'returns success with updated rate' do
      result = client.record_error(domain: :coding, magnitude: 0.5)
      expect(result[:success]).to be true
      expect(result[:rate]).to be > Legion::Extensions::LearningRate::Helpers::Constants::DEFAULT_RATE
    end
  end

  describe '#current_rate' do
    it 'returns current rate for a domain' do
      result = client.current_rate(domain: :general)
      expect(result[:success]).to be true
      expect(result[:rate]).to eq(Legion::Extensions::LearningRate::Helpers::Constants::DEFAULT_RATE)
    end
  end

  describe '#fastest_domains' do
    before do
      3.times { client.record_prediction(domain: :fast, correct: false) }
      client.record_prediction(domain: :slow, correct: true)
    end

    it 'returns domains sorted by rate' do
      result = client.fastest_domains(count: 2)
      expect(result[:success]).to be true
      expect(result[:domains].keys.first).to eq(:fast)
    end
  end

  describe '#slowest_domains' do
    before do
      3.times { client.record_prediction(domain: :fast, correct: false) }
      client.record_prediction(domain: :slow, correct: true)
    end

    it 'returns domains sorted by rate ascending' do
      result = client.slowest_domains(count: 2)
      expect(result[:domains].keys.first).to eq(:slow)
    end
  end

  describe '#update_learning_rate' do
    it 'decays and returns overall rate' do
      client.record_prediction(domain: :math, correct: false)
      result = client.update_learning_rate
      expect(result[:success]).to be true
      expect(result[:domain_count]).to eq(1)
      expect(result[:overall_rate]).to be_a(Float)
    end
  end

  describe '#learning_rate_stats' do
    it 'returns stats' do
      result = client.learning_rate_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to have_key(:domain_count)
      expect(result[:stats]).to have_key(:overall_rate)
    end
  end
end
