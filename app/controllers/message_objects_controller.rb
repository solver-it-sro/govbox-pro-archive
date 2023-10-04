class MessageObjectsController < ApplicationController
  before_action :set_message_object, except: :create
  before_action :set_message, only: [:create, :destroy]

  def create
    authorize @message

    MessageObject.create_message_objects(@message, params[:attachments])

    redirect_to polymorphic_url(@message)
  end

  def show
    authorize @message_object

    message_object_data = @message_object.content_to_show
    send_data message_object_data.content, filename: message_object_data.name, type: message_object_data.mimetype, disposition: :inline
  end

  def download
    authorize @message_object
    send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :download
  end

  def destroy
    authorize @message_object

    @message_object.destroy

    redirect_to polymorphic_url(@message)
  end

  private

  def set_message_object
    @message_object = policy_scope(MessageObject).find(params[:id])
  end

  def set_message
    @message = Message.find(params[:message_id])
  end
end
