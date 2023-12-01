module TagCreation
  def simple_tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant,
      groups: [Current.user.user_group]
    }
  end
end
