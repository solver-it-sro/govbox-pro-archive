# == Schema Information
#
# Table name: govbox_folders
#
#  id                                          :integer          not null, primary key
#  edesk_folder_id                             :integer          not null
#  parent_folder_id                            :integer
#  box_id                                      :integer          not null
#  name                                        :string           not null
#  system                                      :boolean          not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::Folder < ApplicationRecord
  belongs_to :parent_folder, class_name: 'Govbox::Folder', dependent: :destroy, optional: true
  has_many :messages, class_name: 'Govbox::Message', dependent: :destroy
  has_many :child_folders, class_name: 'Govbox::Folder', foreign_key: :parent_folder_id, dependent: :destroy

  def box
    Box.find(box_id)
  end

  def full_name
    parent_folder_id.present? ? "#{parent_folder.full_name}/#{name}" : name
  end

  def inbox?
    name == "Inbox"
  end

  def bin?
    name == 'Bin'
  end

  def drafts?
    name == 'Drafts'
  end
end
