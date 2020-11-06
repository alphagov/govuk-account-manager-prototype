# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  sidekiq_options retry: false
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
end
