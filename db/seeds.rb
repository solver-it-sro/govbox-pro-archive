# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or find_or_create_byd alongside the database with db:setup).
#

tenant = Tenant.find_or_create_by!(name: 'Dummy Tenant')

ENV['SITE_ADMIN_EMAILS'].to_s.split(',').each.with_index(1) do |email, i|
  tenant.users.find_or_create_by!(email: email, name: "Site ADMIN User #{i}")
end

box = tenant.boxes.find_or_create_by!(name: "Dev box", uri: "ico://sk/83300252")
Govbox::ApiConnection.find_or_create_by!(sub: "SPL_Irvin_83300252_KK_24022023", box_id: box.id, api_token_private_key: File.read(Rails.root + "security/govbox_api_fix.pem"))

tenant.tags.find_or_create_by!(name: 'NASES', user_id: tenant.users.first.id)

if tenant.users.first
  rule = tenant.automation_rules.create!(name: 'NASES Tag Sender Rule', user: tenant.users.first, trigger_event: :message_created)
  rule.conditions.find_or_create_by!(attr: :sender_name, type: 'Automation::ContainsCondition', value: 'Národná agentúra pre sieťové')
  rule.actions.find_or_create_by!(type: 'Automation::AddTagAction', value: 'NASES')
  rule.actions.find_or_create_by!(type: 'Automation::AddMessageThreadTagAction', value: 'NASES')

  rule = tenant.automation_rules.create!(name: 'NASES Tag Recipient Rule', user: tenant.users.first, trigger_event: :message_created)
  rule.conditions.find_or_create_by!(attr: :recipient_name, type: 'Automation::ContainsCondition', value: 'Národná agentúra pre sieťové')
  rule.actions.find_or_create_by!(type: 'Automation::AddTagAction', value: 'NASES')
  rule.actions.find_or_create_by!(type: 'Automation::AddMessageThreadTagAction', value: 'NASES')

  rule = tenant.automation_rules.create!(name: 'NASES Tag URI Sender Rule', user: tenant.users.first, trigger_event: :message_created)
  rule.conditions.find_or_create_by!(attr: :sender_uri, type: 'Automation::MetadataValueCondition', value: 'ico://sk/42156424_10037')
  rule.actions.find_or_create_by!(type: 'Automation::AddTagAction', value: 'NASES')
  rule.actions.find_or_create_by!(type: 'Automation::AddMessageThreadTagAction', value: 'NASES')

  rule = tenant.automation_rules.create!(name: 'NASES Tag URI Recipient Rule', user: tenant.users.first, trigger_event: :message_created)
  rule.conditions.find_or_create_by!(attr: :recipient_uri, type: 'Automation::MetadataValueCondition', value: 'ico://sk/42156424_10037')
  rule.actions.find_or_create_by!(type: 'Automation::AddTagAction', value: 'NASES')
  rule.actions.find_or_create_by!(type: 'Automation::AddMessageThreadTagAction', value: 'NASES')
end
