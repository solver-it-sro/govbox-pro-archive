# == Schema Information
#
# Table name: api_connections
#
#  id                                          :integer          not null, primary key
#  sub                                         :string           not null
#  obo                                         :uuid
#  api_token_private_key                       :string           not null
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null

class Govbox::ApiConnectionWithOboSupport < ::ApiConnection
  def invalid_box?(box)
    errors.add(:obo, :not_allowed) if obo && box.settings && box.settings["obo"].present?
  end
end
