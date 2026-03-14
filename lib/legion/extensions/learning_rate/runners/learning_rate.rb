# frozen_string_literal: true

module Legion
  module Extensions
    module LearningRate
      module Runners
        module LearningRate
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def record_prediction(correct:, domain: :general, **)
            rate_model.record_prediction(domain: domain, correct: correct)
            rate = rate_model.rate_for(domain)
            accuracy = rate_model.accuracy_for(domain)
            Legion::Logging.debug "[learning_rate] prediction: domain=#{domain} correct=#{correct} rate=#{rate.round(3)} accuracy=#{accuracy.round(3)}"
            {
              success:  true,
              domain:   domain,
              rate:     rate,
              accuracy: accuracy,
              label:    rate_model.label_for(domain)
            }
          end

          def record_surprise(magnitude:, domain: :general, **)
            rate_model.record_surprise(domain: domain, magnitude: magnitude)
            rate = rate_model.rate_for(domain)
            Legion::Logging.debug "[learning_rate] surprise: domain=#{domain} magnitude=#{magnitude.round(3)} rate=#{rate.round(3)}"
            { success: true, domain: domain, rate: rate, label: rate_model.label_for(domain) }
          end

          def record_error(magnitude:, domain: :general, **)
            rate_model.record_error(domain: domain, magnitude: magnitude)
            rate = rate_model.rate_for(domain)
            Legion::Logging.debug "[learning_rate] error: domain=#{domain} magnitude=#{magnitude.round(3)} rate=#{rate.round(3)}"
            { success: true, domain: domain, rate: rate, label: rate_model.label_for(domain) }
          end

          def current_rate(domain: :general, **)
            rate = rate_model.rate_for(domain)
            accuracy = rate_model.accuracy_for(domain)
            {
              success:  true,
              domain:   domain,
              rate:     rate,
              accuracy: accuracy,
              label:    rate_model.label_for(domain)
            }
          end

          def fastest_domains(count: 5, **)
            domains = rate_model.fastest_domains(count)
            { success: true, domains: domains, count: domains.size }
          end

          def slowest_domains(count: 5, **)
            domains = rate_model.slowest_domains(count)
            { success: true, domains: domains, count: domains.size }
          end

          def update_learning_rate(**)
            rate_model.decay
            overall = rate_model.overall_rate
            Legion::Logging.debug "[learning_rate] tick: domains=#{rate_model.domain_count} overall=#{overall.round(3)}"
            { success: true, domain_count: rate_model.domain_count, overall_rate: overall }
          end

          def learning_rate_stats(**)
            { success: true, stats: rate_model.to_h }
          end

          private

          def rate_model
            @rate_model ||= Helpers::RateModel.new
          end
        end
      end
    end
  end
end
