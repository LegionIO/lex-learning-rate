# lex-learning-rate

Adaptive learning rate management for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-learning-rate` maintains per-domain learning rates that adapt to the agent's prediction performance. Wrong predictions raise the rate (more learning needed), correct predictions lower it (stable enough), and surprise or error events provide temporary boosts. Rates mean-revert toward a default over time. Rolling accuracy windows give a per-domain reliability signal.

Key capabilities:

- **Per-domain rates**: independent learning rate per knowledge domain
- **Prediction-driven adjustment**: wrong prediction +0.03, correct prediction -0.02
- **Event boosts**: surprise +0.05, error +0.04
- **Mean reversion**: rates drift back toward 0.15 default via decay
- **Rate labels**: very_slow / slow / moderate / fast / very_fast per rate value

## Installation

Add to your Gemfile:

```ruby
gem 'lex-learning-rate'
```

Or install directly:

```
gem install lex-learning-rate
```

## Usage

```ruby
require 'legion/extensions/learning_rate'

client = Legion::Extensions::LearningRate::Client.new

# Record prediction outcomes
client.record_prediction(domain: :networking, correct: false)
client.record_prediction(domain: :networking, correct: false)

# Record surprise or error events
client.record_surprise(domain: :networking)

# Check current rate
result = client.current_rate(domain: :networking)
# => { domain: :networking, rate: 0.27, label: :fast, accuracy: 0.3 }

# Find domains with highest/lowest learning rates
client.fastest_domains(limit: 3)
client.slowest_domains(limit: 3)

# Feed tick results (auto-extracts prediction outcomes)
client.update_learning_rate(tick_results: tick_phase_results)

# Stats
client.learning_rate_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `record_prediction` | Record a prediction outcome and adjust the domain rate |
| `record_surprise` | Apply a surprise boost to a domain's rate |
| `record_error` | Apply an error boost to a domain's rate |
| `current_rate` | Current rate value and label for a domain |
| `fastest_domains` | Top N domains by current learning rate |
| `slowest_domains` | Bottom N domains by current learning rate |
| `update_learning_rate` | Extract prediction outcomes from tick results and record |
| `learning_rate_stats` | Domain count, avg rate, fastest/slowest, overall accuracy |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
