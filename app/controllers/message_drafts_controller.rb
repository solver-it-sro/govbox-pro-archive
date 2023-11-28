class MessageDraftsController < ApplicationController
  before_action :load_message_drafts, only: %i[index submit_all]
  before_action :load_original_message, only: :create
  before_action :load_message_template, only: :create
  before_action :load_message_draft, except: [:index, :create, :submit_all]

  include ActionView::RecordIdentifier
  include MessagesConcern
  include MessageThreadsConcern

  def index
    @messages = @messages.order(created_at: :desc)
  end

  def create
    @message = MessageDraft.new
    authorize @message

    @message_template.create_message(@message, author: Current.user, box: Current.box, recipient_uri: new_message_draft_params[:recipient])
    redirect_to message_thread_path(@message.thread)
  end

  def show
    authorize @message

    @message_thread = @message.thread

    set_thread_messages
    set_visible_tags_for_thread
  end

  def update
    authorize @message

    @message.update_content(message_draft_params)
  end

  def submit
    authorize @message

    if @message.submittable?
      Govbox::SubmitMessageDraftJob.perform_later(@message)
      @message.being_submitted!

      redirect_to message_thread_path(@message.thread), notice: "Správa bola zaradená na odoslanie"
    else
      # TODO: prisposobit chybovu hlasku aj importovanym draftom
      redirect_to message_thread_path(@message.thread), alert: "Vyplňte text správy"
    end
  end

  def submit_all
    jobs_batch = GoodJob::Batch.new

    @messages.each do |message_draft|
      next unless message_draft.submittable?

      jobs_batch.add { Govbox::SubmitMessageDraftJob.perform_later(message_draft, schedule_sync: false) }
      message_draft.being_submitted!
    end

    boxes_to_sync = Current.tenant.boxes.joins(message_threads: :messages).where(messages: { id: @messages.map(&:id) } ).uniq
    jobs_batch.enqueue(on_finish: Govbox::ScheduleDelayedSyncBoxJob, boxes: boxes_to_sync)
  end

  def destroy
    authorize @message

    redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_drafts_path

    @message.destroy

    redirect_to redirect_path, notice: "Draft bol zahodený"
  end

  private

  def load_message_drafts
    authorize MessageDraft
    @messages = policy_scope(MessageDraft)
  end

  def load_original_message
    @original_message = policy_scope(Message).find(params[:original_message_id]) if params[:original_message_id]
  end

  def load_message_template
    @message_template = policy_scope(MessageTemplate).find(new_message_draft_params[:message_template])
  end

  def load_message_draft
    @message = policy_scope(MessageDraft).find(params[:id])
  end

  def message_draft_params
    attributes = MessageTemplateParser.parse_template_placeholders(@message.template).map{|item| item[:name]}
    params[:message_draft].permit(attributes)
  end

  def new_message_draft_params
    params.permit(:message_template, :recipient)
  end
end
