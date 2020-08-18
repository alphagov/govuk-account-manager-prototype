class DataExchangeController < ApplicationController
  before_action :authenticate_user!

  DENYLIST_SCOPES = %i[
    openid
    transition_checker
  ].freeze

  def show
    @data_exchanges = current_user
      .access_grants
      .order(created_at: :desc)
      .map { |g| grant_to_exchange(g) }
      .compact
  end

private

  def grant_to_exchange(grant)
    scopes = grant.scopes.map(&:to_sym) - DENYLIST_SCOPES
    return if scopes.empty?

    {
      application_name: grant.application.name,
      created_at: grant.created_at,
      scopes: scopes,
    }
  end
end
