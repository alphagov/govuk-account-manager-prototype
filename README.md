# Set up the GOV.UK account manager prototype

The GOV.UK account manager prototype is an application to test how users:

- authenticate their data
- authorise their data for exchange
- stay informed of the use of their data
- manage consent for use of their data

This content tells you how to:

- set up and run the GOV.UK account manager prototype
- integrate the `finder-frontend` transition checker with the GOV.UK account manager

This content is for GOV.UK developers working on Macs or Linux. If you are not a GOV.UK developer, you cannot use this prototype.

## Install GOV.UK Docker

[Install GOV.UK Docker](https://github.com/alphagov/govuk-docker/blob/master/docs/installation.md). Make sure that you allocate at least the minimum resources specified in the [GOV.UK Docker settings guidance](https://github.com/alphagov/govuk-docker/blob/master/docs/installation.md#docker-settings) as running the prototype on your local machine is resource-intensive.

## Clone repositories to local machine

To set up GOV.UK account manager, clone the following repositories (repos) to the `~/govuk` folder on your local machine:

- the [GOV.UK account manager prototype](https://github.com/alphagov/govuk-account-manager-prototype)
- the [GOV.UK attribute service prototype](https://github.com/alphagov/govuk-attribute-service-prototype)
- the [finder frontend](https://github.com/alphagov/finder-frontend) that contains the transition checker
- the [email alert API](https://github.com/alphagov/email-alert-api/)

You [create the `~/govuk` folder](https://github.com/alphagov/govuk-docker/blob/master/docs/installation.md#prerequisites) when you install GOV.UK Docker.

Check out the following branches on the different repos:

- `enable-account-finder-frontend` branch on the GOV.UK Docker repo
- `main` branch on the GOV.UK account manager prototype repo
- `main` branch on the GOV.UK attribute service prototype repo
- `master` branch on the transition checker repo

## Start the prototype

In the command line, go to the `govuk/govuk-docker` repo folder and run the following commands:

- `make govuk-attribute-service-prototype`
- `make govuk-account-manager-prototype`
- `make finder-frontend`
- `make email-alert-api`

These commands set up a docker image, build the required system and gem dependencies, and set up the database.

## Prevent developers from deploying secrets

The Account Manager prototype uses the [Pre-Commit framework](https://pre-commit.com/) and the [`detect-secrets`](https://github.com/Yelp/detect-secrets) plugin to prevent developers deploying secrets.

### Install Pre-Commit framework

If you are using the [Homebrew Package Manager](https://brew.sh/) or [Linuxbrew](https://docs.brew.sh/Homebrew-on-Linux) on Mac, install Pre-Commit by running `brew install pre-commit` in the command line.

See [the Pre-Commit framework installation documentation](https://pre-commit.com/#installation) for more instructions on how to install Pre-Commit.

You must have Python 3 installed for this to work. Running the `brew install` command will install Python 3 as well. See the [Python downloads page](https://www.python.org/downloads/) for other ways to install Python 3 if required.

### Install `detect-secrets`

The `detect-secrets` plugin to the Pre-Commit framework detects secrets within a codebase.

To alert developers when they attempt to enter a secret in the codebase, [install the client-side pre-commit hook](https://github.com/Yelp/detect-secrets#client-side-pre-commit-hook).

## Start the transition checker and account manager prototype apps

In the command line, go to the `finder-frontend` repo folder and run `govuk-docker-up`. This starts the `finder-frontend` transition checker and its dependencies.

Open up a web browser and go to `https://finder-frontend.dev.gov.uk`.

If you have set up the apps correctly, you will be able to access the following links:

- the [transition checker journey start page](http://finder-frontend.dev.gov.uk/transition-check/questions)
- the [transition checker results page](http://finder-frontend.dev.gov.uk/transition-check/results?c[]=living-ie) that reflects the answers you give during the transition checker journey
- select the subscribe banner or button to access the [account sign up page](http://finder-frontend.dev.gov.uk/transition-check/save-your-results?c%5B%5D=living-ie)

When you have set up your local account, you can [sign into your account](http://www.login.service.dev.gov.uk/) and view the manage screens.

You have now set up and run the GOV.UK account manager prototype, and integrated the `finder-frontend` transition checker with the GOV.UK account manager.

## Sending emails locally

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

## Running the tests

You don't need govuk-accounts-docker to run the tests, a local postgres database is enough:

```
docker run --rm -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=db -p 5432:5432 postgres:13
```

Set up your environment and create the database tables:

```
export TEST_DATABASE_URL="postgresql://postgres:postgres@127.0.0.1/db"
bundle exec rake db:migrate RAILS_ENV=test
```

Then you can run the tests with:

```
bundle exec rake
```

## Deployment to GOV.UK via concourse

Every commit to main is deployed to GOV.UK PaaS by [this concourse pipeline](https://cd.gds-reliability.engineering/teams/govuk-tools/pipelines/govuk-account-manager-prototype), which is configured in [concourse/pipeline.yml](/concourse/pipeline.yml).

You will need to be logged into the GDS VPN to access concourse.

The concourse pipeline has credentials for the govuk-accounts-developers user in GOV.UK PaaS. This user has the SpaceDeveloper role, so it can `cf push` the application.

## Secrets

Secrets are defined via the [gds-cli](https://github.com/alphagov/gds-cli) and Concourse secrets manager.

You can view live secrets with an authenticated cloud foundry command:
`cf env govuk-account-manager`.

Adding or updating a secret can be done with Concourse secrets manager and the [GDS cli](https://docs.publishing.service.gov.uk/manual/get-started.html#3-install-gds-tooling).

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

## Creating a new OAuth application

First get a Rails console.  For example, when running locally in Docker Compose:

```
docker ps
docker exec -it ${container_id} rails console
```

Then create a new `Doorkeeper::Application`:

```
a = Doorkeeper::Application.create!(name: "...", redirect_uri: "...", scopes: [...])
puts "client id:     #{a.uid}"
puts "client secret: #{a.secret}"
```

You will probably want `openid` in the list of scopes.

## Disabling registrations

Set the `ENABLE_REGISTRATION` environment variable to `false` to
disable the registration form.

To do this in production / staging:

1. Edit `concourse/pipeline.yml`, changing `ENABLE_REGISTRATION: "true"` to  `ENABLE_REGISTRATION: "false"` in the relevant environment
2. Deploy the pipeline change (happens automatically on push to main)
3. Deploy the application (happens automatically on push to main)

If changing the pipeline isn't feasible (for example, you are doing
this out-of-hours and nobody else is around), you can use the PaaS CLI
to set the environment variable:

1. Log into the PaaS
2. `cf set-env govuk-account-manager ENABLE_REGISTRATION false`
3. `cf restage govuk-account-manager`

This approach will cause some brief downtime as the app restarts, and
the environment variable change will be lost on the next Concourse
deployment.
