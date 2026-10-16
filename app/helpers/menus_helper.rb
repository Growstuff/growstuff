# frozen_string_literal: true

# The three-dot actions menu every record uses. See DESIGN.md.
module MenusHelper
  # The kebab and its dropdown. `name` names the record ("seed"), giving the
  # wrapper `.seed-actions` and the toggle `#seed-actions-button`; a menu that
  # repeats on a page passes the record's `id` to keep the toggle's id unique.
  # The block holds the items.
  def actions_menu(name, id: nil, classes: nil, align: :end, &)
    toggle_id = [name, id, 'actions-button'].compact.join('-')
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

  def menu_add_photo_link(model)
    return unless can?(:create, Photo)

    menu_link_to :add_photo, t('buttons.add_photo'), new_photo_path(id: model.id, type: model_type_for_photo(model)),
                 data: photo_dialog_data(model)
  end

  def menu_delete_button(model, **)
    delete_button(model, classes: 'dropdown-item text-danger', icon: menu_icon(:delete), **)
  end
end
