class MessageThreadTagsAssignmentsController < ApplicationController
  before_action :set_message_thread

  def edit
    authorize MessageThreadsTag

    set_tags_for_filter
    @init_tags_assignments = TagsAssignments.init(@all_tags, @message_thread.tag_ids)
    @new_tags_assignments = @init_tags_assignments

    @diff = TagsAssignments.build_diff(@init_tags_assignments, @new_tags_assignments, tag_scope)
  end

  def prepare
    authorize MessageThreadsTag

    @init_tags_assignments = tags_assignments[:init].to_h
    @new_tags_assignments = tags_assignments[:new].to_h

    @name_search_query = params[:name_search_query].strip

    set_tags_for_filter(@name_search_query)
    @diff = TagsAssignments.build_diff(@init_tags_assignments, @new_tags_assignments, tag_scope)
  end

  def create_tag
    new_tag = Tag.new(tag_creation_params.merge(name: params[:new_tag].strip))
    authorize(new_tag, "create?")

    @init_tags_assignments = tags_assignments[:init].to_h
    @new_tags_assignments = tags_assignments[:new].to_h

    if new_tag.save
      TagsAssignments.add_new_tag(@new_tags_assignments, new_tag)
    end

    @reset_search_filter = true
    @name_search_query = ""

    set_tags_for_filter(@name_search_query)
    @diff = TagsAssignments.build_diff(@init_tags_assignments, @new_tags_assignments, tag_scope)

    render :prepare
  end

  def update
    authorize MessageThreadsTag

    diff = TagsAssignments.build_diff(
      tags_assignments[:init].to_h,
      tags_assignments[:new].to_h,
      tag_scope
    )

    TagsAssignments.save(
      message_thread: @message_thread,
      tags_to_add: diff.to_add,
      tags_to_remove: diff.to_remove
    )

    # status: 303 is needed otherwise PATCH is kept in the following redirect https://apidock.com/rails/ActionController/Redirecting/redirect_to
    redirect_to message_thread_path(@message_thread), notice: "Priradenie štítkov bolo upravené", status: 303
  end

  private

  def set_message_thread
    @message_thread = message_thread_policy_scope.find(params[:id])
  end

  def set_tags_for_filter(name_search = "")
    @all_tags = tag_scope

    @filtered_tag_ids = @all_tags
    if name_search
      @filtered_tag_ids = @filtered_tag_ids.where('unaccent(name) ILIKE unaccent(?)', "%#{name_search}%")
    end
    @filtered_tag_ids = Set.new(@filtered_tag_ids.pluck(:id))
  end

  def tag_scope
    Current.tenant.tags.visible.order(:name)
  end

  def message_thread_policy_scope
    policy_scope(MessageThread)
  end

  def tags_assignments
    params.require(:tags_assignments).permit(init: {}, new: {})
  end

  def tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant,
      groups: [Current.user.user_group]
    }
  end
end
