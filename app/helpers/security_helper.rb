module SecurityHelper
  def paginated_navigation(things, path_helper)
    page_navigation = {
      current_page: things.current_page,
      total_pages: things.total_pages,
      out_of_range: things.out_of_range?,
    }

    return page_navigation if page_navigation[:out_of_range]

    unless things.first_page?
      page_navigation[:previous_page] = {
        url: path_helper.call(things.prev_page),
        title: t("account.security.page_numbering_previous"),
        label: t("account.security.page_numbering_navigation", target_page: things.prev_page, total_pages: things.total_pages),
      }
    end

    unless things.last_page?
      page_navigation[:next_page] = {
        url: path_helper.call(things.next_page),
        title: t("account.security.page_numbering_next"),
        label: t("account.security.page_numbering_navigation", target_page: things.next_page, total_pages: things.total_pages),
      }
    end

    page_navigation
  end
end
