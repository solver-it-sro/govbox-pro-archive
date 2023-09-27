class Govbox::SubmitMessageDraftJob < ApplicationJob
  def perform(message_draft, schedule_sync: true, upvs_client: UpvsEnvironment.upvs_client)
    message_draft_data = {
      posp_id: message_draft.metadata["posp_id"],
      posp_version: message_draft.metadata["posp_version"],
      message_type: message_draft.metadata["message_type"],
      message_id: message_draft.uuid,
      correlation_id: message_draft.metadata["correlation_id"],
      recipient_uri: message_draft.metadata["recipient_uri"],
      message_subject: message_draft.title,
      sender_business_reference: message_draft.metadata["sender_business_reference"],
      recipient_business_reference: message_draft.metadata["recipient_business_reference"],
      objects: build_objects(message_draft)
    }.compact

    sktalk_api = upvs_client.api(message_draft.thread.folder.box).sktalk
    success, response_status, response_body = sktalk_api.receive_and_save_to_outbox(message_draft_data)

    if success
      message_draft.metadata["status"] = "submitted"
      message_draft.save!

      Govbox::SyncBoxJob.set(wait: 3.minutes).perform_later(message_draft.thread.folder.box) if schedule_sync
    else
      handle_submit_fail(message_draft, response_status, response_body.dig("message"))
    end
  end

  class SubmissionError < StandardError
  end

  class TemporarySubmissionError < SubmissionError
  end

  private

  def build_objects(message_draft)
    objects = []
    message_draft.objects.each do |object|
      objects << {
        id: SecureRandom.uuid,
        name: object.name,
        encoding: "Base64",
        signed: object.is_signed,
        mime_type: object.mimetype,
        form: object.form?,
        content: Base64.strict_encode64(object.message_object_datum.blob)
      }.compact
    end

    objects
  end

  def handle_submit_fail(message_draft, response_status, response_message)
    case response_status
    when 408, 503
      message_draft.metadata["status"] = "temporary_submit_fail"
      message_draft.save

      raise TemporarySubmissionError, "#{response_status}, #{response_message}"
    else
      message_draft.metadata["status"] = "submit_fail"
      message_draft.save

      raise SubmissionError, "#{response_status}, #{response_message}"
    end
  end
end
