class Settings::Rules::ActionsFormComponent < ViewComponent::Base
  def initialize(automation_rule:)
    @automation_rule = automation_rule
    @new_rule = Current.tenant.automation_rules.new(actions: [Automation::Action.new])
  end
end
