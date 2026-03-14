# frozen_string_literal: true

module Legion
  module Extensions
    module LearningRate
      module Helpers
        class RateModel
          include Constants

          attr_reader :rates, :accuracy_buffers, :rate_history

          def initialize
            @rates            = {}
            @accuracy_buffers = {}
            @rate_history     = []
          end

          def rate_for(domain)
            @rates.fetch(domain, DEFAULT_RATE)
          end

          def record_prediction(domain:, correct:)
            ensure_domain(domain)
            @accuracy_buffers[domain] << (correct ? 1.0 : 0.0)
            @accuracy_buffers[domain].shift while @accuracy_buffers[domain].size > ACCURACY_WINDOW
            adjust_rate(domain, correct: correct)
          end

          def record_surprise(domain:, magnitude:)
            ensure_domain(domain)
            boost = magnitude * SURPRISE_BOOST
            @rates[domain] = (@rates[domain] + boost).clamp(MIN_RATE, MAX_RATE)
            record_event(domain, :surprise, @rates[domain])
          end

          def record_error(domain:, magnitude:)
            ensure_domain(domain)
            boost = magnitude * ERROR_BOOST
            @rates[domain] = (@rates[domain] + boost).clamp(MIN_RATE, MAX_RATE)
            record_event(domain, :error, @rates[domain])
          end

          def accuracy_for(domain)
            buffer = @accuracy_buffers.fetch(domain, [])
            return 0.0 if buffer.empty?

            buffer.sum / buffer.size
          end

          def decay
            @rates.each_key do |domain|
              current = @rates[domain]
              delta = (current - DEFAULT_RATE) * RATE_DECAY
              @rates[domain] = (current - delta).clamp(MIN_RATE, MAX_RATE)
            end
          end

          def label_for(domain)
            rate = rate_for(domain)
            RATE_LABELS.each do |range, lbl|
              return lbl if range.cover?(rate)
            end
            :consolidated
          end

          def fastest_domains(count = 5)
            @rates.sort_by { |_, r| -r }.first(count).to_h
          end

          def slowest_domains(count = 5)
            @rates.sort_by { |_, r| r }.first(count).to_h
          end

          def overall_rate
            return DEFAULT_RATE if @rates.empty?

            @rates.values.sum / @rates.size
          end

          def domain_count
            @rates.size
          end

          def to_h
            {
              domain_count: @rates.size,
              overall_rate: overall_rate.round(4),
              rates:        @rates.dup,
              history_size: @rate_history.size
            }
          end

          private

          def ensure_domain(domain)
            @rates[domain] ||= DEFAULT_RATE
            @accuracy_buffers[domain] ||= []
            trim_domains(protect: domain) if @rates.size > MAX_DOMAINS
          end

          def adjust_rate(domain, correct:)
            @rates[domain] = if correct
                               (@rates[domain] - RATE_DECREASE).clamp(MIN_RATE, MAX_RATE)
                             else
                               (@rates[domain] + RATE_INCREASE).clamp(MIN_RATE, MAX_RATE)
                             end
            record_event(domain, correct ? :correct : :incorrect, @rates[domain])
          end

          def record_event(domain, event_type, rate)
            @rate_history << { domain: domain, event: event_type, rate: rate, at: Time.now.utc }
            @rate_history.shift while @rate_history.size > MAX_RATE_HISTORY
          end

          def trim_domains(protect: nil)
            candidates = @rates.reject { |k, _| k == protect }
            sorted = candidates.sort_by { |_, r| (r - DEFAULT_RATE).abs }
            excess = @rates.size - MAX_DOMAINS
            remove_keys = sorted.first(excess).map(&:first)
            remove_keys.each do |key|
              @rates.delete(key)
              @accuracy_buffers.delete(key)
            end
          end
        end
      end
    end
  end
end
