json.file_name @message_object.name
json.mime_type @message_object.mimetype
json.object_type @message_object.object_type
json.schema Base64.strict_encode64(@message_object_schema) if @message_object_schema
json.transformation Base64.strict_encode64(@message_object_transformation) if @message_object_transformation
json.content Base64.strict_encode64(@message_object_content)
