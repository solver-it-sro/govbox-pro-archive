# frozen_string_literal: true

class Icons::TagsComponent < ViewComponent::Base
  def initialize(css_classes: nil)
    @css_classes = css_classes
  end
end
