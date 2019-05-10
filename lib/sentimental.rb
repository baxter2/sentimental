require_relative 'file_reader'

class Sentimental
  include FileReader

  attr_accessor :threshold, :word_scores, :neutral_regexps, :ngrams, :influencers, :exclude

  def initialize(threshold: 0, word_scores: nil, neutral_regexps: [], ngrams: 1, influencers: nil, exclude: nil)
    @ngrams = ngrams.to_i.abs if ngrams.to_i >= 1
    @word_scores = word_scores || {}
    @influencers = influencers || {}
    @word_scores.default = 0.0
    @influencers.default = 0.0
    @threshold = threshold
    @neutral_regexps = neutral_regexps
    @exclude = filter_proc(exclude)
  end

  def score(string)
    return 0 if neutral_regexps.any? { |regexp| string =~ regexp }

    initial_scoring = {score: 0, current_influencer: 1.0}

    words_excluded = extract_words_with_n_grams(string).reject { |word| exclude.call(word) }
    words_excluded.inject(initial_scoring) do |current_scoring, word|
      process_word(current_scoring, word)
    end[:score]
  end

  def sentiment(string)
    score = score(string)

    if score < (-1 * threshold)
      :negative
    elsif score > threshold
      :positive
    else
      :neutral
    end
  end

  def classify(string)
    sentiment(string) == :positive
  end

  def load_defaults
    %w(slang en_words).each do |filename|
      load_from_json(File.dirname(__FILE__) + "/../data/#{filename}.json")
    end
    load_influencers_from_json(File.dirname(__FILE__) + '/../data/influencers.json')
  end

  def load_from(filename)
    load_to(filename, word_scores)
  end

  def load_influencers(filename)
    load_to(filename, influencers)
  end

  def load_to(filename, hash)
    hash.merge!(hash_from_txt(filename))
  end

  def load_from_json(filename)
    word_scores.merge!(hash_from_json(filename))
  end

  def load_influencers_from_json(filename)
    influencers.merge!(hash_from_json(filename))
  end

  alias load_senti_file load_from
  alias load_senti_json load_from_json

  alias_method :load_senti_file, :load_from

  private

  def process_word(scoring, word)
    if influencers[word] > 0
      scoring[:current_influencer] *= influencers[word]
    else
      scoring[:score] += word_scores[word] * scoring[:current_influencer]
      scoring[:current_influencer] = 1.0
    end
    scoring
  end

  def extract_words(string)
    string.to_s.downcase.scan(/([\w']+|\S{2,})/).flatten
  end

  def extract_words_with_n_grams(string)
    words = extract_words(string)
    1.upto(ngrams).map do |number|
      words.each_cons(number).to_a
    end.flatten(1).map { |word| word.join(" ") }
  end

  def influence_score
    @total_score < 0.0 ? -@influence : +@influence
  end

  def filter_proc(filter)
    if filter.respond_to?(:to_a)
      filter_procs = Array(filter).map(&method(:filter_proc))
      ->(word) {
        filter_procs.any? { |p| p.call(word) }
      }
    elsif filter.respond_to?(:to_str)
      exclusion_list = filter.split.collect(&:downcase)
      ->(word) {
        exclusion_list.include?(word)
      }
    elsif regexp_filter = Regexp.try_convert(filter)
      Proc.new { |word| word =~ regexp_filter }
    elsif filter.respond_to?(:to_proc)
      filter.to_proc
    else
      raise ArgumentError, "Filter must String, Array, Lambda, or a Regexp"
    end
  end
end
