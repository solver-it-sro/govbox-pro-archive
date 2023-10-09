class MessageThreadsController < ApplicationController
  before_action :set_message_thread, only: %i[show update]
  before_action :load_threads, only: %i[index scroll]

  include MessageThreadsConcern

  def show
    authorize @message_thread
    set_thread_tags_with_deletable_flag
    @notice = flash
    @message_thread.mark_all_messages_read
    @thread_messages = @message_thread.messages_visible_to_user(Current.user).order(delivered_at: :asc)
  end

  def update
    authorize @message_thread
    if @message_thread.update(message_thread_params)
      redirect_back fallback_location: messages_path(@message_thread.messages.first)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def index
    authorize MessageThread
  end

  def scroll
    authorize MessageThread
  end

  def load_threads
    cursor = MessageThreadCollection.init_cursor(search_params[:cursor])

    result =
      MessageThreadCollection.all(
        scope: message_thread_policy_scope.includes(:tags, :box),
        search_permissions: search_permissions,
        query: search_params[:q],
        no_visible_tags: search_params[:no_visible_tags] == "1" && Current.user.admin?,
        cursor: cursor
      )

    @message_threads, @next_cursor = result.fetch_values(:records, :next_cursor)
    @next_cursor = MessageThreadCollection.serialize_cursor(@next_cursor)
    @next_page_params = search_params.to_h.merge(cursor: @next_cursor).merge(format: :turbo_stream)
  end

  def merge
    authorize MessageThread
    @selected_message_threads = message_thread_policy_scope.where(id: params[:message_thread_ids]).order(:last_message_delivered_at)
    if !@selected_message_threads || @selected_message_threads.size < 2
      flash[:error] = 'Označte zaškrtávacími políčkami minimálne 2 vlákna, ktoré chcete spojiť'
      redirect_back fallback_location: message_threads_path
      return
    end
    @selected_message_threads.merge_threads
    flash[:notice] = 'Vlákna boli úspešne spojené'
    redirect_to @selected_message_threads.first
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:id])
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def search_permissions
    result = { tenant_id: Current.tenant }
    result[:box_id] = Current.box if Current.box
    result[:tag_ids] = policy_scope(Tag).pluck(:id) unless Current.user.admin?
    result
  end

  def message_thread_params
    params.require(:message_thread).permit(:title, :original_title, :merge_uuids, :tag_id, :tags)
  end

  def search_params
    params.permit(:q, :no_visible_tags, :format, cursor: MessageThreadCollection::CURSOR_PARAMS)
  end
end
