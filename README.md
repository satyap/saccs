Saccs
=====

# Simple ACCounting System

Simple system for keeping track of my bank and credit card accounts.

I make an account and enter transactions into it when I make them, for example deposit a check or use my card.

Each transaction could be positive (debit) or negative (credit). I can set the
transaction as "cleared" when I see it appear in my account, which can
sometimes take a day or two.

# How to run it

Saccs is a simple Ruby on Rails app that uses the standard tools such as
`bundle` and `rbenv`.

The data store is sqlite3 and is easily changed.

There is no authentication. This is meant to run locally.

1. Install `rbenv`
1. Clone this repo
1. Run `bundle`. You may need to install `libsqlite3-dev` first.
1. Run `bundle exec rails db:migrate`
1. Run `bundle exec rails s`
1. In your browser, hit `http://localhost:3000`

# Contributing/development

Fork the repo, submit pull requests.

