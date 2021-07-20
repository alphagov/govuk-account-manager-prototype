# Manuals
See further howtos in [Team Manual](https://team-manual.account.publishing.service.gov.uk/).

# Set up the GOV.UK account manager prototype

The GOV.UK account manager prototype is an application to test how users:

- authenticate their data
- authorise their data for exchange
- stay informed of the use of their data
- manage consent for use of their data

This content tells you how to:

- set up and run the GOV.UK account manager prototype
- integrate the `finder-frontend` Brexit transition checker with the GOV.UK account manager

This content is for GOV.UK developers working on Macs or Linux. If you are not a GOV.UK developer, you cannot use this prototype.

## Install GOV.UK Docker

[Install GOV.UK Docker](https://github.com/alphagov/govuk-docker). Make sure that you allocate at least the minimum resources specified in the [GOV.UK Docker installation guidance](https://github.com/alphagov/govuk-docker/blob/master/README.md#installation) as running the prototype on your local machine is resource-intensive.

## Clone repositories to local machine

To set up GOV.UK account manager, ensure you have a `~/govuk` directory.

Clone the following repositories (repos) to the `~/govuk` folder on your local machine:

- the [GOV.UK account manager prototype](https://github.com/alphagov/govuk-account-manager-prototype)
- the [GOV.UK attribute service prototype](https://github.com/alphagov/govuk-attribute-service-prototype)
- the [finder frontend](https://github.com/alphagov/finder-frontend) that contains the Brexit transition checker
- the [email alert API](https://github.com/alphagov/email-alert-api/)

Check out the following branches on the different repos:

- `master` branch on the GOV.UK Docker repo
- `main` branch on the GOV.UK account manager prototype repo
- `main` branch on the GOV.UK attribute service prototype repo
- `master` branch on the Brexit transition checker repo

## Set up the docker image and database

In the command line, go to the `govuk/govuk-docker` repo folder and run the following commands:

- `make govuk-attribute-service-prototype`
- `make govuk-account-manager-prototype`
- `make finder-frontend`
- `make email-alert-api`

These commands set up a docker image, build the required system and gem dependencies, and set up the database.

## Start the Brexit transition checker and account manager prototype apps

In the command line, go to the `finder-frontend` repo folder and run `govuk-docker-up`. This starts the `finder-frontend` Brexit transition checker and its dependencies.

Open up a web browser and go to `https://finder-frontend.dev.gov.uk`.

If you have set up the apps correctly, you will be able to access the following links:

- the [Brexit transition checker journey start page](http://finder-frontend.dev.gov.uk/transition-check/questions)
- the [Brexit transition checker results page](http://finder-frontend.dev.gov.uk/transition-check/results?c[]=living-ie) that reflects the answers you give during the Brexit transition checker journey
- select the subscribe banner or button to access the [account sign up page](http://finder-frontend.dev.gov.uk/transition-check/save-your-results?c%5B%5D=living-ie)

When you have set up your local account, you can [sign into your account](http://www.login.service.dev.gov.uk/) and view the manage screens.

You have now set up and run the GOV.UK account manager prototype, and integrated the `finder-frontend` Brexit transition checker with the GOV.UK account manager.

## Troubleshooting

If you are having issues setting up and running the GOV.UK account manager prototype, it might be because:

- you have not allocated enough resources to GOV.UK Docker
- there have been backend changes to the database or the prototypes
- there have been [Ruby on Rails](https://rubyonrails.org/) configuration changes to the app

### Not enough resources allocated to GOV.UK Docker

To change the resource allocation for GOV.UK Docker, see the [GOV.UK Docker readme](https://github.com/alphagov/govuk-docker/blob/master/README.md#installation).

### Backend changes to the database or the prototypes

To account for recent backend changes, go to the main branch of your local GOV.UK Docker repo and run the following in the command line:

```
govuk-docker run govuk-account-manager-prototype-lite bundle exec rake db:migrate
govuk-docker run govuk-account-manager-prototype-lite bundle exec rake db:migrate RAILS_ENV=test
```

Then [restart the Brexit transition checker and account manager prototype apps](#start-the-transition-checker-and-account-manager-prototype-apps).

### Ruby on Rails configuration changes to the app

If there have been Ruby on Rails configuration changes to the app, you must restart the app to see these changes reflected.

1. Run `govuk-docker down` in the command line to stop all GOV.UK Docker containers.
1. Run `govuk-docker-up` in the folder of the app you want to run to restart the GOV.UK Docker containers.

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

## Supporting information

See the [GOV.UK Account technical documentation](https://docs.account.publishing.service.gov.uk/) for more information on using the GOV.UK Account product.

See the [GOV.UK Account team manual](https://team-manual.account.publishing.service.gov.uk/) for more information on internal GOV.UK Account team processes such as handling Zendesk tickets or deploying a branch to the staging environment.

You should check the GOV.UK Account technical documentation and team manual regularly as they are both currently under development and will change frequently.

See the [GOV.UK developer documentation](https://docs.publishing.service.gov.uk/) for more information on GOV.UK applications, infrastructure and tools.
