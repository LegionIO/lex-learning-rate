# frozen_string_literal: true

RSpec.describe Legion::Extensions::LearningRate::Helpers::RateModel do
  let(:model) { described_class.new }
  let(:constants) { Legion::Extensions::LearningRate::Helpers::Constants }

  describe '#rate_for' do
    it 'returns default rate for unknown domain' do
      expect(model.rate_for(:new_domain)).to eq(constants::DEFAULT_RATE)
    end

    it 'returns tracked rate for known domain' do
      model.record_prediction(domain: :math, correct: false)
      expect(model.rate_for(:math)).not_to eq(constants::DEFAULT_RATE)
    end
  end

  describe '#record_prediction' do
    it 'increases rate on incorrect prediction' do
      model.record_prediction(domain: :math, correct: false)
      expect(model.rate_for(:math)).to be > constants::DEFAULT_RATE
    end

    it 'decreases rate on correct prediction' do
      model.record_prediction(domain: :math, correct: true)
      expect(model.rate_for(:math)).to be < constants::DEFAULT_RATE
    end

    it 'records accuracy history' do
      model.record_prediction(domain: :math, correct: true)
      model.record_prediction(domain: :math, correct: false)
      expect(model.accuracy_for(:math)).to eq(0.5)
    end

    it 'caps accuracy buffer at ACCURACY_WINDOW' do
      (constants::ACCURACY_WINDOW + 5).times { model.record_prediction(domain: :math, correct: true) }
      buffer = model.accuracy_buffers[:math]
      expect(buffer.size).to eq(constants::ACCURACY_WINDOW)
    end
  end

  describe '#record_surprise' do
    it 'increases rate proportional to magnitude' do
      initial = constants::DEFAULT_RATE
      model.record_surprise(domain: :math, magnitude: 0.8)
      expect(model.rate_for(:math)).to be > initial
    end

    it 'records in history' do
      model.record_surprise(domain: :math, magnitude: 0.5)
      expect(model.rate_history.size).to eq(1)
      expect(model.rate_history.last[:event]).to eq(:surprise)
    end
  end

  describe '#record_error' do
    it 'increases rate proportional to magnitude' do
      initial = constants::DEFAULT_RATE
      model.record_error(domain: :math, magnitude: 0.7)
      expect(model.rate_for(:math)).to be > initial
    end
  end

  describe '#accuracy_for' do
    it 'returns 0.0 for unknown domain' do
      expect(model.accuracy_for(:unknown)).to eq(0.0)
    end

    it 'computes rolling accuracy' do
      3.times { model.record_prediction(domain: :test, correct: true) }
      model.record_prediction(domain: :test, correct: false)
      expect(model.accuracy_for(:test)).to eq(0.75)
    end
  end

  describe '#decay' do
    it 'moves rates toward default' do
      model.record_prediction(domain: :math, correct: false)
      raised = model.rate_for(:math)
      model.decay
      expect(model.rate_for(:math)).to be < raised
    end
  end

  describe '#label_for' do
    it 'returns a symbol' do
      expect(model.label_for(:math)).to be_a(Symbol)
    end

    it 'returns :moderate_learning for default rate' do
      expect(model.label_for(:unknown)).to eq(:moderate_learning)
    end
  end

  describe '#fastest_domains' do
    it 'returns domains sorted by rate descending' do
      model.record_prediction(domain: :fast, correct: false)
      model.record_prediction(domain: :fast, correct: false)
      model.record_prediction(domain: :slow, correct: true)
      fastest = model.fastest_domains(2)
      expect(fastest.keys.first).to eq(:fast)
    end
  end

  describe '#slowest_domains' do
    it 'returns domains sorted by rate ascending' do
      model.record_prediction(domain: :fast, correct: false)
      model.record_prediction(domain: :slow, correct: true)
      slowest = model.slowest_domains(2)
      expect(slowest.keys.first).to eq(:slow)
    end
  end

  describe '#overall_rate' do
    it 'returns default when no domains tracked' do
      expect(model.overall_rate).to eq(constants::DEFAULT_RATE)
    end

    it 'averages all domain rates' do
      model.record_prediction(domain: :a, correct: true)
      model.record_prediction(domain: :b, correct: false)
      overall = model.overall_rate
      expect(overall).to be_a(Float)
    end
  end

  describe '#domain_count' do
    it 'counts tracked domains' do
      model.record_prediction(domain: :a, correct: true)
      model.record_prediction(domain: :b, correct: true)
      expect(model.domain_count).to eq(2)
    end
  end

  describe 'domain trimming' do
    it 'caps at MAX_DOMAINS' do
      (constants::MAX_DOMAINS + 5).times { |i| model.record_prediction(domain: :"d_#{i}", correct: true) }
      expect(model.domain_count).to eq(constants::MAX_DOMAINS)
    end
  end

  describe '#to_h' do
    it 'contains expected keys' do
      h = model.to_h
      expect(h).to have_key(:domain_count)
      expect(h).to have_key(:overall_rate)
      expect(h).to have_key(:rates)
      expect(h).to have_key(:history_size)
    end
  end
end
