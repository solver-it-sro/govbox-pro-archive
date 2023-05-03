# == Schema Information
#
# Table name: submissions_objects
#
#  id                                          :integer          not null, primary key
#  submission_id                               :string           not null
#  uuid                                        :string           not null
#  name                                        :string           not null
#  signed                                      :boolean
#  to_be_signed                                :boolean
#  form                                        :boolean
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Submissions::Object < ApplicationRecord
  belongs_to :submission, class_name: 'Submission'

  has_one_attached :content

  validates :name, :uuid, presence: true, on: :validate_data
  validates :uuid, format: { with: Utils::UUID_PATTERN }, on: :validate_data
  validate :content_attached?, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

  private

  def content_attached?
    content.attached?
  end

  def allowed_mime_type?
    Utils.detect_mime_type(self)
  rescue StandardError
    errors.add(:mime_type, "of #{name} object is disallowed", allowed_mime_types: Utils::EXTENSIONS_ALLOW_LIST.join(', '))
  end
end
