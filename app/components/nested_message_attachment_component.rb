class NestedMessageAttachmentComponent < ViewComponent::Base
  def initialize(nested_message_attachment:, nested_message_attachment_iteration:)
    @nested_message_attachment = nested_message_attachment
    @message_object = @nested_message_attachment.message_object
    @message = @message_object.message
    @is_last = nested_message_attachment_iteration.last?
  end
end
