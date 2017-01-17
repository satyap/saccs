# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170117040213) do

  create_table "accounts", force: :cascade do |t|
    t.string  "name"
    t.boolean "archived", default: false
  end

  create_table "months", force: :cascade do |t|
    t.integer "account_id"
    t.string  "name"
    t.decimal "start_amount", precision: 10, scale: 2
    t.decimal "end_amount",   precision: 10, scale: 2
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "description"
    t.decimal  "amount",      precision: 10, scale: 2
    t.integer  "date_year"
    t.integer  "date_month"
    t.integer  "date_day"
    t.boolean  "cleared",                              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
