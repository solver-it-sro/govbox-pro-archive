import { Controller } from "@hotwired/stimulus"
import { post, patch } from '@rails/request.js'

export default class extends Controller {
  connect() {
    const messagesElement = document.getElementById("messages")
    messagesElement.addEventListener("DOMNodeInserted", this.showLastMessageDraft);
  }

  async create() {
    const authenticityToken = this.data.get("authenticityToken");
    const messageDraftPath = this.data.get("messageDraftPath");
    const originalMessageId = this.data.get("originalMessageId");

    await post(messageDraftPath, {
      body: JSON.stringify({
        authenticity_token: authenticityToken,
        original_message_id: originalMessageId
      }),
      responseKind: "turbo-stream"
    })
  }

  async update() {
    const authenticityToken = this.data.get("authenticityToken");
    const messageDraftPath = this.data.get("messageDraftPath");
    const messageDraftTitleId = this.data.get("titleId");
    const messageDraftTextId = this.data.get("textId");

    await patch(messageDraftPath, {
      body: JSON.stringify({
        authenticity_token: authenticityToken,
        message_title: document.getElementById(messageDraftTitleId).value,
        message_text: document.getElementById(messageDraftTextId).value
      })
    })
  }

  uploadAttachments() {
    const attachmentsFormId = this.data.get("attachmentsFormId");
    document.getElementById(attachmentsFormId).requestSubmit();
  }

  showLastMessageDraft() {
    const messageDraftsTexts = document.querySelectorAll('textarea[id^="text_message_draft_"]');

    for(var i = 0; i < messageDraftsTexts.length; i++){
      if (i !== messageDraftsTexts.length - 1) {
        messageDraftsTexts[i].setAttribute('autofocus', false);
      }
      else {
        messageDraftsTexts[i].focus();
      }
    }

    const drafts = document.querySelectorAll(".draft");
    const lastDraft = drafts[drafts.length-1];
    lastDraft.scrollIntoView();
  }
}
