require 'csv'

class Submissions::LoadSubmissionContentJob < ApplicationJob
  queue_as :high_priority

  class << self
    delegate :uuid, to: SecureRandom
  end

  def perform(submission, submission_path)
    Dir.each_child(submission_path) do |subdirectory_name|
      case subdirectory_name
      when "podpisane"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), true, false)
      when "podpisat"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), false, true)
      when "nepodpisovat"
        load_submission_objects(submission, File.join(submission_path, subdirectory_name), false, false)
      end
    end

    submission.update(status: "loading_done")

    # TODO confirm if OK
    # TODO package folder needs to be deleted to (schedule deleting it later?)
    FileUtils.rm_rf(submission_path)
  end

  private

  def load_submission_objects(submission, objects_path, signed, to_be_signed)
    Dir.foreach(objects_path) do |filename|
      next if filename == '.' or filename == '..'

      Submissions::Object.create(
        submission_id: submission.id,
        uuid: uuid,
        name: filename,
        content: File.read(File.join(objects_path, filename)),
        form: form?(submission, filename),
        signed: signed,
        to_be_signed: to_be_signed
      )
    end
  end

  def form?(submission, filename)
    file_basename = File.basename(filename, ".*")

    # Form file must have the same name as subfolder
    file_basename == submission.package_subfolder
  end

  delegate :uuid, to: self
end
