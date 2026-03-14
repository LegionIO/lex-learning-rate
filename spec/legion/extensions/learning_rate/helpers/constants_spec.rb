# frozen_string_literal: true

RSpec.describe Legion::Extensions::LearningRate::Helpers::Constants do
  it 'defines DEFAULT_RATE' do
    expect(described_class::DEFAULT_RATE).to eq(0.15)
  end

  it 'defines MIN_RATE and MAX_RATE' do
    expect(described_class::MIN_RATE).to eq(0.01)
    expect(described_class::MAX_RATE).to eq(0.5)
  end

  it 'defines ACCURACY_WINDOW' do
    expect(described_class::ACCURACY_WINDOW).to eq(20)
  end

  it 'defines RATE_LABELS covering 0.0..1.0' do
    labels = described_class::RATE_LABELS
    [0.01, 0.05, 0.1, 0.2, 0.35, 0.5].each do |val|
      matched = labels.any? { |range, _| range.cover?(val) }
      expect(matched).to be(true), "Expected #{val} to match a label range"
    end
  end

  it 'has all expected RATE_LABELS values' do
    values = described_class::RATE_LABELS.values
    expect(values).to contain_exactly(:fast_learning, :moderate_learning, :slow_learning, :consolidated)
  end
end
