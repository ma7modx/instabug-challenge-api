require 'elasticsearch/model'

class Bug < ActiveRecord::Base

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  PRIORITY_VALUES = %w(minor major critical)
  STATUS_VALUES = %w(new In-progress closed)

  has_one :state

  validates :application_token, presence: true
  validates :status, inclusion: { in: STATUS_VALUES }
  validates :priority, inclusion: { in: PRIORITY_VALUES }

  before_create :auto_assign_number
  after_create :update_bug_number_count
  after_rollback :rollback_bug_number_count

  def auto_assign_number
    self.number ||= Bug.next_bug_number(self.application_token)
  end

  # There're two cache stores for the case of rolling back
  def self.next_bug_number(application_token)
    number_cache_key = "bug_number:#{application_token}"
    # I should've fetch the record then increment it, this code may counter a problem in the else part
    if Rails.cache.exist?(number_cache_key, raw: true)
      Rails.cache.increment(number_cache_key)
    else
      last_bug = Bug.where("application_token = ?", application_token).last
      last_bug = last_bug ? last_bug.number : 0
      Rails.cache.write(number_cache_key,
                        last_bug + 1,
                        raw: true)
    end
    Rails.cache.read(number_cache_key, raw: true).to_i
  end

  # after_create
  def update_bug_number_count
    number_cache_key = "bug_number_count:#{self.application_token}"
    if Rails.cache.exist?(number_cache_key, raw: true)
      Rails.cache.increment(number_cache_key)
    else
      Rails.cache.write(number_cache_key,
                        Bug.where("application_token = ?", application_token).count,
                        raw: true)
    end
    @after_created = true
  end

  # decrement count if this record was created then it was rolled back
  def rollback_bug_number_count
    number_cache_key = "bug_number_count:#{self.application_token}"
    Rails.cache.decrement(number_cache_key) if @after_created
  end

  def self.get_bug_number_count(application_token)
    number_cache_key = "bug_number_count:#{application_token}"
    if Rails.cache.exist?(number_cache_key, raw: true)
      Rails.cache.read(number_cache_key, raw: true).to_i
    else
      Bug.where("application_token = ?", application_token).count
    end
  end

  # ElasticSearch settings
  settings index: {
    number_of_shards: 1,
    analysis: {
      analyzer: {
        my_ngram_analyzer: {
          tokenizer: "my_ngram_tokenizer"
        }
      },
      tokenizer: {
        my_ngram_tokenizer: {
          type: "nGram",
          min_gram: "1",
          max_gram: "50"
        }
      }
    }
  } do
    mapping do
      indexes :comment, type: 'string', index_analyzer: 'my_ngram_analyzer'
      indexes :status, analyzer: 'english'
      indexes :priority, analyzer: 'english'
      indexes :number
      indexes :application_token
    end
  end


  def self.search(q)
    search =  self.__elasticsearch__.search(
      query: {
        multi_match: {
        query: "#{q}", fields: ["comment", "status", "priority", "application_token", "number"] }
      }
    )
    search.records.to_a
  end
end
