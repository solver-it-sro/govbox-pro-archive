require "application_system_test_case"

class MessageThreadsTagsTest < ApplicationSystemTestCase
  setup do
    Searchable::MessageThread.reindex_all

    @thread_general = message_threads(:ssd_main_general)

    sign_in_as(:basic)
  end

  test "user can change tags" do
    visit message_thread_path(@thread_general)

    within("#messages") do
      within_tags do
        assert_text "Finance"
        assert_text "Legal"
        assert_text "Other"
      end
    end

    click_link "Upraviť štítky"

    check "Print"
    uncheck "Legal"

    fill_in "name_search_query", with: "Struction"

    within("#tags-assignment-list") do
      refute_text "Legal"
      refute_text "Print"
    end

    check "Construction"

    check "Struction"

    within("#tags-assignment-list") do
      assert_text "Legal"
      assert_text "Print"
      assert_text "Struction"
    end

    click_button "Uložiť zmeny"

    assert_text "Priradenie štítkov bolo upravené"

    within("#messages") do
      within_tags do
        assert_text "Finance"
        assert_text "Print"
        assert_text "Construction"
        assert_text "Struction"

        refute_text "Legal"
      end
    end
  end
end
