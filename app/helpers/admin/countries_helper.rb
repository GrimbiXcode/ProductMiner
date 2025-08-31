module Admin::CountriesHelper
  def sortable_country_header(title, column)
    current_sort = params[:sort].presence || 'id'
    current_dir = params[:direction].presence || 'asc'
    next_dir = (current_sort == column && current_dir == 'asc') ? 'desc' : 'asc'

    active = (current_sort == column)
    arrow = if active
              current_dir == 'asc' ? '▲' : '▼'
            else
              '↕'
            end
    arrow_classes = active ? 'ml-1 inline-block text-gray-700' : 'ml-1 inline-block text-gray-300'

    label = safe_join([title.to_s, content_tag(:span, " #{arrow}", class: arrow_classes)])

    link_to label, admin_countries_path(request.query_parameters.merge(sort: column, direction: next_dir, page: nil))
  end
end
