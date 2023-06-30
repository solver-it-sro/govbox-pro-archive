module Automation
  class MessageCreatedJob < ApplicationJob
    queue_as :default

    def perform(message)
      Automation.run_rules_for(message, :message_created)
      #tenant = message_thread.tenant

      #tenant.automation_rules.where(trigger_event: :message_thread_created).find_each do |rule|
        # TODO

        # simulate for now
       # rule.conditions = [Automation::Conditions::MessageThreadFilter.new(title: /Všeobecná agenda/)]
        #rule.action = Automation::Actions::MoveToFolder.new(Folder.second!)

#        rule.run!(message_thread)
#      end
    end
  end
end
