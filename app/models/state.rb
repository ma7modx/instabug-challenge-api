class State < ActiveRecord::Base
  belongs_to :bug

  validates :memory, numericality: true, if: -> {self.memory.present?}
  validates :storage, numericality: true, if: -> {self.storage.present?}
end
