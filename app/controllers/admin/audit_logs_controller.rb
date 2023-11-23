class Admin::AuditLogsController < ApplicationController
  before_action :set_audit_logs

  PAGE_SIZE = 50

  def index
    authorize [:admin, AuditLog]
    respond_to do |format|
      format.html
      format.csv do
        send_data @audit_logs.to_csv, filename: "audit-logs-actor-#{@actor.id}-Time.zone.now.to_fs(:db).csv" if @actor
        send_data @audit_logs.to_csv, filename: "audit-logs-thread-#{@thread.id}-Time.zone.now.to_fs(:db).csv" if @thread
      end
    end
  end

  def scroll
    authorize [:admin, AuditLog]
  end

  def set_audit_logs
    cursor = params[:cursor]
    @audit_logs = policy_scope([:admin, AuditLog]).order(happened_at: :desc, id: :desc)
    @audit_logs = @audit_logs.limit(PAGE_SIZE) unless request.format.csv?
    @audit_logs = @audit_logs.where("(happened_at, id) < (?, ?)", from_millis(cursor[:happened_at].to_f), cursor[:id]) if cursor
    set_audit_subject
    return unless @audit_logs.any?

    set_next
  end

  def set_audit_subject
    if params[:actor]
      @actor = policy_scope([:admin, User]).find(params[:actor])
      @audit_logs = @audit_logs.where(actor: @actor)
      @view = :actor
    end
    return unless params[:thread]

    @thread = policy_scope(MessageThread).find(params[:thread])
    @audit_logs = @audit_logs.where(thread: @thread)
    @view = :thread
  end

  def set_next
    @next_cursor = { happened_at: to_millis(@audit_logs.last.happened_at), id: @audit_logs.last.id }
    if @view == :actor
      @url = scroll_admin_audit_logs_path(actor: Current.user, cursor: @next_cursor, format: :turbo_stream)
    elsif @view == :thread
      @url = scroll_admin_audit_logs_path(thread: @thread, cursor: @next_cursor, format: :turbo_stream)
    end
  end

  def to_millis(time)
    time.strftime("%s%L")
  end

  def from_millis(millis)
    Time.zone.at(millis / 1000)
  end
end
