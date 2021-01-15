# frozen_string_literal: true

require "google/cloud/bigquery"

class BigqueryReportExportJob < ApplicationJob
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

    delete_job = dataset.query_job "DELETE FROM #{ACCOUNTS_TABLE_NAME} WHERE 1 = 1"
    delete_job.wait_until_done!

    table = dataset.table ACCOUNTS_TABLE_NAME
    table.insert report
  end

  def update_events_table(dataset:, start_date:, end_date:)
    report = Report::AccountEvents.report(
      user_id_pepper: Rails.application.secrets.reporting_user_id_pepper,
      start_date: start_date,
      end_date: end_date,
    )

    table = dataset.table EVENTS_TABLE_NAME
    table.insert report
  end
end
