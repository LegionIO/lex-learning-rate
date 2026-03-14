# frozen_string_literal: true

require 'legion/extensions/learning_rate/helpers/constants'
require 'legion/extensions/learning_rate/helpers/rate_model'
require 'legion/extensions/learning_rate/runners/learning_rate'

module Legion
  module Extensions
    module LearningRate
      class Client
        include Runners::LearningRate

        attr_reader :rate_model

        def initialize(rate_model: nil, **)
          @rate_model = rate_model || Helpers::RateModel.new
        end
      end
    end
  end
end
