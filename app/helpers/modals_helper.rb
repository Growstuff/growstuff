# frozen_string_literal: true

# A form in a dialog over the page, instead of a page of its own. The form posts
# as it always has, so this needs no JSON endpoint; if the record can't be
# saved, its own form page shows why. Render it outside any dropdown, so it
# isn't torn down with the menu when it closes, and open it with
# MenusHelper#menu_modal_link. The block gets the form builder and holds the
# fields; any errors on the record are listed above them.
module ModalsHelper
  def form_modal(model, id:, title:, submit: 'Save', size: 'lg', &)
    title_id = "#{id}-title"
    tag.div(id:, class: 'modal fade', role: 'dialog', tabindex: -1, 'aria-hidden': 'true', 'aria-labelledby': title_id) do
      tag.div(class: "modal-dialog modal-#{size}", role: 'document') do
        tag.div(class: 'modal-content') { bootstrap_form_for(model) { |form| form_modal_body(form, title, title_id, submit, &) } }
      end
    end
  end

  private

  def form_modal_body(form, title, title_id, submit, &)
    header = tag.div(class: 'modal-header') do
      tag.h4(title, id: title_id, class: 'modal-title') +
        tag.button(type: 'button', class: 'btn-close', 'aria-label': 'Close', data: { 'bs-dismiss': 'modal' })
    end
    body = tag.div(form_modal_errors(form.object) + capture(form, &), class: 'modal-body plant-dialog-body')
    footer = tag.div(class: 'modal-footer') do
      tag.button('Cancel', type: 'button', class: 'btn btn-secondary', data: { 'bs-dismiss': 'modal' }) +
        form.submit(submit, class: 'btn btn-primary')
    end
    header + body + footer
  end

  def form_modal_errors(model)
    return ''.html_safe if model.errors.empty?

    tag.div(role: 'alert', class: 'alert alert-danger') do
      tag.ul(safe_join(model.errors.full_messages.map { |message| tag.li(message) }), class: 'mb-0')
    end
  end
end
