# sentimental

Simple sentiment analysis with Ruby

## How it works

Sentences are tokenized and tokens are assigned a numerical score
for their average sentiment.  The total score is then used to
determine the overall sentiment in relation to the threshold.

For example, the default threshold is 0.0.  If a sentence has
a score of 0, it is deemed "neutral".  Higher than the thresold
is "positive", lower is "negative".

If you set the threshold to a non-zero amount, e.g. 0.25:

- Positive scores are > 0.25
- Neutral scores are -0.25 - 0.25
- Negative scores are < -0.25


## Usage

```ruby

# Create an instance for usage
analyzer = Sentimental.new

# Load the default sentiment dictionaries
analyzer.load_defaults

# And/or load your own dictionaries
analyzer.load_senti_file('path/to/your/file.txt')

# Set a global threshold
analyzer.threshold = 0.1

# Use your analyzer
analyzer.sentiment 'I love ruby'
#=> :positive

analyzer.sentiment 'I like ruby'
#=> :neutral

analyzer.sentiment 'I really like ruby'
#=> :positive

# You can make new analyzers with individual thresholds:
analyzer = Sentimental.new(threshold: 0.9)
analyzer.sentiment 'I love ruby'
#=> :positive

analyzer.sentiment 'I like ruby'
#=> :neutral

analyzer.sentiment 'I really like ruby'
#=> :neutral

# Get the numerical score of a string:
analyzer.score 'I love ruby'
#=> 0.925

```

## Sentiment dictionaries

These are currently plain-text files containing whitespace-separated
scores and tokens, e.g.:

    1.0 Awesome
    0.0 Meh
    -1.0 Horrible

## N-grams

You can parse n-grams of words by specifying their max size in the initializer:
```
  Sentimental.new(ngrams: 4)
```

The dictionary must have this format:

    1.0 very happy
    -2.0 no
    0.0 meh

## Excluding words from the analysis

You can exclude anything you want from the string you want to analyse by passing in an `exclude` keyword. The `exclude` keyword accepts a variety of filters.

1. A string of space-delimited list of candidates. 
2. An array of string candidates. For example: `['do', 'love']`.
3. A regular expression.
4. A lambda.

#### Using a string
```ruby
Sentimental.new(
  word_scores: { 'love' => 0.925, 'do' => -0.375 },
  exclude: 'do'
).score('Do you love ruby?')
#=> 0.925

Sentimental.new(
  word_scores: { 'love' => 0.925, 'do' => -0.375 },
  exclude: 'do love'
).score('Do you love ruby?')
#=> 0.0
```

#### Using an array
```ruby
Sentimental.new(
  word_scores: { 'love' => 0.925, 'do' => -0.375 },
  exclude: ['do', 'love']
).score('Do you love ruby?')
#=> 0.0
```

#### Using a regular expression
```ruby
Sentimental.new(
  word_scores: { 'love' => 0.925, 'do' => -0.375 },
  exclude: /love/i 
).score('Do you love ruby?')
#=> -0.375 
```

#### Using a lambda
```ruby
Sentimental.new(
  word_scores: { 'love' => 0.925, 'do' => -0.375 },
  exclude: ->(w) { w == 'do' }
).score('Do you love ruby?')
#=> 0.925 
```

## Installation

    gem install sentimental

## License

MIT License

## Credits

Based largely on Christopher MacLellan's script:
https://github.com/cmaclell/Basic-Tweet-Sentiment-Analyzer

## Changes
- 2013-10-13 Adding :-) to slang


