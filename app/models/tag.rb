# == Schema Information
#
# Table name: tags
#
#  id                                          :integer          not null, primary key
#  tenant_id                                   :integer
#  name                                        :string
#  visible                                     :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Tag < ApplicationRecord
  belongs_to :tenant
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :message_threads
  has_many :tag_users, dependent: :destroy
  has_many :users, through: :tag_users
  has_many :tag_groups, dependent: :destroy
  has_many :groups, through: :tag_groups
  belongs_to :owner, class_name: 'User', optional: true
  has_many :message_threads_tags

  accepts_nested_attributes_for :message_threads_tags

  validates :name, presence: true
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: false }

  after_create_commit ->(tag) { tag.mark_readable_by_groups(tag.tenant.admin_groups) }
  after_update_commit ->(tag) { EventBus.publish(:tag_renamed, tag) if previous_changes.key?("name") }
  after_destroy ->(tag) { EventBus.publish(:tag_removed, tag) }

  def mark_readable_by_groups(groups)
    self.groups += groups
  end
end
