module Iconized
  extend ActiveSupport::Concern

  def self.icons
    Common::IconComponent::ICONS.keys
  end

  included do
    validates_inclusion_of :icon, in: Iconized.icons, allow_blank: true
  end
end

