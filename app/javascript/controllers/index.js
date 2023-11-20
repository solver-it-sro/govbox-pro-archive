// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import AutogramController from "./autogram_controller"
application.register("autogram", AutogramController)

import MessageDraftsController from "./message_drafts_controller"
application.register("messageDrafts", MessageDraftsController)

import DebounceController from "./debounce_controller"
application.register("debounce", DebounceController)

import FormController from "./form_controller"
application.register("form", FormController)

import TurboContentController from "./turbo_content_controller"
application.register("turbo-content", TurboContentController)

import DismissibleAlertController from "./dismissible_alert_controller"
application.register("dismissible-alert", DismissibleAlertController)

import AutofocusController from "./autofocus_controller"
application.register("autofocus", AutofocusController)

import TriStateCheckboxController from "./tri_state_checkbox_controller"
application.register("tri-state-checkbox", TriStateCheckboxController)

import TextWrapController from "./text_wrap_controller"
application.register("text-wrap", TextWrapController)
