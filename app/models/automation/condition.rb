module Automation
  class Condition < ApplicationRecord
    belongs_to :automation_rule, class_name: 'Automation::Rule'

    attr_accessor :delete_record
    # neviem ich z kodu vylistovat, vid conditions_form_component.rb
    # enum attr: %i[sender_name recipient_name title sender_uri recipient_uri]
  end

  class ContainsCondition < Automation::Condition
    def satisfied?(thing)
      thing[attr]&.match?(value)
    end
  end

  class MetadataValueCondition < Automation::Condition
    def satisfied?(thing)
      thing.metadata && thing.metadata[attr]&.match?(value)
    end
  end
end
