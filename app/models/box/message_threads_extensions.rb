class Box
  module MessageThreadsExtensions
    def find_or_create_by_merge_uuid!(folder:, merge_uuid:, title:, delivered_at:)
      thread = MessageThread.joins(:merge_identifiers).where("message_thread_merge_identifiers.uuid = ?", merge_uuid).take

      # Make sure that thread belongs to the tenant
      if thread&.tenant != folder.tenant
        thread = nil
      end

      if thread
        if thread.delivered_at > delivered_at
          # out-of-order processing
          thread.title = title
          thread.original_title = title
          thread.folder = folder
          thread.delivered_at = delivered_at
        end
      else
        thread = build(
          folder: folder,
          title: title,
          original_title: title,
          delivered_at: delivered_at,
        )
        thread.merge_identifiers.build(uuid: merge_uuid)
      end

      thread.save!

      thread
    end
  end
end