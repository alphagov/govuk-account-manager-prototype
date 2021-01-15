# frozen_string_literal: true

require "google/cloud/bigquery"

class BigqueryReportExportJob < ApplicationJob
  class DeleteError < StandardError; end
  class InsertError < StandardError; end

  DATASET_NAME = "daily"
  ACCOUNTS_TABLE_NAME = "accounts"
  EVENTS_TABLE_NAME = "events"

  queue_as :default

  def perform(start_date, end_date)
    bigquery = Google::Cloud::Bigquery.new(credentials: Rails.application.secrets.bigquery_credentials)
    dataset = bigquery.dataset DATASET_NAME

    replace_accounts_table(dataset: dataset)
    update_events_table(dataset: dataset, start_date: start_date, end_date: end_date)
  end

protected

  def replace_accounts_table(dataset:)
    report = Report::Accounts.report(
      user_id_pepper: Rails.application.secrets.reporting_user_id_pepper,
    )

    delete_job(dataset, ACCOUNTS_TABLE_NAME)
    insert_job(dataset, ACCOUNTS_TABLE_NAME, report)
  end

  def update_events_table(dataset:, start_date:, end_date:)
    report = Report::AccountEvents.report(
      user_id_pepper: Rails.application.secrets.reporting_user_id_pepper,
      start_date: start_date,
      end_date: end_date,
    )

    insert_job(dataset, EVENTS_TABLE_NAME, report)
  end

  def delete_job(dataset, table_name)
    delete_job = dataset.query_job "DELETE FROM #{table_name} WHERE 1 = 1"
    delete_job.wait_until_done!
    raise DeleteError, delete_error.error.dig("message") if delete_job.failed?
  end

  def insert_job(dataset, table_name, rows)
    table = dataset.table table_name
    insert_response = table.insert rows
    raise InsertError, "errors: #{insert_response.error_count}" unless insert_response.success?
  end
end
