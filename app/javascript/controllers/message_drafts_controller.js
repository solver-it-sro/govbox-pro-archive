import { Controller } from "@hotwired/stimulus"
import { get, patch } from '@rails/request.js'

export default class extends Controller {
  connect() {
    const newDraftsElement = document.getElementById("new_drafts")
    newDraftsElement.addEventListener("DOMNodeInserted", this.showLastMessageDraft);
  }

  async loadTemplateRecipients() {
    const messageDraftTemplateId = document.getElementById("message_draft_template").value;
    const templateRecipientsPath = `/message_draft_templates/${messageDraftTemplateId}/recipients_list`;
    await get(templateRecipientsPath, { responseKind: "turbo-stream" })
  }

  async update() {
    const messageDraftBodyFormId = this.data.get("messageDraftBodyFormId");
    document.getElementById(messageDraftBodyFormId).requestSubmit();
  }

  uploadAttachments() {
    const attachmentsFormId = this.data.get("attachmentsFormId");
    document.getElementById(attachmentsFormId).requestSubmit();
  }

  showLastMessageDraft() {
    const messageDraftsTexts = document.querySelectorAll('textarea[name^="message_draft[Text]"]');
    const length = messageDraftsTexts.length;
    if (messageDraftsTexts.length > 1) {
      messageDraftsTexts[length - 2].setAttribute('autofocus', false);
    }
    messageDraftsTexts[length - 1].focus();

    const drafts = document.querySelectorAll(".draft");
    const lastDraft = drafts[drafts.length - 1];
    lastDraft.scrollIntoView();
  }
}
