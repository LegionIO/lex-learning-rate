# frozen_string_literal: true

require 'legion/extensions/learning_rate/version'
require 'legion/extensions/learning_rate/helpers/constants'
require 'legion/extensions/learning_rate/helpers/rate_model'
require 'legion/extensions/learning_rate/runners/learning_rate'
require 'legion/extensions/learning_rate/client'

module Legion
  module Extensions
    module LearningRate
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
