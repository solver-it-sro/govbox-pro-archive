class MessagesController < ApplicationController
  before_action :set_message

  include MessagesConcern

  def show
    authorize @message

    @message.update(read: true)
  end

  def authorize_delivery_notification
    authorize @message

    notice = Message.authorize_delivery_notification(@message) ? "Správa bola zaradená na prevzatie." : "Správu nie je možné prevziať."
    redirect_to message_path(@message), notice: notice
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
    @notice = flash
    set_thread_tags_with_deletable_flag
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
