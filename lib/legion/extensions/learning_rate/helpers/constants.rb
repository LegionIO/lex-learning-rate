# frozen_string_literal: true

module Legion
  module Extensions
    module LearningRate
      module Helpers
        module Constants
          DEFAULT_RATE         = 0.15
          MIN_RATE             = 0.01
          MAX_RATE             = 0.5
          RATE_INCREASE        = 0.03
          RATE_DECREASE        = 0.02
          RATE_DECAY           = 0.005
          ACCURACY_WINDOW      = 20
          SURPRISE_BOOST       = 0.05
          ERROR_BOOST          = 0.04
          CONFIDENCE_DAMPENING = 0.03
          MAX_DOMAINS          = 50
          MAX_RATE_HISTORY     = 200

          RATE_LABELS = {
            (0.3..)       => :fast_learning,
            (0.15...0.3)  => :moderate_learning,
            (0.05...0.15) => :slow_learning,
            (..0.05)      => :consolidated
          }.freeze
        end
      end
    end
  end
end
