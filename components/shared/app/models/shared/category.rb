module Shared
class Category < ActiveRecord::Base
  acts_as_nested_set

  include Shared::Watchable

  include Shared::Categories::Searchable

  has_many :questions, dependent: :restrict_with_exception
  has_many :answers, through: :questions

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :roles, through: :assignments
  has_many :category_questions, dependent: :destroy if Shared::CategoryQuestion.table_exists?
  has_many :related_questions, -> { distinct }, through: :category_questions, source: :question
  has_many :related_answers, -> { distinct }, through: :related_questions, source: :answers

  has_many :category_questions_shared_through_me, foreign_key: 'shared_through_category_id', class: Shared::CategoryQuestion

  has_many :teacher_assistant_assignments, -> { where(role_id: Shared::Role::teacher_assistant.id) }, class_name: "Shared::Assignment"
  has_many :teacher_assistants, through: :teacher_assistant_assignments, class_name: 'Shared::User', source: :user

  validates :name, presence: true

  before_save  :update_changed
  before_save  :update_uuid
  after_create :save_parent_tags
  after_save   :update_public_tags
  after_save   :refresh_names
  after_save   :update_categories_questions

  scope :with_slido, -> { where.not(slido_username: nil) }
  scope :with_questions, lambda { joins(:related_questions).uniq }
  scope :askable, -> { where(askable: true) }
  scope :shared, -> { where(shared: true) }
  scope :in_contexts, lambda { |contexts| Category.all_in_contexts(contexts, self) }

  attr_reader :what_changed

  self.table_name = 'categories'

  def update_changed
    @what_changed = changed || []
  end

  def update_uuid
    return true unless self.uuid.blank?

    random_token = rand(36**5).to_s(36)
    self.uuid    = "#{self.name.to_s.parameterize}-#{random_token}"

    true
  end

  def refresh_names
    return true unless Shared::Category.column_names.include? 'full_public_name'

    refresh_descs            = false
    name_changed             = @what_changed.include? 'name'
    parent_id_changed        = @what_changed.include? 'parent_id'
    full_tree_name_changed   = @what_changed.include? 'full_tree_name'
    full_public_name_changed = @what_changed.include? 'full_public_name'

    if !full_tree_name_changed && (name_changed || parent_id_changed)
      self.refresh_full_tree_name
      refresh_descs = true
    end

    if !full_public_name_changed && (name_changed || parent_id_changed)
      self.refresh_full_public_name
      refresh_descs = true
    end

    if refresh_descs
      self.save validate: false

      self.descendants.each do |category|
        category.refresh_full_tree_name
        category.refresh_full_public_name
        category.save validate: false
      end
    end

    true
  end

  def refresh_full_tree_name
    # TODO (ladislav.gallay) Remove the filtering of 'root' node
    self.full_tree_name = self.self_and_ancestors.select { |item| item.name != 'root' }.map { |item| item.name }.join(' - ')
  end

  def refresh_full_public_name
    depths = CategoryDepth.public_depths
    names  = self.ancestors.select { |item| depths.include? item.depth }.map { |item| item.name }
    names << self.name

    self.full_public_name = names.join(' - ')
  end

  def count
    questions.reload.size
  end

  def effective_tags
    public_tags
  end

  def tags=(values)
    tags_array = Shared::Tags::Extractor.extract(values)
    self.public_tags = (self.public_tags + tags_array).uniq if Shared::Category.column_names.include? 'public_tags'
    new_tags = tags_array - tags
    deleted_tags = tags - tags_array

    add_tags_to_descendants new_tags if new_tags.size > 0
    delete_tags_from_descendants deleted_tags if deleted_tags.size > 0
    write_attribute(:tags, tags_array)
  end

  def public_tags=(values)
    write_attribute(:public_tags, Shared::Tags::Extractor.extract(values))
  end

  def add_tags_to_descendants tags
    self_and_descendants.each do |category|
      category.public_tags = (category.public_tags + tags).uniq

      category.save
    end
  end

  def delete_tags_from_descendants tags
    self_and_descendants.each do |category|
      category.public_tags -= tags

      category.save
    end
  end

  def teachers
    roles = Shared::Role::teacher_roles.map(&:id)
    list  = association(:assignments).loaded? ? assignments.select { |item| roles.include? item.role_id } : assignments.where({ role_id: roles })

    list.map { |t| t.user }
  end

  def has_teachers?
    teachers.length > 0
  end

  def name_with_teacher_supported
    return "#{full_public_name}#{I18n.t('category.teacher_supported')}" if has_teachers?
    full_public_name
  end

  def self.all_in_contexts(contexts, relation = nil)
    relation   ||= Category::all
    conditions = []

    Category::where(id: contexts).each do |category|
      conditions.append "(lft >= #{category.lft} AND rgt <= #{category.rgt})"
    end

    conditions.empty? ? relation.where('1 = 2') : relation.where(conditions.join(' OR '))
  end

  def all_versions
    Shared::Category.where(uuid: self.uuid).where.not(id: self.id)
  end

  def save_parent_tags
    return true unless Shared::Category.column_names.include? 'public_tags'

    self.public_tags += ancestors.map { |ancestor| ancestor.tags }.flatten

    self.save!
  end

  def update_public_tags
    return true unless Shared::Category.column_names.include? 'public_tags'

    if @what_changed.include? 'parent_id'
      self_and_descendants.each do |category|
        category.public_tags = category.self_and_ancestors.map { |ancestor| ancestor.tags }.flatten.uniq.sort

        category.save
      end
    end

    true
  end

  def update_categories_questions
    if @what_changed.include? 'parent_id'
      reload_categories_questions
    elsif @what_changed.include? 'shared'
      if self.shared
        self.all_versions.each do |shared_category|
          shared_category.questions.each do |question|
            self.self_and_ancestors.each do |ancestor|
              CategoryQuestion.create question_id: question.id, category_id: ancestor.id, shared: true, shared_through_category: self
            end
          end
        end
      else
        self.category_questions_shared_through_me.destroy_all
      end
    end

    true
  end

  def reload_categories_questions
    self_and_descendants.each do |category|
      category.questions.each do |question|
        question.register_question
      end
    end
  end

  def self.rebuild!
    super
    self.update_all("#{depth_column_name} = ((select count(*) from #{self.quoted_table_name} t where t.lft <= #{self.quoted_table_name}.lft and t.rgt >= #{self.quoted_table_name}.rgt) - 1)")
  end

  def related_contexts
    self_and_ancestors.where(depth: 1)
  end

  def can_have_subcategories?
     self.questions_count == 0
  end

  def custom?
    self.lti_id.blank?
  end

  def available_in_current_context?
    self.related_contexts.where(id: Shared::Context::Manager.current_context).count > 0
  end
end
end
