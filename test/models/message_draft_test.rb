require "test_helper"

class MessageDraftTest < ActiveSupport::TestCase
  test 'after destroy callback should keep message thread drafts tag if message drafts present' do
    message_draft = messages(:ssd_main_general_draft_one)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread
    drafts_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    message_draft.destroy

    assert message_thread.tags.include?(drafts_tag)
  end

  test 'after destroy callback should delete message thread drafts tag if no message drafts left' do
    message_draft = messages(:ssd_main_delivery_draft)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread
    drafts_tag = message_thread.tags.find_by(type: DraftTag.to_s)

    message_draft.destroy

    assert !message_thread.tags.include?(drafts_tag)
  end

  test 'after destroy callback should destroy message thread if no messages left' do
    message_draft = messages(:ssd_main_delivery_draft)
    message_draft._run_create_callbacks

    message_thread = message_draft.thread

    message_draft.destroy

    assert message_thread.destroyed?
  end
end
