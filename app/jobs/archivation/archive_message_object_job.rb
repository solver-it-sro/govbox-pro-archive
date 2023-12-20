class Archivation::ArchiveMessageObjectJob < ApplicationJob
  def perform(object, archiver_client: Archiver::ArchiverApiClient)
    object.archived_object = create_archived_object(object, archiver_client) if object.archived_object.nil?
    return unless object.archived_object.archived_object_versions.empty? || object.archived_object.archived_object_versions.last.valid_to < DateTime.now.since(90.days)
    Archivation::ExtendArchivedObjectJob.perform_later(object.archived_object)
  end

  private

  def create_archived_object(object, archiver_client)
    response = archiver_client.api.validate_document(object.content)
    return signed_archived_object(response, object) unless response.nil?

    archived_object = ArchivedObject.new(validation_result: '-1', signature_level: nil, message_object: object)
    archived_object.save
    archived_object
  end

  def signed_archived_object(response, object)
    signature_info = response['signatures'].first['signatureInfo']
    archived_object = ArchivedObject.new(validation_result: validation_result_code(response), signature_level: signature_info['level'], message_object: object)
    archived_object.save
    archived_object
  end

  def validation_result_code(validation_response)
    result = -1
    validation_response['signatures'].each do |s|
      result = s['validationResult']['code'] if s['validationResult']['code'] > result
    end

    result
  end
end
