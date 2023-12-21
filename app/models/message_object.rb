# == Schema Information
#
# Table name: message_objects
#
#  id           :bigint           not null, primary key
#  is_signed    :boolean
#  mimetype     :string
#  name         :string
#  object_type  :string           not null
#  to_be_signed :boolean          default(FALSE), not null
#  visualizable :boolean
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  message_id   :bigint           not null
#
class MessageObject < ApplicationRecord
  belongs_to :message, inverse_of: :objects
  has_one :message_object_datum, dependent: :destroy
  has_many :nested_message_objects, inverse_of: :message_object, dependent: :destroy
  has_many :message_objects_tags, dependent: :destroy
  has_many :tags, through: :message_objects_tags
  has_one :archived_object, dependent: :destroy

  scope :unsigned, -> { where(is_signed: false) }
  scope :to_be_signed, -> { where(to_be_signed: true) }
  scope :should_be_signed, -> { where(to_be_signed: true, is_signed: false) }

  validates :name, presence: true, on: :validate_data
  validate :allowed_mime_type?, on: :validate_data

  after_update ->(message_object) { EventBus.publish(:message_object_changed, message_object) }

  def self.create_message_objects(message, objects)
    objects.each do |raw_object|
      message_object_content = raw_object.read.force_encoding("UTF-8")

      message_object = MessageObject.create!(
        message: message,
        name: raw_object.original_filename,
        mimetype: Utils.file_mime_type_by_name(entry_name: raw_object.original_filename),
        is_signed: Utils.is_signed?(entry_name: raw_object.original_filename, content: message_object_content),
        object_type: "ATTACHMENT"
      )

      MessageObjectDatum.create!(
        message_object: message_object,
        blob: message_object_content
      )
    end
  end

  def mark_signed_by_user(user)
    # object, user_signed_tag
    assign_tag(user.signed_by_tag)
    unassign_tag(user.signature_requested_from_tag)

    # object, signed_tag
    unless has_tag?({ type: SignatureRequestedFromTag.to_s })
      assign_tag(user.tenant.signed_tag)
      unassign_tag(user.tenant.signature_requested_tag)
    end

    # thread, user_signed_tag
    unless has_tag_within_thread?(user.signature_requested_from_tag)
      assign_tag_to_thread(user.signed_by_tag)
      unassign_tag_from_thread(user.signature_requested_from_tag)
    end

    # thread, signed_tag
    unless has_tag_within_thread?({ type: SignatureRequestedFromTag.to_s })
      assign_tag_to_thread(user.tenant.signed_tag)
      unassign_tag_from_thread(user.tenant.signature_requested_tag)
    end
  end

  def add_signature_requested_from_user(user)
    # done, if already signed by user
    return if has_tag?(user.signed_by_tag)

    # object, user_signature_requested_tag
    assign_tag(user.signature_requested_from_tag)

    # object, signature_requested_tag
    assign_tag(user.tenant.signature_requested_tag)
    unassign_tag(user.tenant.signed_tag)

    # thread, user_signature_requested_tag
    assign_tag_to_thread(user.signature_requested_from_tag)
    unassign_tag_from_thread(user.signed_by_tag)

    # thread, signature_requested_tag
    assign_tag_to_thread(user.tenant.signature_requested_tag)
    unassign_tag_from_thread(user.tenant.signed_tag)
  end

  def remove_signature_requested_from_user(user)
    return unless has_tag?(user.signature_requested_from_tag)

    # object, user_signature_requested_tag
    unassign_tag(user.signature_requested_from_tag)

    # object, signature_requested_tag
    unless has_tag?({ type: SignatureRequestedFromTag.to_s })
      unassign_tag(user.tenant.signature_requested_tag)

      # object, back to signed_tag
      if has_tag?({ type: SignedByTag.to_s })
        assign_tag(user.tenant.signed_tag)
      end
    end

    # thread, user_signature_requested_tag
    unless has_tag_within_thread?(user.signature_requested_from_tag)
      unassign_tag_from_thread(user.signature_requested_from_tag)

      if has_tag_within_thread?(user.signed_by_tag)
        assign_tag_to_thread(user.signed_by_tag)
      end
    end

    # thread, signature_requested_tag
    unless has_tag_within_thread?({ type: SignatureRequestedFromTag.to_s })
      unassign_tag_from_thread(user.tenant.signature_requested_tag)

      if has_tag_within_thread?({ type: SignedByTag.to_s })
        assign_tag_to_thread(user.tenant.signed_tag)
      end
    end
  end

  def content
    message_object_datum&.blob
  end

  def form?
    object_type == "FORM"
  end

  def asice?
    mimetype == 'application/vnd.etsi.asic-e+zip'
  end

  def destroyable?
    # TODO: avoid loading message association if we have
    message.draft? && message.not_yet_submitted? && !form?
  end

  def archived?
    archived_object.present?
  end

  def downloadable_archived_object?
    archived_object&.archived?
  end

  private

  def allowed_mime_type?
    errors.add(:mime_type, "of #{name} object is disallowed, allowed_mime_types: #{Utils::EXTENSIONS_ALLOW_LIST.join(", ")}") unless mimetype
  end

  def has_tag?(tag)
    message_objects_tags.joins(:tag).where(tag: tag).exists?
  end

  def has_tag_within_thread?(tag)
    MessageObjectsTag.
      joins(:tag, message_object: :message).
      where(tag: tag, messages: { message_thread_id: message.message_thread_id }).
      exists?
  end

  def assign_tag(tag)
    message_objects_tags.find_or_create_by!(tag: tag)
  end

  def unassign_tag(tag)
    message_objects_tags.find_by(tag: tag)&.destroy
  end

  def assign_tag_to_thread(tag)
    message.thread.message_threads_tags.find_or_create_by!(tag: tag)
  end

  def unassign_tag_from_thread(tag)
    message.thread.message_threads_tags.find_by(tag: tag)&.destroy
  end
end
