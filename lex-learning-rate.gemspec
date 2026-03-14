# frozen_string_literal: true

require_relative 'lib/legion/extensions/learning_rate/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-learning-rate'
  spec.version       = Legion::Extensions::LearningRate::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@iverson.io']

  spec.summary       = 'Meta-learning rate adaptation for LegionIO'
  spec.description   = 'Adapts the agent learning speed per domain based on prediction accuracy, ' \
                       'surprise, and errors. Fast learning when predictions fail, slow consolidation ' \
                       'when accurate — the agent learns how fast to learn.'
  spec.homepage      = 'https://github.com/LegionIO/lex-learning-rate'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
