# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or find_or_create_byd alongside the database with db:setup).
#

tenant = Tenant.find_or_create_by!(name: 'Dummy Tenant')

ENV['SITE_ADMIN_EMAILS'].to_s.split(',').each.with_index(1) do |email, i|
  tenant.users.find_or_create_by!(email: email, name: "Site ADMIN User #{i}")
end

box = tenant.boxes.create!(name: "Dev box", uri: "ico://sk/83300252")
Govbox::ApiConnection.create!(sub: "SPL_Irvin_83300252_KK_24022023", box: box, api_token_private_key: File.read(Rails.root + "security/govbox_api_fix.pem"))

tenant.tags.create!(name: 'RuleTest')

if tenant.users.first
  rule = tenant.automation_rules.create!(name: 'Message Thread Name Rule Test', user: tenant.users.first, trigger_event: :message_created)
  rule.conditions.create!(attr: :title, operator: :contains, value: 'neplat')
  rule.actions.create!(name: :add_tag, params: 'RuleTest')
end
