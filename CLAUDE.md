# lex-learning-rate

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-learning-rate`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::LearningRate`

## Purpose

Adaptive learning rate management for LegionIO agents. Maintains per-domain learning rates that adjust dynamically: wrong predictions increase the rate (more learning needed), correct predictions decrease it (less adjustment needed), surprise or error events boost it temporarily. Rates mean-revert toward DEFAULT_RATE over time via decay. Tracks rolling prediction accuracy per domain.

## Gem Info

- **Require path**: `legion/extensions/learning_rate`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/learning_rate/
  version.rb
  helpers/
    constants.rb      # Rate bounds, adjustment deltas, labels
    rate_model.rb     # Per-domain rate tracking and adjustment
  runners/
    learning_rate.rb  # Runner module

spec/
  legion/extensions/learning_rate/
    helpers/
      constants_spec.rb
      rate_model_spec.rb
    runners/learning_rate_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
DEFAULT_RATE     = 0.15   # starting and mean-reversion target
MIN_RATE         = 0.01   # floor on learning rate
MAX_RATE         = 0.5    # ceiling on learning rate
RATE_INCREASE    = 0.03   # delta on wrong prediction
RATE_DECREASE    = 0.02   # delta on correct prediction
SURPRISE_BOOST   = 0.05   # delta on surprise event
ERROR_BOOST      = 0.04   # delta on error event
ACCURACY_WINDOW  = 20     # rolling window for accuracy buffer per domain
MAX_DOMAINS      = 50     # domain cap

RATE_LABELS = {
  (0.4..)     => :very_fast,
  (0.25...0.4) => :fast,
  (0.1...0.25) => :moderate,
  (0.05...0.1) => :slow,
  (..0.05)    => :very_slow
}
```

## Helpers

### `Helpers::RateModel` (class)

Per-domain learning rate store with accuracy tracking.

| Attribute | Description |
|---|---|
| `@rates` | Hash of domain -> current rate Float |
| `@accuracy_buffers` | Hash of domain -> Array of boolean accuracy results (rolling window) |

| Method | Description |
|---|---|
| `record_prediction(domain:, correct:)` | appends to accuracy buffer; increases rate if wrong, decreases if correct; clamps to MIN_RATE..MAX_RATE |
| `record_surprise(domain:)` | boosts rate by SURPRISE_BOOST |
| `record_error(domain:)` | boosts rate by ERROR_BOOST |
| `decay(domain:)` | mean-reverts rate toward DEFAULT_RATE by a small step |
| `fastest_domains(limit:)` | top N domains by current rate |
| `slowest_domains(limit:)` | bottom N domains by current rate |
| `accuracy_for(domain:)` | ratio of correct predictions in rolling window |
| `rate_label(domain:)` | :very_fast / :fast / :moderate / :slow / :very_slow |

## Runners

Module: `Legion::Extensions::LearningRate::Runners::LearningRate`

Private state: `@model` (memoized `RateModel` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `record_prediction` | `domain:, correct:` | Record a prediction outcome and adjust rate |
| `record_surprise` | `domain:` | Apply surprise boost to rate |
| `record_error` | `domain:` | Apply error boost to rate |
| `current_rate` | `domain:` | Return current rate and label for a domain |
| `fastest_domains` | `limit: 5` | Top N domains by learning rate |
| `slowest_domains` | `limit: 5` | Bottom N domains by learning rate |
| `update_learning_rate` | `tick_results: {}` | Extract prediction outcomes from tick_results and record |
| `learning_rate_stats` | (none) | Domain count, avg rate, fastest, slowest, overall accuracy |

`update_learning_rate` extracts from tick_results:
- `tick_results[:prediction_engine][:domain_accuracies]` — per-domain correct/wrong signals
- `tick_results[:prediction_engine][:surprises]` — domains with surprise events
- `tick_results[:memory_consolidation][:errors]` — domains with consolidation errors

## Integration Points

- **lex-prediction**: prediction accuracy per domain is the primary input to learning rate adjustment; `update_learning_rate` reads `prediction_engine` tick output.
- **lex-memory**: high learning rate for a domain should increase `reinforce` strength when storing new traces in that domain (caller responsibility to read rate and apply).
- **lex-curiosity**: domains with high learning rate are more productive for curiosity-driven exploration — more can be learned per interaction.
- **lex-metacognition**: `LearningRate` is listed under `:cognition` capability category.

## Development Notes

- Per-domain rates are initialized to DEFAULT_RATE on first access via `@rates.fetch(domain) { DEFAULT_RATE }`.
- Accuracy buffer is a fixed-size rolling array. When it reaches ACCURACY_WINDOW entries, oldest entries are dropped on the left (shift). Accuracy is computed as sum/count.
- `decay` moves rate toward DEFAULT_RATE by a fixed step of 0.005 per call (half of RATE_DECREASE). Callers must call `update_learning_rate` each tick for continuous mean reversion.
- MAX_DOMAINS is enforced by pruning the domain with the lowest absolute deviation from DEFAULT_RATE when the cap is reached.
- Rate adjustments compound: a domain with persistent wrong predictions can reach MAX_RATE quickly (≈12 consecutive wrong predictions from DEFAULT_RATE).
- No dedicated actor; `update_learning_rate` is driven by the tick cycle.
