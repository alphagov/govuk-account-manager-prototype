# GOV.UK Account Manager - Prototype

A Prototype to explore how users might authenticate, authorise their data to be exchanged, be informed of data use and manage their consent for it.

## Developer setup

### Prerequisites
You must have the following installed:
- Docker
- Docker Compose

### First time setup

TODO: write

### Sending emails locally

You'll need to pass a GOV.UK Notify API key as an environment variable
`NOTIFY_API_KEY`, and change the delivery method in [development.rb][]:

```ruby
config.action_mailer.delivery_method = :notify
```

You'll also need to set a `GOVUK_NOTIFY_TEMPLATE_ID`, which might involve
creating a template in Notify if [your Notify service][] doesn't have one.

The template should have a Message of `((body))` only.

[development.rb]: config/environments/development.rb
[your Notify service]: https://www.notifications.service.gov.uk/accounts

## Deployment to GOV.UK via concourse

Every commit to master is deployed to GOV.UK PaaS by [this concourse pipeline](https://cd.gds-reliability.engineering/teams/govuk-tools/pipelines/govuk-account-manager-prototype), which is configured in [concourse/pipeline.yml](/concourse/pipeline.yml).

You will need to be logged into the GDS VPN to access concourse.

The concourse pipeline has credentials for the govuk-forms-deployer user in GOV.UK PaaS. This user has the SpaceDeveloper role, so it can cf push the application.

### Secrets

Secrets are defined via the GDS cli and Concourse secrets manager,

You can view live secrets with an authenticated cloud foundry command:
`cf env govuk-account-manager`.

Secrets are managed by Concourse secrets manager.
Once added secret can be called using a double parenthesis syntax.

You can see examples called as params for instance in the [deploy-app task](https://github.com/alphagov/govuk-account-manager-prototype/blob/master/concourse/pipeline.yaml#L25).

Concourse can also set them during a deploy using cloud foundry commands (eg. [See here in deploy-to-govuk-pass.yml](https://github.com/alphagov/govuk-account-manager-prototype/blob/master/concourse/tasks/deploy-to-govuk-paas.yml#L48:L58))

Adding or updating a secret can be done with Concourse secrets manager and the [GDS cli](https://docs.publishing.service.gov.uk/manual/get-started.html#3-install-gds-tooling)

```
gds cd secrets add cd-govuk-tools govuk-account-manager-prototype/SECRET_NAME your_secret_value
```

To remove a secret:

```
gds cd secrets rm cd-govuk-tools govuk-account-manager-prototype/SECRET_NAME
```

You would also need to unset it from the PaaS environment. Which you can do with this command:

```
 cf unset-env govuk-account-manager SECRET_NAME
```
