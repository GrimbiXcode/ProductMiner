module Admin::CurrenciesHelper
  def sortable_currency_header(title, column)
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

    link_to label, admin_currencies_path(request.query_parameters.merge(sort: column, direction: next_dir, page: nil))
  end

  def currency_primary_country_name(currency)
    # returns the first three country names. if there are more than 3, it will append "..."
    # if there are no countries, it will return "-"
    currency.countries.map(&:name).take(3).join(", ") + (currency.countries.count > 3 ? "..." : "")
  end
end
