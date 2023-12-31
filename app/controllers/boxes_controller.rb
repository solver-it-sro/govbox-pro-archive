class BoxesController < ApplicationController
  before_action :load_box, only: %i[show sync select]

  def index
    authorize Box
    @boxes = policy_scope(Box)
  end

  def show
    authorize @box, policy_class: BoxPolicy
  end

  def sync
    authorize @box, policy_class: BoxPolicy
    raise ActionController::MethodNotAllowed, 'Not authorized' unless policy_scope(Box).exists?(@box.id)

    Govbox::SyncBoxJob.perform_later(@box)
  end

  def select
    authorize @box
    session[:box_id] = @box.id
    redirect_back_or_to message_threads_path
  end

  def select_all
    authorize Box
    session[:box_id] = nil
    redirect_back_or_to message_threads_path
  end

  def search
    authorize(Box)

    boxes = Current.tenant.boxes.order(:name)
             .where('unaccent(name) ILIKE unaccent(?) OR unaccent(short_name) ILIKE unaccent(?)', "%#{params[:name_search]}%", "%#{params[:name_search]}%")
    set_boxes_with_unread_message_counts(boxes)
  end

  def get_selector
    authorize(Box)

    boxes = Current.tenant.boxes.order(:name)
    set_boxes_with_unread_message_counts(boxes)
  end

  private

  def load_box
    @box = policy_scope(Box).find(params[:id] || params[:box_id])
  end

  def set_boxes_with_unread_message_counts(boxes)
    unread_messages_per_box = policy_scope(Message).joins(:thread).where(read: false, message_threads: { box_id: boxes.to_a }).group("message_threads.box_id").count

    @boxes_with_unread_message_counts = boxes.map { |box| [box, unread_messages_per_box[box.id] || 0] }.to_h
  end
end
