module Shared
  class CategoryQuestion < ActiveRecord::Base
    include Shared::Deletable

    belongs_to :category
    belongs_to :question

    belongs_to :shared_through_category, foreign_key: 'shared_through_category_id', class: Shared::Category

    validates_uniqueness_of :question_id, scope: [:category_id]

    scope :shared, -> { where('shared') }

    self.table_name = 'categories_questions'
  end
end