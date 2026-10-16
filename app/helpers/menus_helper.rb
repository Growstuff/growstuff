# frozen_string_literal: true

# The three-dot actions menu every record uses. See DESIGN.md.
module MenusHelper
  # The kebab and its dropdown. `name` names the record ("seed"), giving the
  # wrapper `.seed-actions` and the toggle `#seed-actions-button`. The block
  # holds the items.
  def actions_menu(name, classes: nil, align: :end, &)
    toggle_id = "#{name}-actions-button"
    toggle = tag.a(id: toggle_id, href: '#', role: 'button', title: 'Actions', 'aria-label': 'Actions',
                   class: 'btn record-actions-toggle', 'aria-haspopup': 'true', 'aria-expanded': 'false',
                   data: { 'bs-toggle': 'dropdown' }) { tag.i(class: 'fas fa-ellipsis-v', 'aria-hidden': 'true') }
    menu = tag.div(capture(&), class: "dropdown-menu dropdown-menu-#{align}", 'aria-labelledby': toggle_id)
    tag.div(toggle + menu, class: ['dropdown', 'actions-menu', "#{name}-actions", classes])
  end

  # An item in an actions menu: a green line icon, then the label.
  def menu_link_to(icon, label, path, **options)
    options[:class] = ['dropdown-item', options[:class]]
    link_to(path, **options) { menu_icon(icon) + label }
  end

  # The Edit item that opens a modal instead of going to a page.
  def menu_modal_link(icon, label, target)
    tag.a(href: '#', class: 'dropdown-item', data: { 'bs-toggle': 'modal', 'bs-target': target }) do
      menu_icon(icon) + label
    end
  end

  def menu_delete_button(model, **)
    delete_button(model, classes: 'dropdown-item text-danger', icon: menu_icon(:delete), **)
  end
end
